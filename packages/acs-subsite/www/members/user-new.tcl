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

set admin_p [ad_permission_p -user_id [ad_conn user_id] $group_id "admin"]

db_1row group_info {
    select group_name, join_policy
    from groups
    where group_id = :group_id
}
set create_p [group::permission_p -privilege create $group_id]
set member_state [group::default_member_state -join_policy $join_policy -create_p $create_p]

if {[string equal $join_policy "closed"] && !$create_p} {
    ad_complain "You do not have permission to add elements to $group_name"
    return
}



set found_p [db_0or1row select_user { select user_id from cc_users where email = :email }]

if { $found_p } {
    # A user with this email already exists. Make them members.

    db_transaction {
	set rel_id [relation_add -member_state $member_state "membership_rel" $group_id $user_id]
    } on_error {
	ad_return_error "Error creating the relation" "We got the following error message while trying to create this relation: <pre>$errmsg</pre>"
	ad_script_abort
    }

    ad_returnredirect .
    ad_script_abort
}

# User does not exist
ad_form -name user -cancel_url . -form {
    {user_id:integer(hidden)
        {value {[db_nextval "acs_object_id_seq"]}}
    }
    {email:text(inform)
        {label "Email"}
        {value $email}
        {html {size 50}}
    }
    {first_names:text
        {label "First names"}
        {html {size 50}}
    }
    {last_name:text
        {label "Last name"}
        {html {size 50}}
    }
    {url:text,optional
        {label "Home page"}
        {html {size 50}}
    }
}

# Only admins can add non-membership_rel members
if { $admin_p } {
    ad_form -extend -name user -form {
        {rel_type:text(select)
            {label "Role"}
            {options {[group::get_rel_types_options -group_id $group_id]}}
        }
    }
}

ad_form -extend -name user -on_submit {
    set password [ad_generate_random_string]

    if {[ad_parameter RegistrationRequiresEmailVerificationP "security" 0]} {
	set email_verified_p "f"
    } else {
	set email_verified_p "t"
    }

    set double_click_p [db_string user_exists {
	select case when exists
	                 (select 1 from users where user_id = :user_id)
	       then 1 else 0 end
	from dual
    }]
    
    if {!$double_click_p} {
        
	db_transaction {
	    set user_id [ad_user_new \
                             $email \
                             $first_names \
                             $last_name \
                             $password \
                             {} \
                             {} \
                             $url \
                             $email_verified_p \
                             $member_state \
                             $user_id]
            
            # Only admins can add non-membership_rel members
            if { !$admin_p } {
                set rel_type "membership_rel"
            }

            # Hack for adding users to the main subsite, whose application group is the registered users group.
            relation_add -member_state $member_state $rel_type $group_id $user_id

	} on_error {
	    	ad_return_error "User Creation Failed" "We were unable to create the user record in the database."
	}
    }
    
    ad_returnredirect .

    if {!$double_click_p} {

	set notification_address [ad_parameter NewRegistrationEmailAddress "security" [ad_system_owner]]

	if {[ad_parameter NotifyAdminOfNewRegistrationsP "security" 0]} {

	    set creation_user [ad_conn user_id]
	    set creation_name [db_string creation_name_query {
	    select p.first_names || ' ' || p.last_name 
	              || ' (' || pa.email || ')'
            from persons p, parties pa
            where p.person_id = pa.party_id and p.person_id = :creation_user
	    }]

	    # we're supposed to notify the administrator when someone new registers
	    ns_sendmail $notification_address \
		    [template::element::get_value add_user email] \
		    "New registration at [ad_url]" "
	[template::element::get_value add_user first_names] [template::element::get_value add_user last_name] ([template::element::get_value add_user email]) was added as a registered as a user of 
[ad_url]

The user was added by $creation_name from [ad_conn url].
	"
        }

	if { $email_verified_p == "f" } {
	
	    set row_id [db_string user_new_2_rowid_for_email "select rowid from users where user_id = :user_id"]
	    # the user has to come back and activate their account

	    ns_sendmail [template::element::get_value add_user email] \
		    $notification_address \
		    "Welcome to [ad_system_name]" \
		    "To confirm your registration, please go to [ad_parameter -package_id [ad_acs_kernel_id] SystemURL]/register/email-confirm?[export_url_vars row_id]

After confirming your email, here's how you can log in at [ad_url]:

Username:  [template::element::get_value add_user email]
Password:  $password
"
	
	} else {
	    with_catch errmsg {
#		ns_log Notice "sending mail from $notification_address to [template::element::get_value add_user email]"
		ns_sendmail [template::element::get_value add_user email] \
			$notification_address \
			"Thank you for visiting [ad_system_name]" \
			"Here's how you can log in at [ad_url]:
	    
Username:  [template::element::get_value add_user email]
Password:  $password
"
            } {
		ns_returnerror "500" "$error"
		ns_log Warning "Error sending registration confirmation to $email in acs-subsite/www/admin/users/new Error: $errmsg"
	    }
	}


    }

    ad_script_abort
}
