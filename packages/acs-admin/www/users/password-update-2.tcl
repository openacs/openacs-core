ad_page_contract {
    Updates the users password if password_1 matches password_2
   
    @cvs-id $Id$
} {
    user_id:integer,notnull
    password_1:notnull
    password_2:notnull
    {return_url ""}

} -validate {
    confirm_password -requires {password_2:notnull} {
        if {[empty_string_p $password_2]} {
            ad_complain "You need to confirm the password"
        }
    }
    new_password_match -requires {password_1:notnull password_2:notnull confirm_password} {
        if {![string equal $password_1 $password_2]} {
            ad_complain "Your passwords don't match"
        }
    }
}

ad_change_password $user_id $password_1


set system_owner [ad_system_owner]
set system_name [ad_system_name]

set subject "Password change on $system_name"
set change_password_url "[ad_url]/user/password-update?[export_vars {user_id {password_old $password_1}}]"
set body "Please login again to $system_name using the new password $password_1 and change it immediately to something more of your liking."

set email [acs_user::get_element -user_id $user_id -element email]

# Send email
if [catch {ns_sendmail $email $system_owner $subject $body} errmsg] {
	ns_log Error "Error sending mail" $errmsg
	ad_return_error \
        "Error sending mail" \
        "There was an error sending the mail" 
} else {

    set system_name [ad_system_name]
    set admin_subject "The following email was sent."
    set admin_message "The following email was sent."


    if [catch {ns_sendmail $system_owner $system_owner $admin_subject $admin_message} errmsg] {
	
	ns_log Error "Error sending email from password-update-2.tcl" $errmsg
	ad_return_error \
		"Error sending mail" \
		"There was an error sending the mail to user_id $user_id"
    }
}


if {[empty_string_p $return_url]} {
    set return_url "user?user_id=$user_id"
}

ad_returnredirect $return_url
