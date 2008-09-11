# /packages/subsite/tcl/subsite-procs.tcl

ad_library {

    Procs to manage the default template's navigation multirow.

    @author Don Baccus (dhogaza@pacifier.com)
    @creation-date 2008-04-26
    @cvs-id $Id$

}

namespace eval subsite_navigation {
}

ad_proc -public subsite_navigation::define_pageflow {
    {-subsite_id ""}
    {-show_applications_p 1}
    {-no_tab_application_list ""}
    {-initial_pageflow ""}
    {-navigation_multirow navigation}
    {-group main}
    {-subgroup sub}
} {
    Defines the page flow of the subsite.

    This sets up a navigation multirow as defined by the default master installed
    by openacs, which renders it as one or more rows of tabs.  The standard CSS
    defines classes for two rows of tabs, if you want more, you must define your own
    CSS classes.

    If the navigation multirow doesn't exist, we create it.

    @param subsite_id The package id of the subsite we're interested in (defaults to current)
    @param show_applications_p If true, autogenerate tabs for applications (not declared
           boolean because the tabbed master takes this from a package parameter)
    @param no_tab_application_list A list of application package keys to ignore when
           autogenerating tabs for applications
    @param initial_pageflow Add these subsections before computing the rest of the page flow
    @param navigation_multirow The name of the multirow used to build the nav bars
    @param group Group name for the primary section
    @param subgroup Group name for the subsection (opened under a selected tab)

} {
    if { $subsite_id eq "" } {
        set subsite_id [ad_conn subsite_id]
    }

    set pageflow [subsite_navigation::get_pageflow_struct \
                     -subsite_id $subsite_id \
                     -initial_pageflow $initial_pageflow \
                     -show_applications_p $show_applications_p \
                     -no_tab_application_list $no_tab_application_list]
    set base_url [subsite::get_element -subsite_id $subsite_id -element url]

    if { ![template::multirow exists $navigation_multirow] } {
        template::multirow create $navigation_multirow group label href target \
            title lang accesskey class id tabindex 
    }

    foreach { section_name section_spec } $pageflow {
        array set section_a {
            label {}
            url {}
            title {}
            subsections {}
            folder {}
            selected_patterns {}
            accesskey {}
        }

        array set section_a $section_spec
        set section_a(name) $section_name

        set selected_p [add_section_row \
                            -subsite_id $subsite_id \
                            -array section_a \
                            -base_url $base_url \
                            -group $group \
                            -multirow $navigation_multirow]

        if { $selected_p } {
            foreach { subsection_name subsection_spec } $section_a(subsections) {
                array set subsection_a {
                    label {}
                    title {}
                    folder {}
                    url {}
                    selected_patterns {}
                    accesskey {}
                }
                array set subsection_a $subsection_spec
                set subsection_a(name) $subsection_name
                set subsection_a(folder) [file join $section_a(folder) $subsection_a(folder)]

                add_section_row \
                    -subsite_id $subsite_id \
                    -array subsection_a \
                    -base_url $base_url \
                    -group $subgroup \
                    -multirow $navigation_multirow
            }
        }
    }
}


ad_proc -public subsite_navigation::add_section_row {
    {-subsite_id ""}
    {-array:required}
    {-base_url:required}
    {-multirow:required}
    {-group:required}
    {-section {}}
} {
    Helper proc for adding rows of sections to the page flow of the subsite.

    @see subsite_navigation::define_pageflow
} {
    upvar $array info
    # the folder index page is called .
    if { $info(url) eq "" || $info(url) eq "index" || \
             [string match "*/" $info(url)] || [string match "*/index" $info(url)] } {
        set info(url) "[string range $info(url) 0 [string last / $info(url)]]."
    }
    
    if { [ad_conn node_id] == 
         [site_node::closest_ancestor_package -include_self \
            -node_id [site_node::get_node_id_from_object_id -object_id $subsite_id] \
            -package_key [subsite::package_keys] \
            -url [ad_conn url]] } {
        set current_url [ad_conn extra_url]
    } else {
        # Need to prepend the path from the subsite to this package
        set current_url [string range [ad_conn url] [string length $base_url] end]
    }
    
    set info(url) [file join $info(folder) $info(url)]
    regsub {\.$} $info(url) "" info(url)

    # Default to not selected
    set selected_p 0

    set info(tabindex) [template::multirow size $multirow]
    if { $info(accesskey) eq "" } {
        set info(accesskey) $info(tabindex)
    }
    
    if { $current_url eq $info(url) || $info(name) eq $section } {
        set selected_p 1
    } else {
        foreach pattern $info(selected_patterns) {
            set full_pattern [file join $info(folder) $pattern]
            if { [string match $full_pattern $current_url] } {
                set selected_p 1
                break
            }
        }
    }

    # DRB: Expr thinks "-" is a subtraction operator thus this caveman if...
    if { $selected_p } { 
        set navigation_id ${group}-navigation-active
    } else {
        set navigation_id ""
    }

    template::multirow append $multirow $group $info(label) [file join $base_url $info(url)] \
        "" $info(title) "" $info(accesskey) "" $navigation_id [template::multirow size $multirow]

    return $selected_p
}

