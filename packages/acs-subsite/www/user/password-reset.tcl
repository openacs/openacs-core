ad_page_contract {
    Let's the user reset his/her password.

    @cvs-id $Id$
} {
    {user_id {[ad_conn untrusted_user_id]}}
    {return_url ""}
    {password_hash ""}
    {message ""}
}

# Redirect to HTTPS if so configured
if { [security::RestrictLoginToSSLP] } {
    security::require_secure_conn
}

if { ![auth::password::can_change_p -user_id $user_id] } {
    ad_return_error "Not supported" "Changing password is not supported."
}

set admin_p [permission::permission_p -object_id $user_id -privilege admin]

if { !$admin_p } {
    permission::require_permission -party_id $user_id -object_id $user_id -privilege write
}



set page_title [_ acs-subsite.Reset_Password]
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]

set system_name [ad_system_name]
set site_link [ad_site_home_link]



acs_user::get -user_id $user_id -array user

ad_form -name reset -edit_buttons [list [list [_ acs-kernel.common_update] "ok"]] -form {
    {user_id:integer(hidden)}
    {return_url:text(hidden),optional}
    {password_hash:text(hidden),optional}
    {message:text(hidden),optional}
}

ad_form -extend -name reset -form {
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

    set password_hash_local [db_string get_password_hash {SELECT password FROM users WHERE user_id = :user_id}]

    if {$password_hash_local eq $password_hash} {

    array set result [auth::password::change \
                          -user_id $user_id \
                          -old_password "" \
                          -new_password $password_1]

    switch $result(password_status) {
        ok {
            # Continue
        }
        default {
            form set_error reset password_1 $result(password_message)
            break
        }
    }

    } else {
        form set_error reset password_1 "Invalid hash"
	break
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
    set continue_url $return_url

    ad_return_template /packages/acs-subsite/www/register/display-message
}
