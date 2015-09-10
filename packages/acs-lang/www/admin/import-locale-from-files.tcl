ad_page_contract {
    Import all catalog messages for a given locale from
    the file system. Should typically only be done once
    as it may overwrite translations already in the database
    for the given locale

    @author Peter Marklund
} {
    locale
}

set locale_label [lang::util::get_label $locale]
set page_title "Import all messages for locale $locale"
set return_url [export_vars -base package-list { locale }]
set context [list [list $return_url $locale_label] $page_title]

lang::catalog::import -locales [list $locale]



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
