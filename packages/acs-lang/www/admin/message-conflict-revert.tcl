ad_page_contract {
    Revert the a message to the last overwritten version. 
    Mark conflict of an I18N message as resolved, i.e.
    set the conflict_p flag to false.

    @author Peter Marklund
} {
    package_key
    message_key
    locale
    {return_url:localurl {[export_vars -base "message-conflicts" { package_key locale }]}}
}

db_transaction {
    lang::message::revert \
        -package_key $package_key \
        -message_key $message_key \
        -locale $locale

    lang::message::edit $package_key $message_key $locale [list conflict_p f]
}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
