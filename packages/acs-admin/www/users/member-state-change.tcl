ad_page_contract {

    Changes the member state of a user

    @author-id Hiro Iwashima <iwashima@mit.edu>
    @creation-date 23 Aug 2000
    @cvs-id
} {
    user_id
    {member_state "no_change"}
    {email_verified_p "no_change"}
    {return_url ""}
} -properties {
    context_bar:onevalue
    export_vars:onevalue
    action:onevalue
    return_url:onevalue
}

if ![db_0or1row get_states "select email_verified_p email_verified_p_old, member_state member_state_old, first_names || ' ' || last_name as name, email, rel_id, rowid
from cc_users
where user_id = :user_id"] {
    # The user is not in there

    ad_return_complaint "Invalid User" "The user is not in the system"
    return
}

set action ""

switch $member_state {
    "approved" {
	set action "Approve $name"
	set email_message "Your membership in [ad_system_name] has been approved. Please return to [ad_parameter SystemUrl]."
    }
    "banned" {
	set action "Ban $name"
	set email_message "You have been banned from [ad_system_name]."
    }
    "reject" {
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
	set email_message "Your email in [ad_system_name] has been approved.  Please return to [ad_parameter SystemUrl]."
    }
    "f" {
	set action "Require Email from $name"
	set email_message "Your email in [ad_system_name] needs approval. please go to [ad_parameter SystemURL]/register/email-confirm.tcl?[export_url_vars rowid]"
    }
}

if [empty_string_p $action] {
    ad_return_complaint "Not valid action" "You have not changed the user in any way"
    return
}

if [ catch {switch $member_state {
               "approved" {
                   db_exec_plsql member_approve "
                        begin membership_rel.approve( rel_id => :rel_id ); end;"
               }
               "banned" {
   	            db_exec_plsql member_ban "
                       begin membership_rel.ban( rel_id => :rel_id ); end;"
               }
               "reject" {
   	            db_exec_plsql member_reject "
                       begin membership_rel.reject( rel_id => :rel_id ); end;"
               }
               "deleted" {
   	            db_exec_plsql member_deleted "
                       begin membership_rel.deleted( rel_id => :rel_id ); end;"
               }
               "needs approval" {
   	            db_exec_plsql member_unapprove "
                       begin membership_rel.unapprove( rel_id => :rel_id ); end;"
               }
            }
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
           } errmsg] {
    ad_return_error "Database Update Failed" "Database update failed with the following error:
    <pre>$errmsg</pre>"
}

set admin_user_id [ad_verify_and_get_user_id]
set email_from [db_string admin_email "select email from parties where party_id = :admin_user_id"]
set subject "$action"
set message $email_message

if [empty_string_p $return_url] {
    set return_url "/acs-admin/users/one?[export_url_vars user_id]"
}

set context_bar [ad_admin_context_bar [list "index.tcl" "Users"] "$action"]
set export_vars [export_url_vars email email_from subject message return_url]

ad_return_template
