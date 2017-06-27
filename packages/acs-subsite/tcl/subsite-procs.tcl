# /packages/subsite/tcl/subsite-procs.tcl

ad_library {

    Procs to manage application groups

    @author oumi@arsdigita.com
    @creation-date 2001-02-01
    @cvs-id $Id$

}

namespace eval subsite {
    namespace eval util {}
    namespace eval default {}
}

ad_proc -public subsite::after_mount { 
    {-package_id:required}
    {-node_id:required}
} {
    This is the Tcl proc that is called automatically by the APM
    whenever a new instance of the subsites application is mounted.

    @author Don Baccus (dhogaza@pacifier.com)
    @creation-date 2003-03-05

} {
    subsite::default::create_app_group -package_id $package_id
}



ad_proc -public subsite::before_uninstantiate { 
    {-package_id:required}
} {

    Delete the application group associated with this subsite.

} {
    subsite::default::delete_app_group -package_id $package_id
}

ad_proc -public subsite::before_upgrade { 
    {-from_version_name:required}
    {-to_version_name:required}
} {
    Handles upgrade
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.0d3 5.0d4 {
                array set main_site [site_node::get -url /]
                set main_site_id $main_site(package_id)

                # Move parameter values from subsite to kernel

                parameter::set_value \
                    -package_id [ad_acs_kernel_id] \
                    -parameter ApprovalExpirationDays \
                    -value [parameter::get \
                                -package_id $main_site_id \
                                -parameter ApprovalExpirationDays \
                                -default 0]
                
                parameter::set_value \
                    -package_id [ad_acs_kernel_id] \
                    -parameter PasswordExpirationDays \
                    -value [parameter::get \
                                -package_id $main_site_id \
                                -parameter PasswordExpirationDays \
                                -default 0]
                
                
                apm_parameter_unregister \
                    -package_key acs-subsite \
                    -parameter ApprovalExpirationDays \
                    {}

                apm_parameter_unregister \
                    -package_key acs-subsite \
                    -parameter PasswordExpirationDays \
                    {}
            }
        }
}

ad_proc -public subsite::pivot_root {
    -node_id
} {

    Pivot the package associated with node_id onto the root.  Mounting
    the current root package under node_id.

} {
    array set node [site_node::get -node_id $node_id]
    array set root [site_node::get -url "/"]

    db_transaction {
        site_node::unmount -node_id $node(node_id)
        site_node::unmount -node_id $root(node_id)

        site_node::mount -node_id $root(node_id) -object_id $node(package_id)
        site_node::mount -node_id $node(node_id) -object_id $root(package_id)

        #TODO: swap the application groups for the subsites so that
        #TODO: registered users is always the application group of the root
        #TODO: subsite.
    }
}

ad_proc -public subsite::default::create_app_group {
    -package_id
    {-name {}}
} {

    Create the default application group for a subsite.

    <ul>
      <li> Create application group
      <li> Create segment "Subsite Users"
      <li> Create relational constraint to make subsite registration 
           require supersite registration.
    </ul>

} {
    if { [application_group::group_id_from_package_id -no_complain -package_id $package_id] eq "" } {
        array set node [site_node::get_from_object_id -object_id $package_id]
        set node_id $node(node_id)

        if { $name eq "" } {
            set subsite_name [db_string subsite_name_query {}]
        } else {
            set subsite_name $name
        }

        set truncated_subsite_name [string range $subsite_name 0 89]

        db_transaction {

            # Create subsite application group
            set group_name "$truncated_subsite_name"
            set subsite_group_id [application_group::new \
                                      -package_id $package_id \
                                      -group_name $group_name]

            # Create segment of registered users
            set segment_name "$truncated_subsite_name Members"
            set segment_id [rel_segments_new $subsite_group_id membership_rel $segment_name]

            # Create a constraint that says "to be a member of this subsite you must be a member
            # of the parent subsite.
            set subsite_id [site_node::closest_ancestor_package \
                                -node_id $node_id \
                                -package_key [subsite::package_keys]]

            db_1row parent_subsite_query {}
            set constraint_name "Members of [string range $subsite_name 0 30] must be members of [string range $supersite_name 0 30]"
            set user_id [ad_conn user_id]
            set creation_ip [ad_conn peeraddr]
            db_exec_plsql add_constraint {}

            # Create segment of registered users for administrators
            set segment_name "$truncated_subsite_name Administrators"
            set admin_segment_id [rel_segments_new $subsite_group_id admin_rel $segment_name]

            # Grant admin privileges to the admin segment
            permission::grant \
                -party_id $admin_segment_id \
                -object_id $package_id \
                -privilege admin

            # Grant read/write/create privileges to the member segment
            foreach privilege { read create write } {
                permission::grant \
                    -party_id $segment_id \
                    -object_id $package_id \
                    -privilege $privilege
            }
            
        }
    }

}

