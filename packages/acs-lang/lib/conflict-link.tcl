ad_include_contract {
    Display the link to conflicting message keys
} {
    {package_key:token ""}
    {locale:token ""}
}

set conflict_count [lang::message::conflict_count \
                        -package_key $package_key \
                        -locale $locale]

set message_conflicts_url [export_vars -base message-conflicts -no_empty {package_key locale}]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
