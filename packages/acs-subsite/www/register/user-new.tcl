ad_page_contract {
    Page for users to register themselves on the site.

    @cvs-id $Id$
} {
    username:optional
    email:optional
    first_names:optional
    last_name:optional
    password:optional
    url:optional
    secret_question:optional
    secret_answer:optional
}

# TODO: Move to includeable chunk


# TODO: log user out if currently logged in, if specified in the includeable chunk's parameters, e.g. not when creating accounts for other users
ad_user_logout 


ad_form -name register -form [auth::get_registration_form_elements] -on_request {
    # Populate elements from local variables
} -on_submit {

    array set creation_info [auth::create_user \
                                 -first_names $first_names \
                                 -last_name $last_name \
                                 -email $email \
                                 -url $url \
                                 -username $username \
                                 -password $password \
                                 -password_confirm $password_confirm \
                                 -verify_password_confirm \
                                 -secret_question $secret_question \
                                 -secret_answer $secret_answer]

    # Handle registration problems
    
    switch $creation_info(creation_status) {
        ok {
            # Continue below
        }
        default {
            # Adding the error to the first element, but only if there are no element messages
            if { [llength $creation_info(element_messages)] == 0 } {
                array set reg_elms [auth::get_registration_elements]
                set first_elm [lindex [concat $reg_elms(required) $reg_elms(optional)] 0]
                form set_error register $first_elm $creation_info(creation_message)
            }
                
            # Element messages
            foreach { elm_name elm_error } $creation_info(element_messages) {
                form set_error register $elm_name $elm_error
            }
            break
        }
    }

    switch $creation_info(account_status) {
        ok {
            # Continue below
        }
        default {
            # Display the message on a separate page
            ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-closed" { { message $creation_info(account_message) } }]
            ad_script_abort
        }
    }

} -after_submit {
    # User is registered and logged in
    if { ![exists_and_not_null return_url] } {
        # Redirect to subsite home page.
        set return_url [subsite::get_element -element url]
    }

    # Handle account_message
    if { ![empty_string_p $creation_info(account_message)] } {
        ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-message" { { message $creation_info(account_message) } return_url }]
        ad_script_abort
    } else {
        # No messages
        ad_returnredirect $return_url
        ad_script_abort
   }
}