ad_proc -public subsite_navigation::get_section_info {
    {-array "section_info"}
    {-navigation_multirow "navigation"}
} {
    Takes the navigation_multirow and sets the passed array name
    with the elements label and url of the selected section.
} {
    upvar $array row
    # Find the label of the selected section

    array set row {
        label {}
        url {}
    }

    template::multirow foreach $navigation_multirow {
        if { [template::util::is_true $selected_p] } {
            set row(label) $label
            set row(url) $url
            break
        }
    }
}

ad_proc -public subsite_navigation::get_pageflow_struct {
    {-subsite_id ""}
    {-initial_pageflow ""}
    {-show_applications_p 1}
    {-no_tab_application_list ""}
} {
    Defines the page flow structure.

    @param subsite_id The package id of the subsite we're interested in (defaults to current)
    @param initial_pageflow Add these subsections before computing the rest of the page flow
    @param show_applications_p If true, autogenerate tabs for applications (not declared
           boolean because the tabbed master takes this from a package parameter)
    @param no_tab_application_list A list of application package keys to ignore when
           autogenerating tabs for applications
} {
    set pageflow $initial_pageflow
    set subsite_node_id [site_node::get_node_id_from_object_id -object_id $subsite_id]
    set subsite_url [site_node::get_element -node_id $subsite_node_id -element url]

    set user_id [ad_conn user_id]
    set admin_p [permission::permission_p \
                     -object_id [site_node::closest_ancestor_package -include_self \
                                     -node_id $subsite_node_id \
                                     -package_key [subsite::package_keys] \
                                     -url [ad_conn url]] \
                     -privilege admin \
                     -party_id [ad_conn untrusted_user_id]]
    set show_member_list_to [parameter::get -parameter "ShowMembersListTo" -package_id $subsite_id -default 2]

    if { $admin_p || ($user_id != 0 && $show_member_list_to == 1) || \
	$show_member_list_to == 0 } {
        set pageflow [concat $pageflow [parameter::get -package_id [ad_conn subsite_id] \
                                           -parameter MembersViewNavbarTabsList -default ""]]
    }

    set index_redirect_url [parameter::get -parameter "IndexRedirectUrl" -package_id $subsite_id]
    set index_internal_redirect_url [parameter::get -parameter "IndexInternalRedirectUrl" -package_id $subsite_id]
    regsub {(.*)/packages} $index_internal_redirect_url "" index_internal_redirect_url
    regexp {(/[-[:alnum:]]+/)(.*)$} $index_internal_redirect_url dummy index_internal_redirect_url
    set child_urls [lsort -ascii [site_node::get_children -node_id $subsite_node_id -package_type apm_application]]

    if { $show_applications_p } {
        foreach child_url $child_urls {
            array set child_node [site_node::get_from_url -exact -url $child_url]
            if { $child_url ne $index_redirect_url  &&
                 $child_url ne $index_internal_redirect_url &&
                 [lsearch -exact $no_tab_application_list $child_node(package_key)] == -1 } {
                lappend pageflow $child_node(name) [list \
                                                        label $child_node(instance_name) \
                                                        folder $child_node(name) \
                                                        url {} \
                                                        selected_patterns *]
            }
        }
    }

    if { $admin_p } {
        set pageflow [concat $pageflow [parameter::get -package_id [ad_conn subsite_id] \
                                           -parameter AdminNavbarTabsList -default ""]]
    }

    return $pageflow
}
