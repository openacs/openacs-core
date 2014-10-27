# Expects properties:
#   doc(title)
#   focus
#   head
#   section
#   subnavbar_link
#
#  Allowed properties
#  skip_link, href of link to skip to. Should be of format #skip_link
#  defaults to #content-wrapper

# DRB: This is a TEMPORARY kludge to get 5.3.2 out.  This should really set the navigation
# tab info then "master" to the site default-master, not site-master.  However, Lee's first
# implementation of the new master scheme only provides for a single-level tab system for
# tab navigation, rather than the two-level tab system implemented by the group master template.

# This should be generalized and ideally, someday, tied in with portal navigation.

# But for now - kludge city.

set system_name [ad_system_name]
if {[ad_conn url] eq "/"} {
    set system_url ""
} else {
    set system_url [ad_url]
}

if {![info exists title]} {
    # TODO: decide how best to set the lang attribute for the title
    set title [ad_conn instance_name]
}

if {![template::multirow exists link]} {
    template::multirow create link rel type href title lang media
}

set untrusted_user_id [ad_conn untrusted_user_id]
set sw_admin_p 0

if { $untrusted_user_id == 0 } {
    # The browser does NOT claim to represent a user that we know about
    set login_url [ad_get_login_url -return]
} else {
    # The browser claims to represent a user that we know about
    set user_name [person::name -person_id $untrusted_user_id]
    set pvt_home_url [ad_pvt_home]
    set pvt_home_name [_ acs-subsite.Your_Account]
    set logout_url [ad_get_logout_url]

    # Site-wide admin link
    set admin_url {}

    set sw_admin_p [acs_user::site_wide_admin_p -user_id $untrusted_user_id]

    if { $sw_admin_p } {
        set admin_url "/acs-admin/"
        set devhome_url "/acs-admin/developer"
        set locale_admin_url "/acs-lang/admin"
    } else {
        set subsite_admin_p [permission::permission_p \
            -object_id [subsite::get_element -element object_id] \
            -privilege admin \
            -party_id $untrusted_user_id]

        if { $subsite_admin_p  } {
            set admin_url "[subsite::get_element -element url]admin/"
        }
    }
}

#
# User messages
#
util_get_user_messages -multirow user_messages

# 
# Set acs-lang urls
#
set acs_lang_url [apm_package_url_from_key "acs-lang"]
set num_of_locales [llength [lang::system::get_locales]]

if {$acs_lang_url eq ""} {
    set lang_admin_p 0
} else {
    set lang_admin_p [permission::permission_p \
        -object_id [site_node::get_element \
            -url $acs_lang_url \
            -element object_id] \
        -privilege admin \
        -party_id [ad_conn untrusted_user_id]]
}

set toggle_translator_mode_url [export_vars \
    -base ${acs_lang_url}admin/translator-mode-toggle \
    {{return_url [ad_return_url]}}]

set package_id [ad_conn package_id]
if { $num_of_locales > 1 } {
    set change_locale_url [export_vars -base $acs_lang_url {package_id}]
}

#
# Change locale link
#
if {[llength [lang::system::get_locales]] > 1} {
    set change_locale_url [export_vars -base "/acs-lang/" {package_id}]
}

#
# Who's Online
#
set num_users_online [lc_numeric [whos_online::num_users]]
set whos_online_url "[subsite::get_element -element url]shared/whos-online"


if { ![info exists section] } {
    set section {}
}

if { ![info exists subnavbar_link] } {
    set subnavbar_link {}
}

# This will set 'sections' and 'subsections' multirows
subsite::define_pageflow -section $section
subsite::get_section_info -array section_info

#
# Context bar
#
if {[info exists context]} {
    set context_tmp $context
    unset context
} else {
    set context_tmp {}
}

ad_context_bar_multirow -- $context_tmp

#
# Curriculum specific bar
#   TODO: remove this and add a more systematic / package independent way 
#   TODO  of getting this content here
#
set curriculum_bar_p [expr {
    [site_node::get_package_url -package_key curriculum] ne ""
}]


# Find the subsite we belong to
set subsite_url [lindex [site_node::get_url_from_object_id -object_id [site_node::closest_ancestor_package -include_self -package_key [subsite::package_keys]]] 0]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)
set subsite_name $subsite_sitenode(instance_name)

if {[ad_conn url] eq $subsite_url} {
    set subsite_url {}
}

if {![info exists skip_link]} {
    set skip_link "#content-wrapper"
}