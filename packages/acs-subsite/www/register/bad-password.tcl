# /www/register/bad-password.tcl

ad_page_contract {
    Informs the user that they have typed in a bad password.
    @cvs-id $Id$
} {
    {user_id:naturalnum}
    {return_url ""}
} -properties {
    system_name:onevalue
    email_forgotten_password_p:onevalue
    user_id:onevalue
}

set email_forgotten_password_p [ad_parameter EmailForgottenPasswordP security 1]

set system_name [ad_system_name]

ad_return_template