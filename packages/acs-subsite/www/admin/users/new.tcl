ad_page_contract {

    Adds a new party

    @author oumi@arsdigita.com
    @creation-date 2000-02-07
    @cvs-id $Id$

} {
    { user_type:notnull "user" }
    { user_type_exact_p:boolean t }
    { user_id:naturalnum "" }
    { return_url:localurl "" }
    {add_to_group_id:naturalnum ""}
    {add_with_rel_type "user_profile"}
    {group_rel_type_list ""}
} -properties {
    context:onevalue
    user_type_pretty_name:onevalue
    attributes:multirow
}

set context [list [list "" "Parties"] "Add a user"]

set export_var_list [list \
        user_id user_type add_to_group_id add_with_rel_type \
        return_url user_type_exact_p group_rel_type_list]

db_1row group_info {
    select group_name as add_to_group_name,
           join_policy as add_to_group_join_policy
    from groups
    where group_id = :add_to_group_id
}

# We assume the group is on side 1...
db_1row rel_type_info {}

set create_p [permission::permission_p -object_id $add_to_group_id -privilege "create"]

# Membership relations have a member_state attribute that gets set
# based on the group's join policy.
if {$ancestor_rel_type eq "membership_rel"} {
    if {$add_to_group_join_policy eq "closed" && !$create_p} {
        ad_complain "You do not have permission to add elements to $add_to_group_name"
        return
    }

    set rel_member_state [group::default_member_state -join_policy $add_to_group_join_policy -create_p $create_p]
} else {
    set rel_member_state ""
}

# Select out the username and the user's object type. The validate
# filter above will catch missing parties

acs_object_type::get -object_type $user_type -array object_type
set user_type_pretty_name $object_type(pretty_name)
set table_name            $object_type(table_name)

## ISSUE / TO DO: (see also admin/groups/new.tcl)
##
## Should there be a check here for required segments, as there is
## in parties/new.tcl? (see parties/new.tcl, search for
## "relation_required_segments_multirow).
##
## Tentative Answer: we don't need to repeat that semi-heinous check on this
## page, because (a) the user should have gotten to this page through
## parties/new.tcl, so the required segments check should have already
## happened before the user reaches this page.  And (b) even if the user
## somehow bypassed parties/new.tcl, they can't cause any relational
## constraint violations in the database because the constraints are enforced
## by triggers in the DB.

if { $user_type_exact_p == "f"
     && [subsite::util::sub_type_exists_p $user_type] } {

    # Sub user-types exist... select one
    set user_type_exact_p "t"
    set export_url_vars [export_vars -exclude user_type $export_var_list ]

    party::types_valid_for_rel_type_multirow \
        -datasource_name object_types \
        -start_with $user_type \
        -rel_type $add_with_rel_type

    set object_type_pretty_name $user_type_pretty_name
    set this_url [ad_conn url]
    set object_type_variable user_type

    ad_return_template ../parties/add-select-type
    return
}

template::form create add_user

if { [template::form is_request add_user] } {

    foreach var $export_var_list {
        template::element create add_user $var \
                -value [set $var] \
                -datatype text \
                -widget hidden
    }

    # Set the object id for the new user
    template::element set_properties add_user user_id \
            -value [db_nextval "acs_object_id_seq"]

}

foreach var [list email first_names last_name] {
    template::element create add_user $var \
            -datatype text -widget text -html {size 30}
}

template::element create add_user url \
        -datatype text -widget text -html {size 30} -optional


template::element create add_user password \
        -datatype text -widget inform -html {size 30} \
        -value "-- automatically generated --"


# Get whether they require some sort of approval
if {[parameter::get -parameter RegistrationRequiresApprovalP -default 0]} {
    set member_state ""
} else {
    set member_state "approved"
}

# attribute::add_form_elements -form_id add_user -variable_prefix user -start_with user -object_type $user_type

attribute::add_form_elements \
    -form_id add_user \
    -variable_prefix rel \
    -start_with relationship \
    -object_type $add_with_rel_type


