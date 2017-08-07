ad_page_contract {
    Change member state

    This page is only suited for admins of the group and handles state
    changes and notification emails.
    
} {
    {rel_id:naturalnum,multiple ""}
    {member_state:notnull}
    {send_notification_mail:boolean,notnull 0}
}

permission::require_permission -object_id $rel_id -privilege "admin"

set membership_rel_info [membership_rel::get -rel_id $rel_id]
set group_id    [dict get $membership_rel_info group_id]
set rel_user_id [dict get $membership_rel_info user_id]
acs_user::get -user_id $rel_user_id -array user_info

#
# Get the locale of the user, which can be influenced by his local
# settings.
#
set locale [lang::user::locale -user_id $rel_user_id]

if {$send_notification_mail} {
    #
    # Compose a mail to notifiy the user about the new state
    #
    set action [group::get_member_state_pretty -component action \
                    -member_state $member_state \
                    -user_name $user_info(username) \
                    -locale $locale]
    #
    # When the group is an application group, then return the url of
    # the package instance.
    #
    set package_id [application_group::package_id_from_group_id -group_id $group_id]
    if {$package_id ne ""} {
        set url [util_current_location][apm_package_url_from_id $package_id]
    } else {
        # Fall back to a default. Wanted?
        set url [ad_url]
    }
    group::get -group_id $group_id -array group_info
    set message [group::get_member_state_pretty -component community_mail \
                     -member_state $member_state \
                     -community_name $group_info(title) \
                     -url $url \
                     -locale $locale]
    #
    # Use the current user in the "from" field of the email
    #
    set email_from [ad_conn user_id]
    
    acs_mail_lite::send -send_immediately \
        -to_addr $user_info(email) \
        -from_addr $email_from \
        -subject $action \
        -body $message

    ad_returnredirect [export_vars -base . { member_state group_id}]
    ad_script_abort
    
} else {
    #
    # Perform the state change
    #
    set return_url [export_vars -base . { member_state group_id}]
    
    membership_rel::change_state \
        -rel_id $rel_id \
        -state $member_state
    
    if {$member_state in {approved rejected}} {
        #
        # In the approved state, we offer the admin to write a
        # notification mail.
        #
        set action [group::get_member_state_pretty -component action \
                        -member_state $member_state \
                        -user_name $user_info(username) \
                        -locale $locale]
        set doc(title) $action
        set context [list [list "./" "Members"] "$action"]
        set email_link [export_vars -base member-state-change {
            member_state rel_id {send_notification_mail 1}
        }]
    } else {
        ad_returnredirect $return_url
        ad_script_abort
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
