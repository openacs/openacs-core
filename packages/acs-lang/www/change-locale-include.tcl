# Tracer Bullet:
# We use this include to change the site wide locale as well as the preferred locale for
# a user
# @author Peter Marklund (peter@collaboraid.biz)

set user_id [ad_conn user_id]

form create locale_form -action "/acs-lang/change-locale"

set locale_option_list [list]
db_foreach locale_loop { select locale, label from ad_locales } {
    lappend locale_option_list [list $label $locale]
}

set user_locale [lang::user::locale]

set site_wide_locale [lang::system::locale]

element create locale_form return_url \
        -datatype text \
        -widget hidden \
        -value "[ad_conn url]?[ad_conn query]"

element create locale_form site_wide_locale \
        -datatype text \
        -widget select \
        -label "Site Wide Locale" \
        -options $locale_option_list \
        -value $site_wide_locale

if { $user_id != "0" } {
    element create locale_form user_locale \
        -datatype text \
        -widget select \
        -label "User Locale Preference" \
        -options $locale_option_list \
        -value $user_locale
} else {
    element create locale_form user_preference_inform \
            -datatype text \
            -widget inform \
            -label  "User Locale Preference" \
            -value "Please log in to specify a user preference"
}

#global message_debug_map

set message_debug_html ""
#if { [info exists message_debug_map] } {

#    set message_debug_html "<ul>"
#    foreach item $message_debug_map {
#        append message_debug_html "<li>[lindex $item 0] - [lindex $item 1]</li>"
#    }
#    append message_debug_html "</ul>"
#}
