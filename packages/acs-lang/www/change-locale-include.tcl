# Tracer Bullet:
# We use this include to change the site wide locale as well as the preferred locale for
# a user
# @author Peter Marklund (peter@collaboraid.biz)

if { ![exists_and_not_null return_url] && [exists_and_not_null return_p] && [string equal $return_p "t"] } {
    # Use referer header
    set return_url [ns_set iget [ns_conn headers] referer]
}

form create locale

element create locale return_url \
        -datatype text \
        -widget hidden \
        -optional \
        -value $return_url

element create locale user_locale \
        -datatype text \
        -widget select \
        -label "Your Preferred Locale" \
        -options [db_list_of_lists locale_loop { select label, locale from ad_locales }] \
        -value [lang::user::locale]

if { [form is_valid locale] } {
    form get_values locale user_locale return_url

    lang::user::set_locale $user_locale

    ad_returnredirect $return_url
    ad_script_abort
}