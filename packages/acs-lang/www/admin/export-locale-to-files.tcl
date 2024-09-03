ad_page_contract {
    Export all catalog messages for a given locale to 
    the filesystem.

    @author Lars Pind (lars@collaboraid.biz)
} {
    locale:word
}

set locale_label [lang::util::get_label $locale]
set page_title "Export all messages for locale $locale"
set return_url [export_vars -base package-list { locale }]
set context [list [list $return_url $locale_label] $page_title]

lang::catalog::export -locales [list $locale]


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
