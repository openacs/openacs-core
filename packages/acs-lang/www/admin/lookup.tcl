ad_page_contract {
    Test message lookup
}

set page_title "Test Message Lookup"
set context [list $page_title]

set message_p 0

ad_form -name lookup -form {
    {key:text
        {label "Message key"}
        {help_text "Include package key, as in package-key.message-key"}
        {html {size 50}}
    }
    {locale:text 
        {label "Locale"}
        {help_text "Can be two-character for language only or five-character full locale"}
    }
} -on_submit {
    # No substitution
    set message [lang::message::lookup $locale $key {} {} 0]
    
    set keyv [split $key "."]
    set package_key [lindex $keyv 0]
    set message_key [lindex $keyv 1]

    set edit_url [export_vars -base edit-localized-message { package_key locale message_key {return_url [ad_return_url]} }]

    set message_p 1
}

