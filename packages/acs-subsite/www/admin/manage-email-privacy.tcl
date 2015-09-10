ad_page_contract {
    Administer the PrivateEmailLevelP parameter
    
    @author Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
} {

} -properties {
    context:onevalue
}

set page_title  "\"#acs-subsite.manage_users_email\#\""
set context [list [list "." "Users"] "\"#acs-subsite.manage_users_email\#\""]


set user_id [auth::require_login -account_status closed]

ad_form -name private-email -form {
    {level:integer(select)
	{label "\#acs-subsite.Change_my_email_P\#:"}
	{options {{"[_ acs-subsite.email_as_text_admin]" 4} {"[_ acs-subsite.email_as_image_admin]" 3} \
		      {"[_ acs-subsite.email_as_a_form_admin]" 2} {"[_ acs-subsite.email_dont_show_admin]" 1}}}
    }
} -on_request {
    set level [parameter::get_from_package_key -package_key "acs-subsite" \
			    -parameter "PrivateEmailLevelP" -default 4]
} -on_submit {
    set package_id [apm_package_id_from_key acs-subsite]
    parameter::set_value -package_id $package_id -parameter "PrivateEmailLevelP" -value $level

} -after_submit {
    ad_returnredirect "/acs-admin/users/"
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
