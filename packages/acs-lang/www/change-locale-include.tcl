ad_page_contract {
    Change user preffered locale

    @author Peter Marklund (peter@collaboraid.biz)
    @author Christian Hvid
} {
    { return_url "" }
    { package_id "" }
}

if { $return_url == "" } {
    # Use referer header
    set return_url [ns_set iget [ns_conn headers] referer]
}

# Create a list of lists containing the possible locale choiches

set list_of_locales [db_list_of_lists locale_loop { select label, locale from enabled_locales order by label }]
set list_of_locales [linsert $list_of_locales 0 [list (default) ""]]

form create locale

# Export variables

element create locale package_id_info -datatype text -widget hidden -optional
element create locale return_url_info -datatype text -widget hidden -optional

if { [form is_valid locale] } {
    set return_url [element get_value locale return_url_info]
    set package_id [element get_value locale package_id_info]
}

element create locale site_wide_explain -datatype text -widget inform -label "&nbsp;" \
        -value "Your locale setting for the whole site."

element create locale site_wide_locale -datatype text -widget select -optional \
        -label "Site-wide Locale" \
        -options $list_of_locales

# are we selecting package level locale as well?

if { ($package_id != "") && ([ad_conn user_id] != 0) } {
    element create locale package_level_explain -datatype text -widget inform -label "&nbsp;" \
            -value "Your locale setting for [apm_instance_name_from_id $package_id]. If set, this will override the site-wide setting in this particular application."
    
    element create locale package_level_locale -datatype text -widget select -optional \
            -label "Locale for [apm_instance_name_from_id $package_id]" \
            -options $list_of_locales
}

if { [lang::system::timezone_support_p] } {
    set timezone_options [list]
    foreach entry [lc_list_all_timezones] {
        set tz [lindex $entry 0]
        lappend timezone_options [list $entry $tz]
    }

    element create locale timezone -datatype text -widget select -optional \
        -label "Your Timezone" \
        -options $timezone_options
}

if { [form is_request locale] } {
    if { ($package_id != "") && ([ad_conn user_id] != 0) } {
        element set_properties locale package_level_locale -value [lang::user::package_level_locale $package_id]
    }
    element set_properties locale site_wide_locale -value [lang::user::site_wide_locale]
    element set_properties locale return_url_info -value $return_url
    element set_properties locale package_id_info -value $package_id
    if { [lang::system::timezone_support_p] } {
        element set_properties locale timezone -value [lang::user::timezone]
    }
}

if { [form is_valid locale] } {
    set site_wide_locale [element get_value locale site_wide_locale]
    lang::user::set_locale -site_wide $site_wide_locale
    if { ($package_id != "") && ([ad_conn user_id] != 0) } {
        set package_level_locale [element get_value locale package_level_locale]
        lang::user::set_locale -package_id $package_id $package_level_locale
    }
    
    if { [lang::system::timezone_support_p] } {
        lang::user::set_timezone [element get_value locale timezone]
    }

    ad_returnredirect $return_url
    ad_script_abort
}
