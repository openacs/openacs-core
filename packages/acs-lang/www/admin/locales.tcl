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

db_multirow -extend { escaped_locale } locales select_locales {
    select l.locale as locale,
           l.label as locale_label,
           l.default_p as default_p
    from ad_locales l
    order by locale_label
} {
    set escaped_locale [ns_urlencode $locale]
}
