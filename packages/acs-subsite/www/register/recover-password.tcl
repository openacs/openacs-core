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
set authority_options [auth::authority::get_authority_options]

if { [llength $authority_options] > 1 } {
    ad_form -name recover_password -edit_buttons [list [list [_ acs-subsite.Recover_Password_Button] ok]] -form {
        {authority_id:integer(select) 
            {label "[_ acs-kernel.authentication_authority]"} 
            {options $authority_options}
            {value $authority_id}
        }
    }
} else {
    ad_form -name recover_password -edit_buttons [list [list [_ acs-subsite.Recover_Password_Button] ok]] -form {
        {authority_id:integer(hidden) 
            {value $authority_id}
        }
    }
}

ad_form -extend -name recover_password -form { 
    {username:text
        {label "Username"}
        {value $username}
    }
} -on_submit {

    if { ![exists_and_not_null authority_id] } {
        # Will be defaulted to local authority
        set authority_id ""
    }



    array set recover_info [auth::password::recover_password \
                                -authority_id $authority_id \
                                -username $username]

} -validate {
    {username
        { ![empty_string_p [acs_user::get_by_username -authority_id $authority_id -username $username]] }
        { Authority and username did not match }
    }
}

if { [llength $authority_options] > 1 } {
    set focus "recover_password.authority_id"
} else {
    set focus "recover_password.username"
}

set form_valid_p [form is_valid recover_password]
set form_submitted_p [form is_submission recover_password]


if { [exists_and_not_null username] && !$form_submitted_p } {
    array set recover_info [auth::password::recover_password \
                                -authority_id $authority_id \
                                -username $username]
}


