ad_page_contract {

    Changes the member state of a user

    @author Hiro Iwashima <iwashima@mit.edu>
    @creation-date 23 Aug 2000
    @cvs-id $Id$

} {
    user_id
    {member_state "no_change"}
    {email_verified_p "no_change"}
    {return_url ""}
} -properties {
    context:onevalue
    export_vars:onevalue
    action:onevalue
    return_url:onevalue
}

if {![db_0or1row get_states {
    select email_verified_p as email_verified_p_old,
           member_state as member_state_old,
           first_names || ' ' || last_name as name,
           email,
           rel_id,
           row_id
    from cc_users
    where user_id = :user_id
}]} {
    # The user is not in there
    ad_return_complaint 1 "Invalid User: the user is not in the system"
    return
}

set action ""

switch $member_state {
    "approved" {
	set action "Approve $name"
	set email_message "Your membership in [ad_system_name] has been approved. Please return to [ad_url]."
    }
    "banned" {
	set action "Ban $name"
	set email_message "You have been banned from [ad_system_name]."
    }
    "rejected" {
	set action "Reject $name"
	set email_message "Your account have been rejected from [ad_system_name]."
    }
    "deleted" {
	set action "Delete $name"
	set email_message "Your account have been deleted from [ad_system_name]."
    }
    "needs approval" {
	set action "Require Admin Approval for $name"
	set email_message "Your account at [ad_system_name] is awaiting approval from an administrator."
    }
}

switch $email_verified_p {
    "t" {
	set action "Approve Email for $name"
	set email_message "Your email in [ad_system_name] has been approved.  Please return to [ad_url]."
    }
    "f" {
	set action "Require Email from $name"
	set email_message "Your email in [ad_system_name] needs approval. please go to [ad_url]/register/email-confirm?[export_url_vars row_id]"
    }
}

if [empty_string_p $action] {
    ad_return_complaint 1 "Not valid action: You have not changed the user in any way"
    return
}

if {[catch {
    acs_user::change_state -user_id $user_id -state $member_state

    switch $email_verified_p {
        "t" {
            db_exec_plsql approve_email "
                begin acs_user.approve_email ( user_id => :user_id ); end;"
        }
        "f" {
            db_exec_plsql unapprove_email "
                begin acs_user.unapprove_email ( user_id => :user_id ); end;"
        }
    }
} errmsg]} {
    ad_return_error "Database Update Failed" "Database update failed with the following error:
    <pre>$errmsg</pre>"
}

set admin_user_id [ad_conn user_id]
set email_from [db_string admin_email "select email from parties where party_id = :admin_user_id"]
set subject "$action"
set message $email_message

if [empty_string_p $return_url] {
    set return_url "/acs-admin/users/one?[export_url_vars user_id]"
} else {
    ad_returnredirect $return_url
    ad_script_abort
}

set context [list [list "./" "Users"] "$action"]
set export_vars [export_url_vars email email_from subject message return_url]

ad_return_template
