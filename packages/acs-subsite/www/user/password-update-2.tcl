ad_page_contract {
    Updates the users password if 
    <ul>
      <li>old_password is correct
      <li>password_1 matches password_2
    <ul>
    @cvs-id $Id$
} {
    password_1:notnull
    password_2:notnull
    {old_password ""}
    {user_id:integer ""}
    {return_url ""}
} -validate {
    confirm_password -requires {password_2:notnull} {
        if {[empty_string_p $password_2]} {
            ad_complain "You need to confirm the password that you typed. (Type the same thing again.)"
        }
    }
}

if {[empty_string_p $user_id]} {
    set user_id [ad_verify_and_get_user_id]
}

if { ![auth::password::can_change_p -user_id $user_id] } {
    # We are not allowd to change password
    # SIMON: What should we do here?
    ad_return_error "Not allowed" "Changing password is not allowed. Sorry"
}

set admin_p [permission::permission_p -object_id $user_id -privilege admin]

if {!$admin_p} {
    permission::require_permission -party_id $user_id -object_id $user_id -privilege write
}


array set change_pwd_info [auth::password::change \
                         -user_id $user_id \
                         -old_password $old_password \
                         -new_password $password_1]

if { [string equal $change_pwd_info(password_status) "ok"] } {
    # Make sure the user is logged in
   if { ![ad_conn user_id] } {
        ad_user_login $user_id
    }
    
    if {[empty_string_p $return_url]} {
        set return_url [ad_parameter -package_id [ad_acs_kernel_id] "HomeURL"]
    }
    
    ad_returnredirect $return_url

}  else {
    # Changing password failed, display password_message
    # SIMON: What should we do here?
    ad_return_error "Failure" $change_pwd_info(password_status)
}

