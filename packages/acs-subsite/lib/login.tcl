# Present a login box
#
# Expects:
#   subsite_id - optional, defaults to nearest subsite
#   return_url - optional, defaults to Your Account
# Optional:
#   authority_id
#   username
#   email
#

# Redirect to HTTPS if so configured
if { [security::RestrictLoginToSSLP] } {
    security::require_secure_conn
}

set self_registration [parameter::get_from_package_key \
                                  -package_key acs-authentication \
			          -parameter AllowSelfRegister \
			          -default 1]   

if { ![exists_and_not_null package_id] } {
    set subsite_id [subsite::get_element -element object_id]
}

set email_forgotten_password_p [parameter::get \
                                    -parameter EmailForgottenPasswordP \
                                    -package_id $subsite_id \
                                    -default 1]

if { ![info exists username] } {
    set username {}
}

if { ![info exists email] } {
    set email {}
}

if { $email eq "" && $username eq "" && [ad_conn untrusted_user_id] != 0 } {
    acs_user::get -user_id [ad_conn untrusted_user_id] -array untrusted_user
    if { [auth::UseEmailForLoginP] } {
        set email $untrusted_user(email)
    } else {
        set authority_id $untrusted_user(authority_id)
        set username $untrusted_user(username)
    }
}




# Persistent login
# The logic is: 
#  1. Allowed if allowed both site-wide (on acs-kernel) and on the subsite
#  2. Default setting is in acs-kernel

set allow_persistent_login_p [parameter::get -parameter AllowPersistentLoginP -package_id [ad_acs_kernel_id] -default 1]
if { $allow_persistent_login_p } {
    set allow_persistent_login_p [parameter::get -package_id $subsite_id -parameter AllowPersistentLoginP -default 1]
}
if { $allow_persistent_login_p } {
    set default_persistent_login_p [parameter::get -parameter DefaultPersistentLoginP -package_id [ad_acs_kernel_id] -default 1]
} else {
    set default_persistent_login_p 0
}


set subsite_url [subsite::get_element -element url]
set system_name [ad_system_name]

if { [exists_and_not_null return_url] } {
    if { [util::external_url_p $return_url] } {
      ad_returnredirect -message "only urls without a host name are permitted" "."
      ad_script_abort
    }
} else {
    set return_url [ad_pvt_home]
}

set authority_options [auth::authority::get_authority_options]

if { ![exists_and_not_null authority_id] } {
    set authority_id [lindex [lindex $authority_options 0] 1]
}

set forgotten_pwd_url [auth::password::get_forgotten_url -authority_id $authority_id -username $username -email $email]

set register_url [export_vars -base "[subsite::get_url]register/user-new" { return_url }]
if { $authority_id eq [auth::get_register_authority] || [auth::UseEmailForLoginP] } {
    set register_url [export_vars -no_empty -base $register_url { username email }]
}

set login_button [list [list [_ acs-subsite.Log_In] ok]]
ad_form -name login -html { style "margin: 0px;" } -show_required_p 0 -edit_buttons $login_button -action "[subsite::get_url]register/" -form {
    {return_url:text(hidden)}
    {time:text(hidden)}
    {token_id:text(hidden)}
    {hash:text(hidden)}
} 

set username_widget text
if { [parameter::get -parameter UsePasswordWidgetForUsername -package_id [ad_acs_kernel_id]] } {
    set username_widget password
}

set focus {}
if { [auth::UseEmailForLoginP] } {
    ad_form -extend -name login -form [list [list email:text($username_widget),nospell [list label [_ acs-subsite.Email]] [list html [list style "width: 150px"]]]]
    set user_id_widget_name email
    if { $email ne "" } {
        set focus "password"
    } else {
        set focus "email"
    }
} else {
    if { [llength $authority_options] > 1 } {
        ad_form -extend -name login -form {
            {authority_id:integer(select) 
                {label "[_ acs-subsite.Authority]"} 
                {options $authority_options}
            }
        }
    }

    ad_form -extend -name login -form [list [list username:text($username_widget),nospell [list label [_ acs-subsite.Username]] [list html [list style "width: 150px"]]]]
    set user_id_widget_name username
    if { $username ne "" } {
        set focus "password"
    } else {
        set focus "username"
    }
}
set focus "login.$focus"

ad_form -extend -name login -form {
    {password:text(password) 
        {label "[_ acs-subsite.Password]"}
	{html {style "width: 150px"}}
    }
}

