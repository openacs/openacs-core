ad_page_contract {

    Sets enabled_p for a locale.

    @author Simon Carstensen (simon@collaboraid.biz)

    @creation-date 2003-08-08
} {
    locale
    enabled_p:boolean
}

db_dml set_enabled_p { update ad_locales set enabled_p = :enabled_p where locale = :locale }

# Flush caches
util_memoize_flush_regexp {^lang::util::default_locale_from_lang_not_cached}
util_memoize_flush_regexp {^lang::system::get_locales}

ad_returnredirect . 
ad_script_abort
