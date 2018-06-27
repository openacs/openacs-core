ad_page_contract {
    Let's the admin change a user's password.

    @version $Id$
} {
    {user_id:naturalnum,notnull}
    {return_url:localurl ""}
    {password_old ""}
}

set email [party::get -party_id $user_id -element email]
set context [list [list "./" "Users"] [list "user.tcl?user_id=$user_id" $email] "Update Password"]

set site_link [ad_site_home_link]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
