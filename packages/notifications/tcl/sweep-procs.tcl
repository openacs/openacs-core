ad_library {

    Notification Sweeps

    @creation-date 2002-05-27
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::sweep {

    ad_proc -public schedule_all {} {
        This schedules all the notification procs
    } {
    }

    ad_proc -public send_one {
        {-user_id:required}
        {-subject:required}
        {-content:required}
        {-response_id:required}
        {-delivery_method_id:required}
    } {
        hack currently send only by email
        # FIXME
    } {
        # Get email
        set email [cc_email_from_party $user_id]

        acs_mail_lite::send -to_addr $email -from_addr "notifications@openforce.biz" \
                -subject $subject \
                -body $content
    }

    ad_proc -public cleanup_notifications {} {
        Clean up the notifications that are done
    } {
        # Get the list of the ones to kill
        set notification_id_list [db_list select_notification_ids {}]

        # Kill them
        foreach notification_id $notification_id_list {
            notification::delete -notification_id $notification_id
        }
    }
    
    ad_proc -public sweep_notifications {
        {-interval_id:required}
        {-batched_p 0}
    } {
        This sweeps for notifications in a particular interval
    } {
        # Look for notifications joined against the requests they may match with the right interval_id
        # order it by user_id
        # make sure the users have not yet received this notification with outer join
        # on the mapping table and a null check
        set notifications [db_list_of_ns_sets select_notifications {}]

        foreach notif $notifications {
            # If not batched, just send out and mark it
            if {!$batched_p} {
                db_transaction {
                    # Send it
                    send_one -user_id [ns_set get $notif user_id] \
                            -subject "\[[ad_system_name] - [ns_set get $notif object_name]\]: [ns_set get $notif notif_subject]" \
                            -content [ns_set get $notif notif_text] \
                            -response_id [ns_set get $notif response_id] \
                            -delivery_method_id [ns_set get $notif delivery_method_id]

                    # Markt it as sent
                    notification::mark_sent -notification_id [ns_set get $notif notification_id] \
                            -user_id [ns_set get $notif user_id]
                }
            } else {
                # It's batched, we're not handling this one yet
                ns_log Notice "Notifcations: Batched Request not handled"
            }
        }
    }

}
