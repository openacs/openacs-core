ad_page_contract {
    Mark conflict of an I18N message as resolved, i.e.
    set the conflict_p flag to false.

    @author Peter Marklund
} {
    package_key
    message_key
    locale
    {return_url {[export_vars -base "message-conflicts" { package_key locale }]}}
}

lang::message::edit $package_key $message_key $locale [list conflict_p f]

ad_returnredirect $return_url
