ad_page_contract {
    Let's the user change his/her password.  Asks
    for old password, new password, and confirmation.

    @cvs-id $Id$
} {
    {user_id {[ad_conn user_id]}}
    {return_url ""}
    {old_password ""}
}

# This is a bit confusing, but old_password is what we get passed in here,
# whereas password_old is the form element.

if { ![auth::password::can_change_p -user_id $user_id] } {
    ad_return_error "Not allowed" "Changing password is not allowed. Sorry"
}

set admin_p [permission::permission_p -object_id $user_id -privilege admin]

if { !$admin_p } {
    permission::require_permission -party_id $user_id -object_id $user_id -privilege write
}



set page_title [_ acs-subsite.Update_Password]
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]

set system_name [ad_system_name]
set site_link [ad_site_home_link]



acs_user::get -user_id $user_id -array user

ad_form -name update -edit_buttons [list [list [_ acs-kernel.common_update] "ok"]] -form {
    {user_id:integer(hidden)}
    {return_url:text(hidden),optional}
    {old_password:text(hidden),optional}
}

if { [exists_and_not_null old_password] } {
    set focus "update.password_1"
} else {
    ad_form -extend -name update -form {
        {password_old:text(password)
            {label {[_ acs-subsite.Current_Password]}}
        }
    }
    set focus "update.password_old"
}

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
    
    if { [exists_and_not_null old_password] } {
        set password_old $old_password
    }
    
    array set result [auth::password::change \
                          -user_id $user_id \
                          -old_password $password_old \
                          -new_password $password_1]
    
    switch $result(password_status) {
        ok {
            # Continue
        }
        old_password_bad {
            if { ![exists_and_not_null old_password] } {
                form set_error update password_old $result(password_message)
            } else {
                # This hack causes the form to reload as if submitted, but with the old password showing
                ad_returnredirect [export_vars -base [ad_conn url] -entire_form -exclude { old_password } -override { { password_old $old_password } }]
                ad_script_abort
            }
            break
        }
        default {
            form set_error update password_1 $result(password_message)
            break
        }
    }

    # Make sure the user is logged in
    # LARS: This looks fairly dangerous to me
    if { [ad_conn user_id] == 0 } {
        ad_user_login $user_id
    }
    
} -after_submit {
    if { [empty_string_p $return_url] } {
        set return_url [ad_pvt_home]
    }
    ad_returnredirect $return_url
    ad_script_abort
}
