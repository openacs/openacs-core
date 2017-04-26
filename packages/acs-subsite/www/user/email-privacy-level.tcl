ad_page_contract {
    Allows users to change their priv_email field in the users table
    
    @author Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
} {
    {user_id:naturalnum ""}
    {return_url:localurl ""}
}

if { $return_url eq "" } {
    set return_url [ad_pvt_home]
}

set doc(title) [_ acs-subsite.Change_my_email_P]
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $doc(title)]

if {$user_id eq ""} {
    set user_id [auth::require_login -account_status closed]
}

ad_form -name private-email -export return_url -form {
    {level:integer(select)
	{label "\#acs-subsite.Change_my_email_P\#:"}
	{options {
            {"[_ acs-subsite.email_as_text]" 4}
            {"[_ acs-subsite.email_as_image]" 3} 
            {"[_ acs-subsite.email_as_a_form]" 2}
            {"[_ acs-subsite.email_dont_show]" 1}
        }}
    }
} -on_request {
    set level [email_image::get_priv_email -user_id $user_id]
} -on_submit {
    email_image::update_private_p -user_id $user_id -level $level
} -after_submit {
    ad_returnredirect $return_url
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