ad_proc -public subsite::default::delete_app_group {
    -package_id
} {

    Delete the default application group for a subsite.

} {
    application_group::delete -group_id [application_group::group_id_from_package_id -package_id $package_id]
}

ad_proc -private subsite::instance_name_exists_p {
    node_id
    instance_name 
} { 
    Returns 1 if the instance_name exists at this node. 0
    otherwise. Note that the search is case-sensitive.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-03-01

} {
    return [db_string select_name_exists_p {
        select count(*)  from site_nodes
        where parent_id = :node_id and name = :instance_name
    }]
}

ad_proc -public subsite::auto_mount_application { 
    { -instance_name "" }
    { -pretty_name "" }
    { -node_id "" }
    package_key
} {
    Mounts a new instance of the application specified by package_key
    beneath node_id.  This proc makes sure that the instance_name (the
    name of the new node) is unique before invoking site_node::instantiate_and_mount.


    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-28

    @param instance_name The name to use for the url in the
    site-map. Defaults to the package_key plus a possible digit to
    serve as a unique identifier (e.g. news-2)

    @param pretty_name The english name to use for the site-map and
    for things like context bars. Defaults to the name of the object
    mounted at this node + the package pretty name (e.g. Intranet News)

    @param node_id Defaults to [ad_conn node_id]

    @see site_node::instantiate_and_mount

    @return The package id of the newly mounted package 

} {
    if { $node_id eq "" } {
        set node_id [ad_conn node_id]
    }

    set ctr 2
    if { $instance_name eq "" } {
        # Default the instance name to the package key. Add a number,
        # if necessary, until we find a unique name
        set instance_name $package_key
        while { [subsite::instance_name_exists_p $node_id $instance_name] } {
            set instance_name "$package_key-$ctr"
            incr ctr
        }
    }

    if { $pretty_name eq "" } {
        # Get the name of the object mounted at this node
        db_1row select_package_object_names {}
        set pretty_name "$object_name $package_name"
        if { $ctr > 2 } {
            # This was a duplicate pkg name... append the ctr used in the instance name
            append pretty_name " [expr {$ctr - 1}]"
        }
    }

    return [site_node::instantiate_and_mount -parent_node_id $node_id \
                                             -node_name $instance_name \
                                             -package_name $pretty_name \
                                             -package_key $package_key]
}


ad_proc -public subsite::package_keys {
} {
    Get the list of packages which can be subsites.  This is built during the
    bootstrap process.  If you install a new subsite-implementing package and don't
    accept the installers invitation to reboot openacs, tough luck.

    @return the packages keys of all installed packages acting as subsites.
} {
    return [nsv_get apm_subsite_packages_list package_keys]
}

ad_proc -public subsite::get {
    {-subsite_id {}}
    {-array:required}
} {
    Get information about a subsite.

    @param subsite_id The id of the subsite for which info is requested.
    If no id is provided, then the id of the closest ancestor subsite will
    be used.
    @param array The name of an array in which information will be returned.

    @author Frank Nikolajsen (frank@warpspace.com)
    @creation-date 2003-03-08
} {
    upvar $array subsite_info

    if { $subsite_id eq "" } {
        set subsite_id [ad_conn subsite_id]
    }

    if { ![ad_conn isconnected] } {
        set package_id ""
    } else {
        set package_id [ad_conn package_id]
    }

    array unset subsite_info
    array set subsite_info [site_node::get_from_object_id -object_id $subsite_id]
}

