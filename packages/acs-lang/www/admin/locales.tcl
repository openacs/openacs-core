# /packages/gp-lang/www/gpadmin/locales.tcl
ad_page_contract {
    Locales administration (creation, edition, deletion)

    @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
    @creation-date March 14, 2002
    @cvs-id $Id$
} {
} -properties {
}

set locale_user [ad_conn locale]

set context_bar [ad_context_bar "Locales Administration"]

db_multirow -extend { 
    escaped_locale
    msg_edit_url
    locale_edit_url
    locale_delete_url
    locale_make_default_url
    locale_enabled_p_url
} locales select_locales {
    select l.locale as locale,
           l.label as locale_label,
           l.default_p as default_p,
           l.enabled_p as enabled_p,
           (select count(*) from ad_locales l2 where l2.language = l.language) as num_locales_for_language
    from ad_locales l
    order by locale_label
} {
    set escaped_locale [ns_urlencode $locale]
    set msg_edit_url "display-grouped-messages?[export_vars { locale }]"
    set locale_edit_url "locale-edit?[export_vars { locale }]"
    set locale_delete_url "locale-delete?[export_vars { locale }]"
    set locale_make_default_url "locale-make-default?[export_vars { locale }]"
    set toggle_enabled_p [ad_decode $enabled_p "t" "f" "t"]
    set locale_enabled_p_url "locale-set-enabled-p?[export_vars { locale {enabled_p $toggle_enabled_p} }]"
    
}