set options_list [list [list [_ acs-subsite.Remember_my_login] "t"]]
if { $allow_persistent_login_p } {
    ad_form -extend -name login -form {
        {persistent_p:text(checkbox),optional
            {label ""}
            {options $options_list}
        }
    }
}

ad_form -extend -name login -on_request {
    # Populate fields from local vars

    set persistent_p [ad_decode $default_persistent_login_p 1 "t" ""]

    # One common problem with login is that people can hit the back button
    # after a user logs out and relogin by using the cached password in
    # the browser. We generate a unique hashed timestamp so that users
    # cannot use the back button.
    
    set time [ns_time]
    set token_id [sec_get_random_cached_token_id]
    set token [sec_get_token $token_id]
    set hash [ns_sha1 "$time$token_id$token"]

} -on_submit {

    # Check timestamp
    set token [sec_get_token $token_id]
    set computed_hash [ns_sha1 "$time$token_id$token"]
    
    set expiration_time [parameter::get -parameter LoginPageExpirationTime -package_id [ad_acs_kernel_id] -default 600]
    if { $expiration_time < 30 } { 
        # If expiration_time is less than 30 seconds, it's practically impossible to login
        # and you will have completely hosed login on your entire site
        set expiration_time 30
    }

    if { $hash ne $computed_hash  || \
             $time < [ns_time] - $expiration_time } {
        ad_returnredirect -message [_ acs-subsite.Login_has_expired] -- [export_vars -base [ad_conn url] { return_url }]
        ad_script_abort
    }

    if { ![exists_and_not_null authority_id] } {
        # Will be defaulted to local authority
        set authority_id {}
    }

    if { ![exists_and_not_null persistent_p] } {
        set persistent_p "f"
    }
    if {![element exists login email]} {
	set email [ns_queryget email ""]
    }
    set first_names [ns_queryget first_names ""]
    set last_name [ns_queryget last_name ""]
    
    array set auth_info [auth::authenticate \
                             -return_url $return_url \
                             -authority_id $authority_id \
                             -email [string trim $email] \
                             -first_names $first_names \
                             -last_name $last_name \
                             -username [string trim $username] \
                             -password $password \
                             -persistent=[expr {$allow_persistent_login_p && [template::util::is_true $persistent_p]}]]
    
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
            form set_error login $user_id_widget_name $auth_info(auth_message)
            break
        }
    }

    if { [exists_and_not_null auth_info(account_url)] } {
        ad_returnredirect $auth_info(account_url)
        ad_script_abort
    }

    # Handle account status
    switch $auth_info(account_status) {
        ok {
            # Continue below
        }
        default {
	    # if element_messages exists we try to get the element info
	    if {[info exists auth_info(element_messages)]
		&& [auth::authority::get_element \
			-authority_id $authority_id \
			-element allow_user_entered_info_p]} {
		foreach message [lsort $auth_info(element_messages)] {
		    ns_log notice "LOGIN $message"
		    switch -glob -- $message {
			*email* {
 			    if {[element exists login email]} {
 				set operation set_properties
 			    } else {
 				set operation create
 			    }
			    element $operation login email -widget $username_widget -datatype text -label [_ acs-subsite.Email]
			    if {[element error_p login email]} {
				template::form::set_error login email [_ acs-subsite.Email_not_provided_by_authority]
			    }
			}
			*first* {
			    element create login first_names -widget text -datatype text -label [_ acs-subsite.First_names]
			    template::form::set_error login email [_ acs-subsite.First_names_not_provided_by_authority]
			}
			*last* {
			    element create login last_name -widget text -datatype text -label [_ acs-subsite.Last_name]
			    template::form::set_error login last_name [_ acs-subsite.Last_name_not_provided_by_authority]
			}
		    }
		}
		set auth_info(account_message) ""
		    
		ad_return_template
		
	    } else {
		# Display the message on a separate page
		ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-closed" { { message $auth_info(account_message) } }]
		ad_script_abort
	    }
        }
    }
} -after_submit {

    # We're logged in

    # Handle account_message
    if { [exists_and_not_null auth_info(account_message)] } {
        ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-message" { { message $auth_info(account_message) } return_url }]
        ad_script_abort
    } else {
	if {![info exists auth_info(element_messages)]} {
	    # No message
	    ad_returnredirect $return_url
	    ad_script_abort
	}
    }
}
