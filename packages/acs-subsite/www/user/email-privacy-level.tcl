ad_page_contract {
    Allows users to change their priv_email field in the users table
    
    @author Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
} {
    {user_id ""}
}

set page_title  "\"#acs-subsite.Change_my_email_P\#\""
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]

if { [string equal $user_id ""] } {
    set user_id [auth::require_login -account_status closed]
}

ad_form -name private-email -form {
    {level:integer(select)
	{label "\#acs-subsite.Change_my_email_P\#:"}
	{options {{"[_ acs-subsite.email_as_text]" 4} {"[_ acs-subsite.email_as_image]" 3} \
		      {"[_ acs-subsite.email_as_a_form]" 2} {"[_ acs-subsite.email_dont_show]" 1}}}
    }
} -on_request {
    set level [email_image::get_priv_email -user_id $user_id]
} -on_submit {
    email_image::update_private_p -user_id $user_id -level $level
} -after_submit {
    ad_returnredirect [ad_pvt_home]
}