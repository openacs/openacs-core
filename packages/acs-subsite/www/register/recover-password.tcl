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

if { ![exists_and_not_null authority_id] } {
    set authority_id [auth::authority::local]
}

# Display form to collect username and authority
set authority_options [auth::authority::get_authority_options]

ad_form -name recover -edit_buttons [list [list [_ acs-kernel.common_continue] ok]] -form { {dummy:text(hidden),optional} }
    
if { [llength $authority_options] > 1 } {
    ad_form -extend -name recover -form {
        {authority_id:integer(select) 
            {label {[_ acs-kernel.authentication_authority]}} 
            {options $authority_options}
        }
    }
}

set submission_p 0

ad_form -extend -name recover -form { 
    {username:text
        {label "Username"}
        {value $username}
    }
} -validate {
    {username
        { ![empty_string_p [acs_user::get_by_username -authority_id $authority_id -username $username]] }
        { Could not find username at authority }
    }
}

# We handle form submission here, because otherwise we can't handle both the case where we use the form
# and the case where we don't in one go
if { [form is_valid recover] || (![form is_submission recover] && [exists_and_not_null username]) } {
    array set recover_info [auth::password::recover_password \
                                -authority_id $authority_id \
                                -username $username]

    set login_url [ad_get_login_url -authority_id $authority_id -username $username]
}

