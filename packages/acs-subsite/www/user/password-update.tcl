ad_page_contract {
    Let's the user change his/her password.  Asks
    for old password, new password, and confirmation.

    @cvs-id $Id$
} {
    {user_id ""}
    {return_url ""}
    {old_password ""}
    {expired_p:boolean "0"}
}

if {[empty_string_p $user_id]} {
    set user_id [ad_verify_and_get_user_id]
}
if { ![auth::password::can_change_p -user_id $user_id] } {
    ad_return_error "Not allowed" "Changing password is not allowed. Sorry"
}

set context [list [list [ad_pvt_home] "Your Account"] [_ acs-subsite.Update_Password]]

# We have a special provision here for expired passwords
# The user will not be logged in, but we're supposed to log them in after we're done
# We use template::util::is_true in order to be liberal in the input we accept
# SIMON: Do we still want to do this?
set expired_p [template::util::is_true $expired_p]

set system_name [ad_system_name]

set admin_p [permission::permission_p -object_id $user_id -privilege admin]

if { !$admin_p } {
    permission::require_permission -party_id $user_id -object_id $user_id -privilege write
}

db_1row user_information {}

set site_link [ad_site_home_link]
