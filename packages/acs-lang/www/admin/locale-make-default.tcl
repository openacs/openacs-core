# /packages/acs-lang/www/admin/locale-make-default.tcl

ad_page_contract {

    Makes a locale the default for its language

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 19 march 2002
    @cvs-id $Id$
} {
    locales
} -properties {
}

# If have first to revert the other locales to default_p = f
db_transaction {

    set language_from_locale [db_string select_lang_from_locale "select
        language from ad_locales where locale = :locales"]

    db_dml make_locales_not_default "update ad_locales set default_p = 'f'
        where language = :language_from_locale and default_p = 't'"

    db_dml make_locales_default "update ad_locales set default_p = 't'
        where locale = :locales"

    util_memoize_flush [list ad_locale_locale_from_lang $locales]

}

template::forward "index?tab=locales"
