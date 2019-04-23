# /packages/acs-lang/www/admin/index.tcl

ad_page_contract {

    Administration of the localized messages

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 19 October 2001
    @cvs-id $Id$
}

# SWA?
set site_wide_admin_p [acs_user::site_wide_admin_p]

# Translator mode?
set translator_mode_p [lang::util::translator_mode_p]

# Title and context
set page_title [_ acs-lang.Administration_of_Localization]
set context [list]

# We rename to avoid conflict in queries
set system_locale       [lang::system::locale -site_wide]
set system_locale_label [lang::util::get_label $system_locale]

# Timezones
set timezone    [lang::system::timezone]
set timezone_p  [lang::system::timezone_support_p]

# URLs
set import_url      [export_vars -base import-messages]
set export_url      [export_vars -base export-messages]
set parameter_url   [export_vars -base /shared/parameters {
    { package_id {[ad_conn package_id]} }
    { return_url {[ad_return_url]} }
}]

# Confirmation handlers
template::add_confirm_handler -id action-import \
    -message [_ acs-lang.Are_you_sure_you_want_to_import_all_I18N_messages_from_catalog_files]
template::add_confirm_handler -id action-export \
    -message [_ acs-lang.Are_you_sure_you_want_to_export_all_I18N_messages_to_catalog_files]

# Retrieve locale information
set locale_list [db_list locale_list_select {select locale from ad_locales order by locale}]

template::multirow create locales \
    locale \
    locale_label \
    escaped_locale \
    msg_edit_url \
    enabled_p \
    default_p \
    language \
    locale_edit_url \
    locale_delete_url \
    locale_make_default_url \
    locale_enabled_p_url \
    num_messages_pretty \
    num_messages \
    num_translated_pretty \
    num_translated \
    num_untranslated_pretty \
    num_untranslated \
    num_deleted_pretty \
    num_deleted \
    num_locales_for_language_pretty \
    num_locales_for_language

# Populate multirow
set default_locale "en_US"
foreach current_locale $locale_list {
    #
    # Get values per locale
    #
    db_0or1row locale_stats {}
    #
    # Encode locale
    #
    set escaped_locale [ns_urlencode $locale]
    #
    # Enabled locale?
    #
    set toggle_enabled_p [expr {!$enabled_p}]
    #
    # URLs
    #
    set msg_edit_url            [export_vars -base package-list { locale }]
    set locale_edit_url         [export_vars -base locale-edit { locale }]
    set locale_delete_url       [export_vars -base locale-delete { locale }]
    set locale_make_default_url [export_vars -base locale-make-default { locale }]
    set locale_enabled_p_url    [export_vars -base locale-set-enabled-p { locale {enabled_p $toggle_enabled_p} }]
    #
    # Prettify numbers
    #
    set num_messages_pretty             [lc_numeric $num_messages]
    set num_translated_pretty           [lc_numeric $num_translated]
    set num_untranslated_pretty         [lc_numeric $num_untranslated]
    set num_deleted_pretty              [lc_numeric $num_deleted]
    set num_locales_for_language_pretty [lc_numeric $num_locales_for_language]
    #
    # Append to multirow
    #
    template::multirow append locales \
        $locale \
        $locale_label \
        $escaped_locale \
        $msg_edit_url \
        $enabled_p \
        $default_p \
        $language \
        $locale_edit_url \
        $locale_delete_url \
        $locale_make_default_url \
        $locale_enabled_p_url \
        $num_messages_pretty \
        $num_messages \
        $num_translated_pretty \
        $num_translated \
        $num_untranslated_pretty \
        $num_untranslated \
        $num_deleted_pretty \
        $num_deleted \
        $num_locales_for_language_pretty \
        $num_locales_for_language
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
