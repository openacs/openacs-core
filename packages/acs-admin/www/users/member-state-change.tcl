ad_page_contract {

    Changes the member state of a user

    @author Hiro Iwashima <iwashima@mit.edu>
    @creation-date 23 Aug 2000
    @cvs-id $Id$

} {
    user_id:naturalnum,notnull
    {member_state:trim}
    {email_verified_p:boolean ""}
    {return_url:localurl ""}
    {pass_through:boolean false}
} -validate {
    valid_member_state -requires member_state {
        if {$member_state ni {approved banned deleted merged "needs approval" rejected}} {
            ad_complain "invalid member_state '$member_state'"
        }
    }
} -properties {
    context:onevalue
    export_vars:onevalue
    action:onevalue
    return_url:onevalue
}

if {![db_0or1row get_states {
    select member_state as member_state_old,
           email_verified_p as email_verified_p_old
    from cc_users where user_id = :user_id
}]} {
    # The user is not in there
    ad_return_complaint 1 "Invalid User: the user is not in the system"
    return
}

set user [acs_user::get -user_id $user_id]
set name   [dict get $user name]
set email  [dict get $user email]
set rel_id [dict get $user rel_id]

#
# This page is used for state changes in the member_state, and as well
# on email confirm require and approve operations.
#
switch -- $email_verified_p {
    "t" {
        set user_name     $name
        set url           [ad_url]
        set site_name     [ad_system_name]
        set action        [lang::util::localize #acs-kernel.email_action_approved#]
        set email_message [lang::util::localize #acs-kernel.email_mail_approved#]
    }
    "f" {
        set user_name     $name
        set url           [ad_url]/register/email-confirm
        set site_name     [ad_system_name]
        set action        [lang::util::localize #acs-kernel.email_action_needs_approval#]
        set email_message [lang::util::localize #acs-kernel.email_mail_needs_approval#]
    }
    default {
        set action        [group::get_member_state_pretty -component action \
                               -member_state $member_state \
                               -user_name $name]
        set email_message [group::get_member_state_pretty -component account_mail \
                               -member_state $member_state \
                               -site_name [ad_system_name] \
                               -url [ad_url]]
    }
}

ad_try {
    acs_user::change_state -user_id $user_id -state $member_state

    if {$email_verified_p ne ""} {
        acs_user::update \
            -user_id $user_id \
            -email_verified_p $email_verified_p
    }

} on error {errorMsg} {
    ad_return_error "Database Update Failed" "Database update failed with the following error:
    <pre>[ns_quotehtml $errorMsg]</pre>"
    ad_script_abort
}

callback acs_admin::member_state_change -member_state $member_state -user_id $user_id

set admin_user_id [ad_conn user_id]
set email_from [acs_user::get_element -user_id $admin_user_id -element email]
set subject $action
set message $email_message

if {$return_url eq ""} {
    set return_url [acs_community_member_admin_url -user_id $user_id]
}

if {$pass_through || $member_state_old eq $member_state} {
    #
    # No need to ask the admin to send a state notification mail to
    # the user.
    #
    ad_returnredirect $return_url
    ad_script_abort
}

set context [list [list "./" "Users"] "$action"]
set export_vars [export_vars {email email_from subject message return_url}]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
