ad_page_contract {
    Let's the admin change a user's password.

    @version $Id$
} {
    {user_id:integer}
    {return_url ""}
    {password_old ""}
}

acs_user::get -user_id $user_id -array userinfo
set context [list [list "./" "Users"] [list "user.tcl?user_id=$user_id" $userinfo(email)] "Update Password"]

set site_link [ad_site_home_link]

ad_return_template