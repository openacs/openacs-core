ad_page_contract {
    Recover forgotten password.

    @author Simon Carstensen
    @creation-date 2003-08-29
    @cvs-id $Id$
} {
    {authority_id:integer ""}
    {username ""}
}

set page_title [_ acs-subsite.Recover_Password]
set context [list $page_title]
set focus ""

# Display form to collect username and authority
set list_of_authorities [auth::authority::get_authority_options]

ad_form -name recover_password -form {
    {authority_id:integer(select)
            {label "Authority"}
        {options $list_of_authorities}
    }
    {username:text
        {label "Username"}
        }
} -on_submit {

    array set recover_info [auth::password::recover_password \
                                -authority_id $authority_id \
                                -username $username]

} -validate {
    {username
        { ![empty_string_p [acs_user::get_by_username -authority_id $authority_id -username $username]] }
        { Authority and username did not match }
    }
}

if { [llength $list_of_authorities] > 1 } {
    set focus "recover_password.authority_id"
} else {
    set focus "recover_password.username"
}

set form_valid_p [form is_valid recover_password]
set form_submitted_p [form is_submission recover_password]

if { [exists_and_not_null authority_id] && [exists_and_not_null username] && !$form_submitted_p } {
    array set recover_info [auth::password::recover_password \
                                -authority_id $authority_id \
                                -username $username]
}

# BEWARE: the template page is a pretty ugly construction! I'm gonna have someone look at it