ad_proc -public subsite::get_element {
    {-subsite_id {}}
    {-element:required}
    {-notrailing:boolean}
} {
    Return a single element from the information about a subsite.

    @param subsite_id The node id of the subsite for which info is
       requested.  If no id is provided, then the id of the closest
       ancestor subsite will be used.

    @param element The element you want, one of: directory_p
       object_type package_key package_id name pattern_p instance_name
       node_id parent_id url object_id

    @paramm notrailing If true and the element requested is an url,
       then strip any trailing slash ('/'). This means the empty string
       is returned for the root.

    @return The element you asked for

    @author Frank Nikolajsen (frank@warpspace.com)
    @creation-date 2003-03-08
} {
    if { $subsite_id eq "" } {
        set subsite_id [ad_conn subsite_id]
    }

    subsite::get -subsite_id $subsite_id -array subsite_info
    set result $subsite_info($element)

    if { $notrailing_p && [string match $element "url"]} {
        set result [string trimright $result "/"]
    }

    return $result
}

ad_proc -public subsite::upload_allowed {} {
    Verifies SolicitPortraitP parameter to ensure upload portrait
    security.

    @author Hector Amado (hr_amado@galileo.edu)
    @creation-date 2004-06-16
} {
   
    set package_id [ad_conn subsite_id]

    if { ![parameter::get -package_id $package_id -parameter SolicitPortraitP -default 1]  } {
        if { ![acs_user::site_wide_admin_p] } {
             ns_log notice "user is tried to see user/portrait/upload  without permission"
        ad_return_forbidden \
               "Permission Denied" \
               "<blockquote>
                You don't have permission to see this page.
               </blockquote>"
        }
    }
}

ad_proc -public subsite::util::sub_type_exists_p {
    object_type
} {
    @param object_type

    @return 1 if object_type has sub types, or 0 otherwise

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 2000-02-07
} {

    return [db_string sub_type_exists_p {}]

}


ad_proc -public subsite::util::object_type_path_list {
    object_type
    {ancestor_type acs_object}
} {
    @return the object type hierarchy for the given object type from ancestor_type to object_type
} {
    set path_list [list]

    set type_list [db_list select_object_type_path {}]

    foreach type $type_list {
        lappend path_list $type
        if {$type eq $ancestor_type} {
            break
        }
    }

    return $path_list

}

ad_proc -public subsite::util::object_type_pretty_name {
    object_type
} {
    returns pretty name of object.  We need this so often that I thought
    I'd stick it in a proc so it can possibly be cached later.

    @author Oumi Mehrotra (oumi@arsdigita.com)
    @creation-date 2000-02-07

    @param object_type
} {
    return [db_string select_pretty_name {
        select pretty_name from acs_object_types 
          where object_type = :object_type
    }]
}

ad_proc -public subsite::util::return_url_stack {
    return_url_list
} {
    Given a list of return_urls, we recursively encode them into one
    return_url that can be redirected to or passed into a page.  As long 
    as each page in the list does the typical redirect to return_url, then
    the page flow will go through each of the pages in $return_url_list
} {

    if {[llength $return_url_list] == 0} {
        error "subsite::util::return_url_stack - \$return_url_list is empty"
    }

    set first_url [lindex $return_url_list 0]
    set rest [lrange $return_url_list 1 end]

    # Base Case
    if {[llength $rest] == 0} {
        return $first_url
    }

    # More than 1 url was in the list, so recurse
    if {[string first ? $first_url] == -1} {
        append first_url ?
    }
    append first_url "&return_url=[ad_urlencode [return_url_stack $rest]]"

    return $first_url
}


