# /packages/acs-lang/www/admin/locale-make-default.tcl

ad_page_contract {

    Makes a locale the default for its language

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 19 march 2002
    @cvs-id $Id$
} {
    locale
} -properties {
}

# If have first to revert the other locale to default_p = f
db_transaction {

    set language_from_locale [db_string select_lang_from_locale "select
        language from ad_locales where locale = :locale"]

    db_dml make_locale_not_default "update ad_locales set default_p = 'f'
        where language = :language_from_locale and default_p = 't'"

    db_dml make_locale_default "update ad_locales set default_p = 't'
        where locale = :locale"
}

# Flush caches
util_memoize_flush_regexp {^lang::util::default_locale_from_lang_not_cached}

template::forward "index?tab=locales"

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
