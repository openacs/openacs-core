ad_page_contract {
    Let's the admin change a user's password.
   

    @version $Id$
} {
    {user_id:integer}
    {return_url ""}
    {password_old ""}
} 

db_1row user_information {}

set context_bar [list [list users Users] [list "user.tcl?user_id=$user_id" "$first_names $last_name"] "[_ dotlrn.Update_Password]"]

set site_link [ad_site_home_link]

ad_return_template