ad_proc -public subsite::define_pageflow {
    {-sections_multirow "sections"}
    {-subsections_multirow "subsections"}
    {-section ""}
    {-url ""}
} {
    Defines the page flow of the subsite

    TODO: add an image
    TODO: add link_p/selected_p for subsections
} {
    set pageflow [get_pageflow_struct -url $url]
    if {$url eq ""} {
        set base_url [subsite::get_element -element url]
    } else {
        set base_url $url
    }

    template::multirow create $sections_multirow name label title url selected_p link_p

    template::multirow create $subsections_multirow name label title url selected_p link_p

    foreach { section_name section_spec } $pageflow {
        array set section_a {
            label {}
            url {}
            title {}
            subsections {}
            folder {}
            selected_patterns {}
        }

        array set section_a $section_spec
        set section_a(name) $section_name

        set selected_p [add_section_row \
                            -array section_a \
                            -base_url $base_url \
                            -multirow $sections_multirow]

        if { $selected_p } {
            foreach { subsection_name subsection_spec } $section_a(subsections) {
                array set subsection_a {
                    label {}
                    title {}
                    folder {}
                    url {}
                    selected_patterns {}
                }
                array set subsection_a $subsection_spec
                set subsection_a(name) $subsection_name
                set subsection_a(folder) [file join $section_a(folder) $subsection_a(folder)]

                add_section_row \
                    -array subsection_a \
                    -base_url $base_url \
                    -multirow $subsections_multirow
            }
        }
    }
}


ad_proc -public subsite::add_section_row {
    {-array:required}
    {-base_url:required}
    {-multirow:required}
    {-section {}}
} {
    Helper proc for adding rows of sections to the page flow of the subsite.

    @see subsite::define_pageflow
} {
    upvar $array info

    # the folder index page is called .
    if { $info(url) eq ""
         || $info(url) eq "index"
         || [string match "*/" $info(url)]
         || [string match "*/index" $info(url)]
     } {
        set info(url) "[string range $info(url) 0 [string last / $info(url)]]."
    }
    
    if { [ad_conn node_id] == 
         [site_node::closest_ancestor_package -include_self \
            -package_key [subsite::package_keys] \
            -url [ad_conn url]] } {
        set current_url [ad_conn extra_url]
    } else {
        # Need to prepend the path from the subsite to this package
        set current_url [string range [ad_conn url] [string length $base_url] end]
    }
    if { $current_url eq ""
         || $current_url eq "index"
         || [string match "*/" $current_url]
         || [string match "*/index" $current_url]
     } {
        set current_url "[string range $current_url 0 [string last / $current_url]]."
    }
    
    set info(url) [file join $info(folder) $info(url)]
    regsub {/\.$} $info(url) / info(url)

    # Default to not selected
    set selected_p 0
    
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
    
    set link_p [expr {$current_url ne $info(url) }] 
    
    template::multirow append $multirow \
        $info(name) \
        $info(label) \
        $info(title) \
        [file join $base_url $info(url)] \
        $selected_p \
        $link_p

    return $selected_p
}

ad_proc -public subsite::get_section_info {
    {-array "section_info"}
    {-sections_multirow "sections"}
} {
    Takes the sections_multirow and sets the passed array name
    with the elements label and url of the selected section.
} {
    upvar $array row
    # Find the label of the selected section

    array set row {
        label {}
        url {}
    }

    template::multirow foreach $sections_multirow {
        if { [template::util::is_true $selected_p] } {
            set row(label) $label
            set row(url) $url
            break
        }
    }
}

