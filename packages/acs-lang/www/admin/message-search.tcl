ad_page_contract {

    Search for localized messages containing a certain substring, 
    in order to help translators ensure consistent terminology.

} {
    locale
}

set page_title "Search Messages"
set context_bar [ad_context_bar [list "display-grouped-messages?[export_vars { locale }]" "Listing"] $page_title]

set default_locale en_US

set search_locales [list]
lappend search_locales [list "Current locale - [ad_locale_get_label $locale]" $locale ]
lappend search_locales [list "Master locale - [ad_locale_get_label $default_locale]" $default_locale]

set submit_p 0

ad_form -name search -form {
    {locale:text(hidden)}
    {q:text 
        {label "Search message for"}
    }
    {search_locale:text(select)
        {options $search_locales}
        {label "In locale"}
    }
} -on_request {
    # locale will be set now
} -on_submit {
    set submit_p 1
    # q and seach_locale will now be set as local variables.

    set search_string "%$q%"

    db_multirow -extend { package_url edit_url } messages select_messages {} {
        set edit_url "edit-localized-message?[export_vars { message_key locale package_key {return_url {[ad_return_url]} } }]"
        set package_url "batch-editor?[export_vars { package_key locale }]"
    }
}

