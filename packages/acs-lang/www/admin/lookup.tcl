ad_page_contract {
    Test message lookup
}

set page_title "Test Message Lookup"
set context [list $page_title]

set message_p 0

ad_form -name lookup -form {
    {key:text
        {label "[_ acs-lang.Message_key]"}
        {help_text "[_ acs-lang.Include_package_key_as]"}
        {html {size 50}}
    }
    {locale:text 
        {label "[_ acs-lang.Locale]"}
        {help_text "[_ acs-lang.Can_be_two_character]"}
    }
} -on_submit {
    # No substitution
    set message [lang::message::lookup $locale $key]
    
    set keyv [split $key "."]
    set package_key [lindex $keyv 0]
    set message_key [lindex $keyv 1]

    set edit_url [export_vars -base edit-localized-message { package_key locale message_key {return_url [ad_return_url]} }]

    set message_p 1
}

