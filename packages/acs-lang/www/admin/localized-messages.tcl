ad_page_contract {

    Administration of the localized messages

    @author Bruno Mattarollo <bruno.mattarollo@ams.greenpeace.org>
    @creation-date 19 October 2001
    @cvs-id $Id$
}

#  AS - doesn't work
#  set encoding_charset [ad_locale charset $locale_user]
#  ns_setformencoding $encoding_charset
#  ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=$encoding_charset"

db_multirow -extend { escaped_locale } locales select_locale_list {
    select locale as locale,
           label as locale_name
    from   ad_locales
} {
    set escaped_locale [ns_urlencode $locale]
}

db_release_unused_handles
