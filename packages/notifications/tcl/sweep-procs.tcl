ad_library {

    Notification Sweeps

    @creation-date 2002-05-27
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::sweep {

    ad_proc -deprecated -warn -public schedule_all {} {
        This schedules all the notification procs.
	DEPRECATED.
    } {
    }

    ad_proc -public cleanup_notifications {} {
        Clean up the notifications that have been sent out (DRB: inefficiently...).
    } {
        # LARS:
        # Also sweep the dynamic notification requests that have been sent out
        db_dml delete_dynamic_requests {}

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

        if {$batched_p} {
            set prev_user_id 0
            set prev_type_id 0
            set prev_deliv_method_id ""
            set batched_content ""
            set list_of_notification_ids [list]

            # Add a stop codon
            lappend notifications STOP

            # Batched sending
            foreach notif $notifications {
                ns_log Debug "NOTIF-BATCHED: one notif $notif"

                if {$notif != "STOP"} {
                    ns_log Debug "NOTIF-BATCHED: NOT a stop codon"
                    set user_id [ns_set get $notif user_id]
                    set type_id [ns_set get $notif type_id]
                } else {
                    ns_log Debug "NOTIF-BATCHED stop codon!"
                    set user_id ""
                    set type_id ""
                }

                # Check if we have a new user_id and type_id
                # if so, batch up previous stuff and send it
                if {$notif == "STOP" || $user_id != $prev_user_id || $type_id != $prev_type_id} {

                    ns_log Debug "NOTIF-BATCHED: batching things up for $prev_user_id"

                    # If no content, keep going
                    if {![empty_string_p $batched_content]} {
                        ns_log Debug "NOTIF-BATCHED: content to send!"
                        db_transaction {
                            ns_log Debug "NOTIF-BATCHED: sending content"
                            # System name is used in the subject
                            set system_name [ad_system_name]
                            notification::delivery::send \
                                    -to_user_id $prev_user_id \
                                    -notification_type_id $prev_type_id \
                                    -subject "[_ notifications.lt_system_name_-_Batched]" \
                                    -content $batched_content \
                                    -delivery_method_id $prev_deliv_method_id
                            
                            ns_log Debug "NOTIF-BATCHED: marking notifications"
                            foreach not_id $list_of_notification_ids {
                                # Mark it as sent
                                notification::mark_sent \
                                        -notification_id $not_id \
                                        -user_id $prev_user_id
                            }         
                        }

                        # Reset things
                        set list_of_notification_ids [list]
                        set batched_content ""
                    } else {
                        ns_log Debug "NOTIF-BATCHED: NO content to send!"
                    }
                }

                if {$notif == "STOP"} {
                    continue
                }
                

                # append content to built-up content
                ns_log Debug "NOTIF-BATCHED: appending one notif!"
                append batched_content "[_ notifications.SUBJECT] [ns_set get $notif notif_subject]\n[ns_set get $notif notif_text]\n\n\n=====================\n\n\n"
                lappend list_of_notification_ids [ns_set get $notif notification_id]

                # Set the vars
                set prev_user_id $user_id
                set prev_type_id $type_id
                set prev_deliv_method_id [ns_set get $notif delivery_method_id]
            }
            
        } else {
            # Unbatched
            foreach notif $notifications {
                db_transaction {
                    # Send it
                    notification::delivery::send \
                        -from_user_id [ns_set get $notif notif_user] \
                        -to_user_id [ns_set get $notif user_id] \
                        -notification_type_id [ns_set get $notif type_id] \
                        -subject [ns_set get $notif notif_subject] \
                        -content [ns_set get $notif notif_text] \
                        -reply_object_id [ns_set get $notif response_id] \
                        -delivery_method_id [ns_set get $notif delivery_method_id]
                    
                    # Markt it as sent
                    notification::mark_sent \
                            -notification_id [ns_set get $notif notification_id] \
                            -user_id [ns_set get $notif user_id]
                }
            }
        } 
    }

}
