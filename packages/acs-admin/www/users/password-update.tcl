ad_page_contract {
    Let's the admin change a user's password.

    @version $Id$
} {
    {user_id:integer}
    {return_url ""}
    {password_old ""}
}


set context_bar [list [list users Users] [list "user.tcl?user_id=$user_id" "usuario"] "Update Password"]

set site_link [ad_site_home_link]

ad_return_template