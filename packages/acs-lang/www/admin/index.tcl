# /packages/acs-lang/www/admin/index.tcl

ad_page_contract {

    Administration of the localized messages

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 19 October 2001
    @cvs-id $Id$
}
#
# SWA?
#
set site_wide_admin_p [acs_user::site_wide_admin_p]
#
# Translator mode?
#
set translator_mode_p [lang::util::translator_mode_p]
#
# Title and context
#
set page_title [_ acs-lang.Administration_of_Localization]
set context [list]
#
# We rename to avoid conflict in queries
#
set default_locale      "en_US"
set system_locale       [lang::system::locale -site_wide]
set system_locale_label [lang::util::get_label $system_locale]
#
# Timezones
#
set timezone    [lang::system::timezone]
#
# URLs
#
set import_url      [export_vars -base import-messages]
set export_url      [export_vars -base export-messages]
set parameter_url   [export_vars -base /shared/parameters {
    { package_id {[ad_conn package_id]} }
    { return_url {[ad_return_url]} }
}]
#
# Confirmation handlers
#
template::add_confirm_handler -id action-import \
    -message [_ acs-lang.Are_you_sure_you_want_to_import_all_I18N_messages_from_catalog_files]
template::add_confirm_handler -id action-export \
    -message [_ acs-lang.Are_you_sure_you_want_to_export_all_I18N_messages_to_catalog_files]
#
# Retrieve locale information
#
set locale_list [db_list locale_list_select {select locale from ad_locales order by locale}]
#
# Retrieve locale stats
#
# TODO: whenever we stop supporting oracle 11, use LATERAL in the locale_stats
# query, to use one single query instead of one for each locale, and replace the
# logic below. Even better, create a view to get all this data based on that
# query.
#
set locale_stat_list [list]
foreach current_locale $locale_list {
    #
    # Get values per locale
    #
    db_0or1row locale_stats {}
    #
    # Create locale stats dict
    #
    set locale_data [dict create]
    #
    # Locale properties
    #
    dict set locale_data locale         $locale
    dict set locale_data locale_label   $locale_label
    dict set locale_data escaped_locale [ns_urlencode $locale]
    dict set locale_data language       $language
    dict set locale_data enabled_p      $enabled_p
    dict set locale_data default_p      $default_p
    #
    # URLs
    #
    set toggle_enabled_p [expr {!$enabled_p}]
    dict set locale_data msg_edit_url            [export_vars -base package-list { locale }]
    dict set locale_data locale_edit_url         [export_vars -base locale-edit { locale }]
    dict set locale_data locale_delete_url       [export_vars -base locale-delete { locale }]
    dict set locale_data locale_make_default_url [export_vars -base locale-make-default { locale }]
    dict set locale_data locale_enabled_p_url    [export_vars -base locale-set-enabled-p { locale {enabled_p $toggle_enabled_p} }]
    #
    # Numbers
    #
    dict set locale_data num_messages                    $num_messages
    dict set locale_data num_translated                  $num_translated
    dict set locale_data num_untranslated                $num_untranslated
    dict set locale_data num_deleted                     $num_deleted
    dict set locale_data num_locales_for_language        $num_locales_for_language
    dict set locale_data num_messages_pretty             [lc_numeric $num_messages]
    dict set locale_data num_translated_pretty           [lc_numeric $num_translated]
    dict set locale_data num_untranslated_pretty         [lc_numeric $num_untranslated]
    dict set locale_data num_deleted_pretty              [lc_numeric $num_deleted]
    dict set locale_data num_locales_for_language_pretty [lc_numeric $num_locales_for_language]
    #
    # Append to list
    #
    lappend locale_stat_list $locale_data
}
#
# Generate multirow
#
template::util::list_to_multirow locales $locale_stat_list

template::list::create \
    -name locales \
    -multirow locales \
    -actions {
        "#acs-lang.Create_New_Locale#" locale-new "#acs-lang.Create_New_Locale#"
    } \
    -elements {
        edit {
            label {}
            link_url_col locale_edit_url
            display_template {<adp:icon name="edit" title="#acs-lang.Edit_definition_of_locale#">}
        }
        locale {
            sub_class narrow           
            label "#acs-lang.Locale#"
        }
        locale_label {
            label "#acs-lang.Label#"
            link_html {title "#acs-lang.Edit_localized_messages_for#"}
            link_url_col msg_edit_url
        }
        num_translated {
            label "#acs-lang.Translated#"
            display_template {
                <if @locales.enabled_p;literal@ true or @locales.num_translated;literal@ gt 0>
                   <if @locales.num_translated;literal@ ne 0>@locales.num_translated_pretty@</if>
                </if>
            }
            html {align right}
        }
        num_untranslated {
            label "#acs-lang.Untranslated#"
            display_template {
                <if @locales.enabled_p;literal@ true or @locales.num_translated;literal@ gt 0>
                  <if @locales.num_untranslated;literal@ ne 0>@locales.num_untranslated_pretty@</if>
                </if>
            }
            html {align right}
        }
        num_deleted {
            label "#acs-lang.Deleted#"
            display_template {
                <if @locales.enabled_p;literal@ true or @locales.num_translated;literal@ gt 0>
                  <if @locales.num_deleted;literal@ ne 0>@locales.num_deleted_pretty@</if>
                </if>
            }
            html {align right}
        }
        total {
            label "#acs-lang.Total#"
            display_template {
                <if @locales.enabled_p;literal@ true or @locales.num_translated;literal@ gt 0>
                  <if @locales.num_messages;literal@ ne 0>@locales.num_messages_pretty@</if>
                </if>
            }
            html {align right}
        }
        enabled_p {
            label "#acs-lang.Enabled#"
            display_template {
                <if @locales.enabled_p;literal@ true>
                  <a href="@locales.locale_enabled_p_url@" title="#acs-lang.Disable_this_locale#">
                    <adp:icon name="checkbox-checked" title="#acs-lang.Disable_this_locale#">
                  </a>
                </if>
                <else>
                  <a href="@locales.locale_enabled_p_url@" title="#acs-lang.Enable_this_locale#">
                    <adp:icon name="checkbox-unchecked" title="#acs-lang.Enable_this_locale#">
                  </a>
                </else>
            }
            html {align center}
        }
        default_p {
            label "#acs-lang.Default_Locale_For_Language#"
            display_template {
                <if @locales.default_p;literal@ true>
                  <if @locales.num_locales_for_language;literal@ eq 1>
                    <span style="font-style: italic; color: gray;" title="#acs-lang.This_is_the_only_locale_for_this_language#"></span>
                  </if>
                  <else>
                    @locales.language@:
                    <adp:icon name="radio-checked" title="#acs-lang.Default_Locale_For_Language#">
                  </else>
                </if>
                <else>@locales.language@: <a href="@locales.locale_make_default_url@" title="#acs-lang.Make_this_locale_the_default_locale_for_language#">
                   <adp:icon name="radio-unchecked" title="#acs-lang.Make_this_locale_the_default_locale_for_language#">
                </a></else>
            }
            html {align center}
        }
        delete {
            label {}
            link_url_col locale_delete_url
            display_template {<adp:icon name="trash" title="#acs-lang.Delete_this_locale#">}
        }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
