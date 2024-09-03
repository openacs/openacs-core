ad_page_contract {
    Administer the PrivateEmailLevelP parameter

    @author Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
} {

} -properties {
    context:onevalue
}

set context [list [list "." "Users"] "\"#acs-subsite.manage_users_email\#\""]

ad_form -name private-email -form {
    {level:oneof(select)
        {label "\#acs-subsite.Change_my_email_P\#:"}
        {options {{"[_ acs-subsite.email_as_text_admin]" 4} {"[_ acs-subsite.email_as_image_admin]" 3} \
                      {"[_ acs-subsite.email_as_a_form_admin]" 2} {"[_ acs-subsite.email_dont_show_admin]" 1}}}
    }
} -on_request {
    set level [parameter::get -package_id [ad_conn subsite_id] \
                              -parameter "PrivateEmailLevelP" -default 4]
} -on_submit {
    parameter::set_value -package_id [ad_conn subsite_id] \
                         -parameter "PrivateEmailLevelP" \
                         -value $level

} -after_submit {
    ad_returnredirect "/acs-admin/users/"
    ad_script_abort
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
