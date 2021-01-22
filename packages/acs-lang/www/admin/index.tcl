# /packages/acs-lang/www/admin/index.tcl

ad_page_contract {

    Administration of the localized messages

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 19 October 2001
    @cvs-id $Id$
}

# We rename to avoid conflict in queries
set system_locale [lang::system::locale -site_wide]
set system_locale_label [lang::util::get_label $system_locale]

set page_title [_ acs-lang.Administration_of_Localization]
set context [list]

set site_wide_admin_p [acs_user::site_wide_admin_p]

set timezone_p [lang::system::timezone_support_p]

set timezone [lang::system::timezone]

set translator_mode_p [lang::util::translator_mode_p]

set import_url [export_vars -base import-messages]
set export_url [export_vars -base export-messages]

template::add_confirm_handler -id action-import \
    -message [_ acs-lang.Are_you_sure_you_want_to_import_all_I18N_messages_from_catalog_files]
template::add_confirm_handler -id action-export \
    -message [_ acs-lang.Are_you_sure_you_want_to_export_all_I18N_messages_to_catalog_files]

set parameter_url [export_vars -base "/shared/parameters" {
    {package_id {[ad_conn package_id]} }
    { return_url {[ad_return_url]} }
}]


#####
#
# Locales
#
#####

set default_locale "en_US"
db_1row counts {
    select count(*) as num_messages
    from lang_messages 
    where locale = :default_locale and deleted_p = 'f'
}

db_multirow -extend { 
    escaped_locale
    msg_edit_url
    locale_edit_url
    locale_delete_url
    locale_make_default_url
    locale_enabled_p_url
    num_translated_pretty
    num_untranslated
    num_untranslated_pretty
} locales select_locales {
    select l.locale,
           l.label as locale_label,
           l.language,
           l.default_p as default_p,
           l.enabled_p as enabled_p,
           (select count(*) from ad_locales l2 where l2.language = l.language) as num_locales_for_language,
           (select count(*) from lang_messages lm2 where lm2.locale = l.locale and lm2.deleted_p = 'f') as num_translated
    from   ad_locales l
    order  by locale_label
} {
    set escaped_locale [ns_urlencode $locale]
    set msg_edit_url [export_vars -base package-list { locale }]
    set locale_edit_url [export_vars -base locale-edit { locale }]
    set locale_delete_url [export_vars -base locale-delete { locale }]
    set locale_make_default_url [export_vars -base locale-make-default { locale }]
    set toggle_enabled_p [ad_decode $enabled_p "t" "f" "t"]
    set locale_enabled_p_url [export_vars -base locale-set-enabled-p { locale {enabled_p $toggle_enabled_p} }]
    
    set num_translated_pretty [lc_numeric $num_translated]
    set num_untranslated [expr {$num_messages - $num_translated}]
    set num_untranslated_pretty [lc_numeric $num_untranslated]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
