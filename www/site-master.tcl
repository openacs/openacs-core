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

if { [template::util::is_nil subnavbar_link] } {
    set subnavbar_link ""
}

# Where to find the stylesheet
set css_url "/resources/acs-subsite/site-master.css"

# Get system name
set system_name [ad_system_name]
set system_url [ad_url]
if { [string equal [ad_conn url] "/"] } {
    set system_url ""
}

# Get user information
set sw_admin_p 0
set user_id [ad_conn user_id]
set untrusted_user_id [ad_conn untrusted_user_id]
if { $untrusted_user_id != 0 } {
    set user_name [person::name -person_id $untrusted_user_id]
    set pvt_home_url [ad_pvt_home]
    set pvt_home_name [ad_pvt_home_name]
    if [empty_string_p $pvt_home_name] {
	set pvt_home_name [_ acs-subsite.Your_Account]
    }
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

if { $untrusted_user_id == 0 } {
    set login_url [ad_get_login_url -return]
}

# Context bar
if { [info exists context] } {
    set context_tmp $context
    unset context
} else {
    set context_tmp {}
}
ad_context_bar_multirow -- $context_tmp


# change locale
set num_of_locales [llength [lang::system::get_locales]]
if { $num_of_locales > 1 } {
    set change_locale_url \
        "/acs-lang/?[export_vars { { package_id "[ad_conn package_id]" } }]"
}

# Curriculum bar
if { [empty_string_p [site_node::get_package_url -package_key curriculum]] } {
    set curriculum_bar_p 0
} else {
    set curriculum_bar_p 1
}

# Who's Online
set num_users_online [lc_numeric [whos_online::num_users]]

set whos_online_url "[subsite::get_element -element url]shared/whos-online"


#----------------------------------------------------------------------
# Display user messages
#----------------------------------------------------------------------

util_get_user_messages -multirow "user_messages"
