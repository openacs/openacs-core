# /packages/gp-lang/www/gpadmin/locales.tcl
ad_page_contract {
    Locales administration (creation, edition, deletion)

    @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
    @creation-date March 14, 2002
    @cvs-id $Id$
} {
} -properties {
}

# Check the locale from the user
if { [exists_and_not_null locales] } {
    set locale_user $locales
} else {
    set locale_user [ad_locale_locale_from_lang [ad_locale user language]]
}

#  AS - doesn't work
#  set encoding_charset [ad_locale charset $locale_user]
#  ns_setformencoding $encoding_charset
#  ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=$encoding_charset"

set context_bar [ad_context_bar "Locales Administration"]

db_multirow -extend { escaped_locale } locales select_locales {
    select l.locale as locale,
           l.label as locale_label,
           l.default_p as default_p
    from ad_locales l
    order by locale_label
} {
    set escaped_locale [ns_urlencode $locale]
}

db_release_unused_handles
