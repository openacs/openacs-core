ad_page_contract {
    Updates the users password if 
    <ul>
    <li>password_old is correct
    <li>password_1 matches password_2

    @cvs-id $Id$
} -query {
    password_1:notnull
    password_2:notnull
    {password_old ""}
    {user_id:integer ""}
    {return_url ""}
} -validate {
    old_password_match -requires {user_id:integer password_old} {
        if {![permission::permission_p -object_id $user_id -privilege admin] && ![empty_string_p $user_id] && ![ad_check_password $user_id $password_old]} {
            ad_complain "Your current password does not match what you entered in the form."
        }
    }
    confirm_password -requires {password_2:notnull} {
        if {[empty_string_p $password_2]} {
            ad_complain "You need to confirm the password that you typed. (Type the same thing again.)"
        }
    }
    new_password_match -requires {password_1:notnull password_2:notnull confirm_password} {
        if {![string equal $password_1 $password_2]} {
            ad_complain "Your passwords don't match! Presumably, you made a typo while entering one of them."
        }
    }
    new_password_old_password_different -requires { new_password_match } {
        if { [string equal $password_old $password_1] } {
            ad_complain "Your new password is identical to your old password. If you don't want to change your password, use your browser's back button to get out."
        }
    }
}

if {[empty_string_p $user_id]} {
    set user_id [ad_verify_and_get_user_id]
}

set admin_p [permission::permission_p -object_id $user_id -privilege admin]

if {!$admin_p} {
    permission::require_permission -party_id $user_id -object_id $user_id -privilege write
}

if {[catch {ad_change_password $user_id $password_1} errmsg]} {
    ad_return_error "Wasn't able to change your password. Please contact the system administrator."
}

if { ![ad_conn user_id] } {
    ad_user_login $user_id
}

if {[empty_string_p $return_url]} {
    set return_url [ad_parameter -package_id [ad_acs_kernel_id] "HomeURL"]
}

ad_returnredirect $return_url
