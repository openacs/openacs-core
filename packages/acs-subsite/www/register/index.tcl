ad_page_contract {
    Prompt the user for email and password.
    @cvs-id $Id$
} {
    return_url:optional
}


# TODO: Move this entire thing to an includeable template and make sure it'll still work

# TODO: Forgotten passwords



# Persistent login
# The logic is: 
#  1. Allowed if allowed both site-wide (on acs-kernel) and on the subsite
#  2. Default setting is in acs-kernel

set allow_persistent_login_p [parameter::get -parameter AllowPersistentLoginP -package_id [ad_acs_kernel_id] -default 1]
if { $allow_persistent_login_p } {
    set allow_persistent_login_p [parameter::get -parameter AllowPersistentLoginP -default 1]
}
if { $allow_persistent_login_p } {
    set default_persistent_login_p [parameter::get -parameter DefaultPersistentLoginP -package_id [ad_acs_kernel_id] -default 1]
}


set subsite_url [subsite::get_element -element url]
set system_name [ad_system_name]

if { ![exists_and_not_null return_url] } {
    set return_url [ad_pvt_home]
}

# One common problem with login is that people can hit the back button
# after a user logs out and relogin by using the cached password in
# the browser. We generate a unique hashed timestamp so that users
# cannot use the back button.

set time [ns_time]
set token_id [sec_get_random_cached_token_id]
set token [sec_get_token $token_id]
set hash [ns_sha1 "$time$token_id$token"]


# TODO: Move this into a library proc
set authority_options [db_list_of_lists select_authorities {
    select pretty_name, authority_id
    from   auth_authorities
    where  enabled_p = 't'
    and    auth_impl_id is not null
    order  by sort_order
}]

# TODO: Not implemented
set forgotten_pwd_url [auth::password::get_forgotten_url]

ad_form -name login -form {
    {return_url:text(hidden)}
    {time:text(hidden)}
    {token_id:text(hidden)}
    {hash:text(hidden)}
} 

if { [llength $authority_options] > 1 } {
    ad_form -extend -name login -form {
        {authority_id:integer(select) 
            {label "Authority"} 
            {options $authority_options}
        }
    }
}

ad_form -extend -name login -form {
    {username:text
        {label "Username"}
    }
    {password:text(password) 
        {label "Password"}
    }
}

if { $allow_persistent_login_p } {
    ad_form -extend -name login -form {
        {persistent_p:text(checkbox)
            {label ""}
            {options { { "Remember my login on this computer" "t" } }}
            {value {[ad_decode $default_persistent_login_p 1 "t" ""]}}
        }
    }
}

ad_form -extend -name login -on_request {
    # Populate fields
} -on_submit {
    if { ![exists_and_not_null authority_id] } {
        # Will be defaulted to local authority
        set authority_id {}
    }

    if { ![exists_and_not_null persistent_p] } {
        set persistent_p "f"
    }
    
    array set auth_info [auth::authenticate \
                             -authority_id $authority_id \
                             -username $username \
                             -password $password \
                             -persistent=[expr $allow_persistent_login_p && [template::util::is_true $persistent_p]]]
    
    # Handle authentication problems
    switch $auth_info(auth_status) {
        ok {
            # Continue below
        }
        bad_password {
            form set_error login password $auth_info(auth_message)
            break
        }
        default {
            form set_error login username $auth_info(auth_message)
            break
        }
    }


    # Handle account status
    switch $auth_info(account_status) {
        ok {
            # Continue below
        }
        default {
            # Display the message on a separate page
            set page_title "Login denied"
            set context [list [list "." [_ acs-subsite.Log_In]] "Login denied"]
            set message $auth_info(account_message)
            ad_return_template "display-message"
            break
        }
    }
} -after_submit {

    # We're logged in

    # Handle account_message
    if { [exists_and_not_null auth_info(account_message)] } {
        set page_title "Logged In"
        set context [list [list "." [_ acs-subsite.Log_In]] "Logged in"]
        set message $auth_info(account_message)
        set continue_url $return_url
        set continue_label "Continue working with [ad_system_name]"
        ad_return_template "display-message"
        return    
    } else {
        # No message
        ad_returnredirect $return_url
        ad_script_abort
   }
}
