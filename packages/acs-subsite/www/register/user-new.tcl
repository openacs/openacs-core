ad_page_contract {
    Page for users to register themselves on the site.

    @cvs-id $Id$
} -validate {
    password_1 {
	if {![string equal $password_1 $password_2]} {
	    ad_complain "[_ acs-subsite.lt_The_passwords_youve_e]"
	}
    }
}

ad_form -name register -form [auth::get_registration_form_elements] -on_submit {

    array set creation_info [auth::create_user \
                            -first_names $first_names \
                            -last_name $last_name \
                            -email $email \
                            -url $url \
                            -username $username \
                            -password $password_1 \
                            -secret_question $secret_question \
                            -secret_answer $secret_answer]

    # Handle registration problems

    switch $creation_info(creation_status) {
        ok {
            # Continue below
        }
        default {
            # Adding the error to just some element, not sure where it makes sense
            # AFAIK, we can't add errors to the form in general ...
            ad_form_complain -element first_names -error creation_info(auth_message)
            
            # Element messages
            foreach { elm_name elm_error } $creation_info(element_messages) {
                ad_form_complain -element $elm_name -error $elm_error
            }
            continue
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

