# Redirect to HTTPS if so configured
if { [security::RestrictLoginToSSLP] } {
    security::require_secure_conn
}

set level [ad_decode [security::RestrictLoginToSSLP] 1 "secure" "ok"]

# If the user is changing passwords for another user, they need to be account ok
set account_status [ad_decode $user_id [ad_conn untrusted_user_id] "closed" "ok"]

auth::require_login \
    -level $level \
    -account_status $account_status

if { ![auth::password::can_change_p -user_id $user_id] } {
    ad_return_error "Not supported" "Changing password is not supported."
}

set page_title [_ acs-subsite.Update_Password]
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]

set system_name [ad_system_name]
set site_link [ad_site_home_link]



acs_user::get -user_id $user_id -array user

ad_form -name update -edit_buttons [list [list [_ acs-kernel.common_update] "ok"]] -form {
    {user_id:integer(hidden)}
    {return_url:text(hidden),optional}
    {message:text(hidden),optional}
}


set focus "update.password_old"


ad_form -extend -name update -form {
    {password_1:text(password)
        {label {[_ acs-subsite.New_Password]}}
        {html {size 20}}
    }
    {password_2:text(password)
        {label {[_ acs-subsite.Confirm]}}
        {html {size 20}}
    }
} -on_request {
    
} -validate {
    {password_1
        { [string equal $password_1 $password_2] }
        { Passwords don't match }
    }
} -on_submit {
    array set result [auth::password::change \
                          -user_id $user_id \
                          -old_password "" \
                          -new_password $password_1]

    switch $result(password_status) {
        ok {
            # Continue
        }
        old_password_bad {
            if { (![info exists old_password] || $old_password eq "") } {
                form set_error update password_old $result(password_message)
            } else {
                # This hack causes the form to reload as if submitted, but with the old password showing
                ad_returnredirect [export_vars -base [ad_conn url] -entire_form -exclude { old_password } -override { { password_old $old_password } }]
                ad_script_abort
            }
	    ad_return_error $result(password_message) ""
	    break
        }
        default {
            form set_error update password_1 $result(password_message)
	    break
        }

    }
   
    # If the account was closed, it might be open now
    if {[ad_conn account_status] eq "closed"} {
        auth::verify_account_status
    }
    
} -after_submit {
    if { $return_url eq "" } {
        set return_url [ad_pvt_home]
        set pvt_home_name [ad_pvt_home_name]
        set continue_label [_ acs-subsite.Continue_to_your_account]
    } else {
        set continue_label [_ acs-subsite.Continue]
    }
    set message [_ acs-subsite.confirmation_password_changed]

    # set continue_url $return_url
    # ad_return_template /packages/acs-subsite/www/register/display-message

    ad_returnredirect $return_url
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