ad_proc -public subsite::get_pageflow_struct {
    {-url ""}
} {
    Defines the page flow structure.
} {
    # This is where the page flow structure is defined
    set subsections [list]
    lappend subsections home {
        label "Home"
        url ""
    }


    set pageflow [list]

    if {$url eq ""} {
        set subsite_url [subsite::get_element -element url]
    } else {
        set subsite_url $url
    }

    set subsite_id [ad_conn subsite_id]
    array set subsite_sitenode [site_node::get -url $subsite_url]
    set subsite_node_id $subsite_sitenode(node_id)

    set index_redirect_url [parameter::get -parameter "IndexRedirectUrl" -package_id $subsite_id]

    set child_urls [lsort -ascii [site_node::get_children -node_id $subsite_node_id -package_type apm_application]]

    if { $index_redirect_url eq "" } {
        lappend pageflow home {
            label "Home"
            folder ""
            url ""
            selected_patterns {
                ""
                "subsites"
            }
        }
    } else {
        # See if the redirect-url to a package inside this subsite
        for { set i 0 } { $i < [llength $child_urls] } { incr i } {
            array set child_node [site_node::get_from_url -exact -url [lindex $child_urls $i]]
            if { $index_redirect_url eq $child_node(url) ||
                 [string equal ${index_redirect_url}/ $child_node(url)]} {
                lappend pageflow $child_node(name) [list \
                                                        label "Home" \
                                                        folder $child_node(name) \
                                                        url {} \
                                                        selected_patterns *]
                set child_urls [lreplace $child_urls $i $i]
                break
            }
        }
    }


    set user_id [ad_conn user_id]
    set admin_p [permission::permission_p \
                     -object_id [site_node::closest_ancestor_package -include_self \
                                     -package_key [subsite::package_keys] \
                                     -url [ad_conn url]] \
                     -privilege admin \
                     -party_id [ad_conn untrusted_user_id]]
    set show_member_list_to [parameter::get -parameter "ShowMembersListTo" -package_id $subsite_id -default 2]

    if { $admin_p
         || ($user_id != 0 && $show_member_list_to == 1)
         || $show_member_list_to == 0
     } {
        lappend pageflow members {
            label "Members"
            folder "members"
            selected_patterns {*}
        }
    }


    foreach child_url $child_urls {
        array set child_node [site_node::get_from_url -exact -url $child_url]
        lappend pageflow $child_node(name) [list \
                                                label $child_node(instance_name) \
                                                folder $child_node(name) \
                                                url {} \
                                                selected_patterns *]
    }

    if { $admin_p } {
        lappend pageflow admin {
            label "Administration"
            url "admin/configure"
            selected_patterns {
                admin/*
                shared/parameters
            }
            subsections {
                configuration {
                    label "Configuration"
                    url "admin/configure"
                }
                applications {
                    label "Applications"
                    folder "admin/applications"
                    url ""
                    selected_patterns {
                        *
                    }
                }
                subsite_add {
                    label "New Subsite"
                    url "admin/subsite-add"
                }
                permissions {
                    label "Permissions"
                    url "admin/permissions"
                    selected_patterns {
                        permissions*
                    }
                }
                parameters {
                    label "Parameters"
                    url "shared/parameters"
                }
                advanced {
                    label "Advanced"
                    url "admin/."
                    selected_patterns {
                        site-map/*
                        groups/*
                        group-types/*
                        rel-segments/*
                        rel-types/*
                        host-node-map/*
                        object-types/*
                    }
                }
            }
        }
    }

    return $pageflow
}

ad_proc -public subsite::main_site_id {} {
    Get the package_id of the Main Site. The Main Site is the subsite
    that is always mounted at '/' and that has a number
    of site-wide parameter settings.

    @author Peter Marklund
} {
    array set main_node [site_node::get_from_url -url "/"]
    
    return $main_node(object_id)
}

ad_proc -public subsite::get_theme_options {} {
    Gets options for subsite themes for use with a form builder select widget.
} {
    db_foreach get_subsite_themes {} {
        lappend master_theme_options [list [lang::util::localize $name] $key]
    }

    return $master_theme_options
}


ad_proc -public subsite::set_theme {
    -subsite_id
    {-theme:required}
} {
    Set the theme for the given or current subsite.  This will change
    the subsite's ThemeKey, DefaultMaster, and ThemeCSS,
    DefaultFormStyle, DefaultListStyle, DefaultListFilterStyle,
    DefaultDimensionalStyle, and ResourceDir parameters.

    @param subsite_id Id of the subsite
    @param theme Name of the theme (theme key)
} {
    if { ![info exists subsite_id] } {
        set subsite_id [ad_conn subsite_id]
    }

    set old_theme [subsite::get_theme -subsite_id $subsite_id]

    db_1row get_theme_paths {}

    parameter::set_value -parameter ThemeKey -package_id $subsite_id \
        -value $theme
    parameter::set_value -parameter DefaultMaster -package_id $subsite_id \
        -value $template
    parameter::set_value -parameter ThemeCSS -package_id $subsite_id \
        -value $css
    parameter::set_value -parameter ThemeJS -package_id $subsite_id \
        -value $js
    parameter::set_value -parameter DefaultFormStyle -package_id $subsite_id \
        -value $form_template
    parameter::set_value -parameter DefaultListStyle -package_id $subsite_id \
        -value $list_template
    parameter::set_value -parameter DefaultListFilterStyle -package_id $subsite_id \
        -value $list_filter_template
    parameter::set_value -parameter DefaultDimensionalStyle -package_id $subsite_id \
        -value $dimensional_template
    parameter::set_value -parameter ResourceDir -package_id $subsite_id \
        -value $resource_dir
    parameter::set_value -parameter StreamingHead -package_id $subsite_id \
        -value $streaming_head

    
    callback subsite::theme_changed \
        -subsite_id $subsite_id \
        -old_theme $old_theme \
        -new_theme $theme
}

ad_proc -public -callback subsite::theme_changed {
    -subsite_id:required
    -old_theme:required
    -new_theme:required
} {

    Callback for executing code after the subsite theme has been send changed
    
    @param subsite_id subsite, of which the theme was changed
    @param old_theme the old theme
    @param new_theme the new theme
} -


ad_proc -public subsite::save_theme_parameters {
    -subsite_id
    -theme
    -local_p 
} {
    Save the actual theming parameter set of the given/current subsite
    as default for the given/current theme. These default values are
    used, whenever a subsite switches to the specified theme.

    @param subsite_id Id of the subsite
    @param theme Name of the theme (theme key)

    @author Gustaf Neumann
} {

    if { ![info exists subsite_id] } {
        set subsite_id [ad_conn subsite_id]
    }

    if {![info exists theme]} {
        set theme [subsite::get_theme -subsite_id $subsite_id]
    }

    set name [db_string get_theme_name {select name from subsite_themes where key = :theme} -default ""]
    if {$name eq ""} {
        error "no subsite theme with key $theme registered"
    }

    subsite::update_subsite_theme \
        -key $theme \
        -name                 $name \
        -template             [parameter::get -parameter DefaultMaster           -package_id $subsite_id] \
        -css                  [parameter::get -parameter ThemeCSS                -package_id $subsite_id] \
        -js                   [parameter::get -parameter ThemeJS                 -package_id $subsite_id] \
        -form_template        [parameter::get -parameter DefaultFormStyle        -package_id $subsite_id] \
        -list_template        [parameter::get -parameter DefaultListStyle        -package_id $subsite_id] \
        -list_filter_template [parameter::get -parameter DefaultListFilterStyle  -package_id $subsite_id] \
        -dimensional_template [parameter::get -parameter DefaultDimensionalStyle -package_id $subsite_id] \
        -resource_dir         [parameter::get -parameter ResourceDir             -package_id $subsite_id] \
        -streaming_head       [parameter::get -parameter StreamingHead           -package_id $subsite_id] \
        -local_p              $local_p
        
}

ad_proc -public subsite::save_theme_parameters_as {
    -subsite_id
    -theme:required
    -pretty_name:required
} {
    Save the actual theming parameter for the given/current subsite
    under a new name.

    @param subsite_id Id of the subsite
    @param theme Name of the theme (theme key)
    @param pretty_theme Pretty Name (of the theme)

    @author Gustaf Neumann
} {

    if { ![info exists subsite_id] } {
        set subsite_id [ad_conn subsite_id]
    }

    set exists_p [db_string get_theme_name {select 1 from subsite_themes where key = :theme} -default 0]
    if {$exists_p} {
        error "subsite theme with key $theme exists already"
    }

    subsite::new_subsite_theme \
        -key                  $theme \
        -name                 $pretty_name \
        -template             [parameter::get -parameter DefaultMaster           -package_id $subsite_id] \
        -css                  [parameter::get -parameter ThemeCSS                -package_id $subsite_id] \
        -js                   [parameter::get -parameter ThemeJS                 -package_id $subsite_id] \
        -form_template        [parameter::get -parameter DefaultFormStyle        -package_id $subsite_id] \
        -list_template        [parameter::get -parameter DefaultListStyle        -package_id $subsite_id] \
        -list_filter_template [parameter::get -parameter DefaultListFilterStyle  -package_id $subsite_id] \
        -dimensional_template [parameter::get -parameter DefaultDimensionalStyle -package_id $subsite_id] \
        -resource_dir         [parameter::get -parameter ResourceDir             -package_id $subsite_id] \
        -streaming_head       [parameter::get -parameter StreamingHead           -package_id $subsite_id] \
        -local_p              true
        
}



ad_proc -public subsite::get_theme {
    -subsite_id
} {
    Get the theme for the given (or current) subsite.

    @param subsite_id id of the subsite
    @return Name of the theme (theme key)
} {
    if { ![info exists subsite_id] } {
        set subsite_id [ad_conn subsite_id]
    }
    parameter::get -parameter ThemeKey -package_id $subsite_id 
}

ad_proc -public subsite::new_subsite_theme {
    -key:required
    -name:required
    -template:required
    {-css ""}
    {-js ""}
    {-form_template ""}
    {-list_template ""}
    {-list_filter_template ""}
    {-dimensional_template ""}
    {-resource_dir ""}
    {-streaming_head ""}
    {-local_p true}
} {
    Add a new subsite theme, making it available to the theme configuration code.
} {
    # the following line is for Oracle compatibility
    set local_p [expr {$local_p ? "t" : "f"}]
    
    db_dml insert_subsite_theme {}
}

ad_proc -public subsite::update_subsite_theme {
    -key:required
    -name:required
    -template:required
    {-css ""}
    {-js ""}
    {-form_template ""}
    {-list_template ""}
    {-list_filter_template ""}
    {-dimensional_template ""}
    {-resource_dir ""}
    {-streaming_head ""}
    {-local_p false}
} {
    Update the default theming parameters in the database

    @author Gustaf Neumann
} {
    # the following line is for Oracle compatibility
    set local_p [expr {$local_p ? "t" : "f"}]
    
    db_dml update {
      update subsite_themes
        set name = :name,
            template = :template,
            css = :css,
            js = :js,
            form_template = :form_template,
            list_template = :list_template,
            list_filter_template = :list_filter_template,
            dimensional_template = :dimensional_template,
            resource_dir = :resource_dir,
            streaming_head = :streaming_head,
            local_p = :local_p
     where
        key = :key
    }
}



ad_proc -public subsite::delete_subsite_theme {
    -key:required
} {
    Delete a subsite theme, making it unavailable to the theme configuration code.    
} {
    db_dml delete_subsite_theme {}
}

ad_proc -public subsite::get_application_options {} {
    Gets options list for applications to install
} {
    set subsite_package_keys [join '[subsite::package_keys]' ","]
    return [db_list_of_lists package_types {}]
}

ad_proc -private subsite::assert_user_may_add_member {} {
    Used on pages that add users to the application group of
    the current subsite to assert that the currently logged in
    user may add users.

    @author Peter Marklund
} {
    auth::require_login

    set group_id [application_group::group_id_from_package_id]

    set admin_p [permission::permission_p -object_id $group_id -privilege "admin"]

    if { !$admin_p } {
        # If not admin, user must be member of group, and members must be allowed to invite other members
        if { ![parameter::get -parameter "MembersCanInviteMembersP" -default 0]
             || ![group::member_p -group_id $group_id]
         } {
            ad_return_forbidden "Cannot invite members" "I'm sorry, but you're not allowed to invite members to this group"
            ad_script_abort
        }
    }
}

ad_proc -public subsite::get_url {
    {-node_id ""}
    {-absolute_p 0}
    {-force_host ""}
    {-strict_p 0}
    {-protocol ""}
    {-port ""}
} {
    Returns the url stub for the specified subsite.

    If -absolute is supplied then this function will generate absolute urls.  

    If the site is currently being accessed via a host node mapping or 
    -force_host_node_map is also supplied then URLs will ommit the 
    corresponding subsite url stub.  The host name will be used
    for any appropriate subsite when absolute urls are generated.  

    @param node_id the subsite's node_id (defaults to nearest subsite node).
    @param absolute_p whether to include the host in the returned url.
    @param force_host_node_map_p whether to produce host node mapped urls 
        regardless of the current connection state
} {
    if {[ad_conn isconnected]} {
        if {$node_id eq ""} {
            set node_id [ad_conn subsite_node_id]
        }

        array set subsite_node [site_node::get -node_id $node_id]
        util_driver_info -array driver_info
        set main_host $driver_info(hostname)

        lassign [split [ns_set iget [ns_conn headers] host] :] driver_info(vhost) host_provided_port
        if {$host_provided_port ne "" } {
            set driver_info(port) $host_provided_port
        }

        set request_vhost_p [expr {$main_host ne $driver_info(vhost) }]
        
    } elseif {$node_id eq ""} {
        error "You must supply node_id when not connected."
    } else {
        array set subsite_node [site_node::get -node_id $node_id]
        set request_vhost_p 0
        #
        # Provide fallback values from the first configured driver
        #
        set d [lindex [security::configured_driver_info] 0]
        set driver_info(proto) [dict get $d proto]
        set driver_info(port) [dict get $d port]
        set driver_info(hostname) [dict get $d host]
    }

    #
    # If the provided protocol is empty, get it from the driver_info.
    #
    if {$protocol eq ""} {
        set protocol $driver_info(proto)
    }
    
    #
    # If the provided port is empty, get it from the driver_info.
    #
    if {$port eq ""} {
        set port $driver_info(port)
    }
    
    #
    # If the provided host is not empty, get it from the host header
    # field (when connected) or from the configured host name.
    #
    if {$force_host eq "any"} {
        if {[info exists driver_info(vhost)]} {
            set host $driver_info(vhost)
        } else {
            error "The option '-force_host any' is only valid when connected"
        }
    } elseif {$force_host ne ""} {
        set host $force_host
    } else {
        set host $driver_info(hostname)
    }

    
    set result ""
    if { $request_vhost_p } {
        set root_p [string equal $subsite_node(parent_id) ""]
        set search_vhost $host

        set where_clause [db_map orderby]
        
        # TODO: This should be cached
        set site_node $subsite_node(node_id)
        set mapped_vhost [db_string get_vhost {} -default ""]

        if {$root_p && $mapped_vhost eq ""} {
            if {$strict_p} {
                error "$search_vhost is not mapped to this subsite or any of its parents."
            }
            set mapped_vhost $search_vhost
        }

        if {$mapped_vhost eq ""} {
            set result [subsite::get_url \
                            -node_id $subsite_node(parent_id) \
                            -absolute_p $absolute_p \
                            -strict_p $strict_p \
                            -force_host $host]
            append result "$subsite_node(name)/"
        } else {
            set host $mapped_vhost
        }

    }
    if {$result eq ""} {
        if {$absolute_p} {
            set result [util::join_location \
                            -proto $protocol \
                            -hostname $host \
                            -port $port]
        }
        append result $subsite_node(url)
    }

    return $result
}

ad_proc -private subsite::util::packages_no_mem {
    -node_id
} {
    return a list of package_id's for children of the passed node_id

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-05-07
    @see subsite::util::packages
} {
    # need to strip nodes which have no mounted package...
    set packages [list]
    foreach package [site_node::get_children -all -node_id $node_id -element package_id] {
        if {$package ne ""} {
            lappend packages $package
        }
    }

    return $packages
}

ad_proc -public subsite::util::packages {
    -node_id
} {
    Return a list of package_id's for the subsite containing node_id

    This is a memoized function which caches for 20 minutes.

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-05-07
    @see subsite::util::packages_no_mem
} {
    set subsite_node_id [site_node::closest_ancestor_package \
                             -package_key [subsite::package_keys] \
                             -node_id $node_id \
                             -include_self \
                             -element node_id]

    return [util_memoize [list subsite::util::packages_no_mem -node_id $subsite_node_id] 1200]
}

ad_proc -public subsite::util::get_package_options {
} {
    Get a list of pretty name, package key pairs for all packages which identify
    themselves as implementing subsite semantics.

    @return a list of pretty name, package key pairs suitable for use in a template
            select widget.
} {
    return [db_list_of_lists get {}]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