if { [template::form is_valid add_user] } {

    set password [ad_generate_random_string]

    if {$add_to_group_id eq ""} {
        set add_to_group_id [application_group::group_id_from_package_id]
    }

    if {[parameter::get -parameter RegistrationRequiresEmailVerificationP -default 0]} {
        set email_verified_p "f"
    } else {
        set email_verified_p "t"
    }

    set double_click_p [db_string user_exists {select count(*) from users where user_id = :user_id}]
    set add_user_email       [template::element::get_value add_user email]
    set add_user_first_names [template::element::get_value add_user first_names]
    set add_user_last_name   [template::element::get_value add_user last_name]

    if {!$double_click_p} {

        db_transaction {

            # LARS: Hack - we should use acs-subsite/lib/user-new instead

            array set result [auth::create_user \
                                  -user_id $user_id \
                                  -email $add_user_email \
                                  -first_names $add_user_first_names \
                                  -last_name $add_user_last_name \
                                  -password $password \
                                  -password_confirm $password \
                                  -url [template::element::get_value add_user url] \
                                  -email_verified_p $email_verified_p]

            # LARS: Hack, we should check the result
            set user_id $result(user_id)

            # Hack for adding users to the main subsite, whose application group is the registered users group.

            if { $add_to_group_id != [acs_magic_object "registered_users"] ||
                 $add_with_rel_type ne "membership_rel"
             } {
                relation_add -member_state $rel_member_state $add_with_rel_type $add_to_group_id $user_id
            }

        } on_error {
            ad_return_error "User Creation Failed" "We were unable to create the user record in the database."
            ad_script_abort
        }
    }

    # there may be more segments to put this new party in before the
    # user's original request is complete.   So build a return_url stack
    foreach group_rel_type $group_rel_type_list {
        lassign $group_rel_type next_group_id next_rel_type
        lappend return_url_list \
            [export_vars -base "../relations/add" {
                {group_id $next_group_id}
                {rel_type $next_rel_type}
                {party_id $user_id}
                {allow_out_of_scope_p t}
            }]
    }

    # Add the original return_url as the last one in the list
    lappend return_url_list $return_url

    set return_url_stacked [subsite::util::return_url_stack $return_url_list]

    if {$return_url_stacked eq ""} {
        set return_url_stacked [export_vars -base ../parties/one {{party_id $user_id}}]
    }
    ad_returnredirect $return_url_stacked

    if {!$double_click_p} {

        set notification_address [parameter::get \
                                      -parameter NewRegistrationEmailAddress \
                                      -default [ad_system_owner]]

        if {[parameter::get -parameter NotifyAdminOfNewRegistrationsP -default 0]} {

            set creation_user [ad_conn user_id]
            set user_info [acs_user::get -user_id $creation_user]
            set creation_name "[dict get $user_info name] ([dict get $user_info email])"

            # we're supposed to notify the administrator when someone new registers

            acs_mail_lite::send \
                -send_immediately \
                -to_addr $notification_address \
                -from_addr $add_user_email \
                -subject "New registration at [ad_url]" \
                -body "$add_user_first_names $add_user_last_name ($add_user_email) was added as a registered as a user of
[ad_url]

The user was added by $creation_name from [ad_conn url]."

        }

        if { $email_verified_p == "f" } {

            set row_id [db_string user_new_2_rowid_for_email {}]
            # the user has to come back and activate their account

            set system_url [parameter::get -package_id [ad_acs_kernel_id] -parameter SystemURL]
            set href [export_vars -base $system_url/register/email-confirm {row_id}]
            acs_mail_lite::send \
                -to_addr $add_user_email \
                -from_addr $notification_address \
                -subject "Welcome to [ad_system_name]" \
                -body "To confirm your registration, please go to $href

After confirming your email, here's how you can log in at [ad_url]:

Username:  $add_user_email
Password:  $password
"
        } else {
            ad_try {
                # ns_log Notice "sending mail from $notification_address to $add_user_email"
                acs_mail_lite::send \
                        -to_addr $add_user_email \
                        -from_addr $notification_address \
                        -subject "Thank you for visiting [ad_system_name]" \
                        -body "Here's how you can log in at [ad_url]:

Username:  $add_user_email
Password:  $password
"
            } on error {errmsg} {
                ns_returnerror 500 $errmsg
                ns_log Warning "Error sending registration confirmation to $email in acs-subsite/www/admin/users/new Error: $errmsg"
            }
        }
    }

    ad_script_abort
}


ad_return_template


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
