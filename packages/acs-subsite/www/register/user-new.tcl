ad_page_contract {
    Page for users to register themselves on the site.

    @cvs-id $Id$
}

# TODO: Move to includeable chunk


# TODO: log user out if currently logged in, if specified in the includeable chunk's parameters, e.g. not when creating accounts for other users
ad_user_logout 


ad_form -name register -form [auth::get_registration_form_elements] -on_submit {

    array set creation_info [auth::create_user \
                                 -first_names $first_names \
                                 -last_name $last_name \
                                 -email $email \
                                 -url $url \
                                 -username $username \
                                 -password $password \
                                 -password_confirm $password_confirm \
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
            error $creation_info(account_message)
            # Display the message on a separate page
            set message $creation_info(account_message)
            ad_return_template "display-message"
            # TODO: Double-check that this actually causes us to break out of ad_form and have the template display
            return
        }
    }

} -after_submit {
    # User is registered and logged in

    if { ![exists_and_not_null return_url] } {
        # Redirect to subsite home page.
        set return_url [subsite::get_element -element url]
    }

    # TODO: 
    # SIMON: Handle creation_message

    # Handle account_message
    if { ![empty_string_p $creation_info(account_message)] } {
        set message creation_info(account_message)
        set continue_url $return_url
        set continue_label "Continue working with [ad_system_name]"
        ad_return_template "display-message"
        return    
    } else {
        # No messages
        ad_returnredirect $return_url
        ad_script_abort
   }
}

