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
set css_url "${subsite_url}group-master.css"

# Get system name
set system_name [ad_system_name]
set system_url [ad_url]

# Get user information
set user_id [ad_conn user_id]
if { $user_id != 0 } {
    set user_name [person::name -person_id $user_id]
    set pvt_home_url [ad_pvt_home]
    set pvt_home_name [ad_pvt_home_name]
    set logout_url [ad_get_logout_url]
} else {
    set login_url [ad_get_login_url -return]
}

# Site-wide admin link
set swadmin_url {}
if { $user_id != 0 } {
    array set swadmin_node [site_node::get -url /acs-admin]
    set swadmin_object_id $swadmin_node(object_id)
    set sw_admin_p [permission::permission_p -party_id $user_id -object_id $swadmin_object_id -privilege admin]
    if { $sw_admin_p } {
        set sw_admin_url "/acs-admin"
    }
}


# Context bar
if { [template::util::is_nil no_context_p] } {
    if { ![template::util::is_nil context] } {
        set context_bar [eval ad_context_bar -top_node_id $subsite_node_id $context]
    }
    if [template::util::is_nil context_bar] { 
        set context_bar [ad_context_bar -top_node_id $subsite_node_id]
    }
} else {
    set context_bar {}
}

