# includelet pseudo-contract
#    Change user preferred locale

#    @author Peter Marklund (peter@collaboraid.biz)
#    @author Christian Hvid

if { ![info exists return_url] || $return_url eq "" } {
    set return_url [get_referrer -relative]
}

#
# Check if the passed in value or the referer is faked
#
if {[util::external_url_p $return_url]} {
    ad_page_contract_handle_datasource_error "invalid url"
    ad_script_abort
}

if { ![info exists package_id] || $package_id eq "" } {
    set package_id [ad_conn package_id]
}

set use_timezone_p [expr {[lang::system::timezone_support_p] && [ad_conn user_id]}]

#
# LARS:
# I'm thinking the UI here needs to be different.
# 
# Your locale preference and your timezone is going to be set through 'Your Account"
# The package-specific locale setting should be set through a page in dotlrn/acs-subsite
# 
# This page should only be accessed through "Your Account"
# 
# There's no reason to offer an option of 'default' preferred locale. 
# 

# Create a list of lists containing the possible locale choiches

set list_of_locales [list]

db_foreach locale_loop {} {
    if { [lang::message::message_exists_p $locale acs-lang.this-language] } {
        set label "[lang::message::lookup $locale  acs-lang.this-language]"
    }
    lappend list_of_locales [list ${label} $locale]
}

set list_of_package_locales [linsert $list_of_locales 0 [list (default) ""]]

form create locale

# Export variables

element create locale package_id_info -datatype text -widget hidden -optional
element create locale return_url_info -datatype text -widget hidden -optional

if { [form is_valid locale] } {
    set return_url [element get_value locale return_url_info]
    set package_id [element get_value locale package_id_info]

    if {[util::external_url_p $return_url]} {
        ad_return_complaint 1 "invalid url"
        ad_script_abort
    }
    if {![string is integer -strict $package_id]} {
        ad_return_complaint 1 "invalid package_id"
        ad_script_abort
    }
}

# are we selecting package level locale as well?
set package_level_locales_p [expr {[lang::system::use_package_level_locales_p] && $package_id ne "" && [ad_conn user_id] != 0}]

if { $package_level_locales_p } {
    element create locale site_wide_explain -datatype text -widget inform -label "&nbsp;" \
        -value "[_ acs-lang.Your_locale_site_wide]"
}

element create locale site_wide_locale \
    -datatype text \
    -widget select_locales \
    -optional \
    -label "[_ acs-lang.Your_Preferred_Locale]" \
    -options $list_of_locales \
    -values [ad_conn locale]

if { $package_level_locales_p } {
    set package_name [apm_instance_name_from_id $package_id]
    element create locale package_level_explain -datatype text -widget inform -label "&nbsp;" \
            -value "[_ acs-lang.Your_locale_for_package]"
    
    element create locale package_level_locale -datatype text -widget select -optional \
            -label "[_ acs-lang.Locale_for]" \
            -options $list_of_package_locales
}

if { $use_timezone_p } {
    set timezone_options [db_list_of_lists all_timezones {}]

    element create locale timezone -datatype text -widget select -optional \
        -label "[_ acs-lang.Your_timezone]" \
        -options $timezone_options
}

if { [form is_request locale] } {
    if { $package_level_locales_p } {
        element set_properties locale package_level_locale -value [lang::user::package_level_locale $package_id]
    }
    
    set site_wide_locale [lang::user::site_wide_locale]
    if { $site_wide_locale eq "" } {
        set site_wide_locale [lang::system::site_wide_locale]
    }

    element set_properties locale site_wide_locale -value $site_wide_locale
    element set_properties locale return_url_info -value $return_url
    element set_properties locale package_id_info -value $package_id

    if { $use_timezone_p } {
        set timezone [lang::user::timezone]
        if { $timezone eq "" } {
            set timezone [lang::system::timezone]
        }
        element set_properties locale timezone -value $timezone
    }
}

if { [form is_valid locale] } {
    set site_wide_locale [element get_value locale site_wide_locale]
    lang::user::set_locale $site_wide_locale
    if { $package_level_locales_p } {
        set package_level_locale [element get_value locale package_level_locale]
        lang::user::set_locale -package_id $package_id $package_level_locale
    }
    
    if { $use_timezone_p } {
        lang::user::set_timezone [element get_value locale timezone]
    }

    ad_returnredirect $return_url
    ad_script_abort
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
