ad_page_contract {
    Add a new user to the system, if the email doesn't already exist.

    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
} {
    email
}

set page_title "Inivite Member to [ad_conn instance_name]"
set context [list [list "." "Members"] "Invite"]

set group_id [application_group::group_id_from_package_id]

#
# Check if email already belongs to a user
#

set found_p [db_0or1row select_user { select user_id from cc_users where lower(email) = lower(:email) }]

if { $found_p } {
    # A user with this email already exists. Make them members.
    set member_state approved

    db_transaction {
	set rel_id [relation_add -member_state $member_state "membership_rel" $group_id $user_id]
    } on_error {
	ad_return_error "Error creating the relation" "We got the following error message while trying to create this relation: <pre>$errmsg</pre>"
	ad_script_abort
    }

    ad_returnredirect .
    ad_script_abort
}

