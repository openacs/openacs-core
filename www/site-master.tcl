# Expects properties:
#   title
#   focus
#   header_stuff
#   section

if { ![info exists section] } {
    set section {}
}

if { ![info exists header_stuff] } {
    set header_stuff {}
}

# This will set 'sections' and 'subsections' multirows
subsite::define_pageflow -section $section
subsite::get_section_info -array section_info

# Find the subsite we belong to
set subsite_url [site_node_closest_ancestor_package_url]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)
set subsite_name $subsite_sitenode(instance_name)

# Where to find the stylesheet
set css_url "/resources/acs-subsite/site-master.css"

# Get system name
set system_name [ad_system_name]
set system_url [ad_url]

# Get user information
set user_id [ad_conn untrusted_user_id]
if { [ad_conn untrusted_user_id] != 0 } {
    set user_name [person::name -person_id $user_id]
    set pvt_home_url [ad_pvt_home]
    set pvt_home_name [ad_pvt_home_name]
    if [empty_string_p $pvt_home_name] {
	set pvt_home_name [_ acs-subsite.Your_Account]
    }
    set logout_url [ad_get_logout_url]

    # Site-wide admin link
    set admin_url {}

    set sw_admin_p [acs_user::site_wide_admin_p -user_id [ad_conn untrusted_user_id]]

    if { $sw_admin_p } {
        set admin_url "/acs-admin/"
        set devhome_url "/acs-admin/developer"
        set locale_admin_url "/acs-lang/admin"
    } else {
        set subsite_admin_p [permission::permission_p \
                                 -object_id [subsite::get_element -element object_id] \
                                 -privilege admin \
                                 -party_id [ad_conn untrusted_user_id]]

        if { $subsite_admin_p  } {
            set admin_url "[subsite::get_element -element url]admin/"
        }
    }
} else {
    set login_url [ad_get_login_url -return]
}



# Context bar
if { [template::util::is_nil no_context_p] } {
    if { ![template::util::is_nil context] } {
        set cmd [list ad_context_bar -from_node $subsite_node_id --]
        foreach elem $context {
            lappend cmd $elem
        }
        set context_bar [eval $cmd]
    }
    if [template::util::is_nil context_bar] { 
        set context_bar [ad_context_bar -from_node $subsite_node_id]
    }
} else {
    set context_bar {}
}

# change locale
set num_of_locales [llength [lang::system::get_locales]]
if { $num_of_locales > 1 } {
    set change_locale_url \
        "/acs-lang/?[export_vars { { package_id "[ad_conn package_id]" } }]"
}



# Curriculum bar
set curriculum_bar_p [llength [site_node::get_children -all -filters { package_key "curriculum" } -node_id $subsite_node_id]]
