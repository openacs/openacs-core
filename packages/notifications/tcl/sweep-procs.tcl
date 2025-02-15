ad_library {

    Notification Sweeps

    @creation-date 2002-05-27
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::sweep {

    ad_proc -private cleanup_sse_subscriptions {} {
        Cleanup unused SSE channels.
    } {
        foreach {subscription channels} [nsv_array get ::notification::sse channels-*] {
            set to_user_id [string range $subscription [string length channels-] end]
            foreach channel $channels {
                try {
                    ns_connchan write $channel [string cat {: ping} \n\n]
                } on error {errmsg} {
                    ::notification::sse::unsubscribe $channel $to_user_id
                }
            }
        }
    }

    ad_proc -private cleanup_notifications {} {
        Clean up the notifications that have been sent out (DRB: inefficiently...).
    } {
        # before the killing starts, remove invalid requests
        foreach request_id [db_list select_invalid_request_ids {
           select request_id
             from notification_requests
            where
                  -- LARS
                  -- Also sweep the dynamic notification requests that have been sent out
                  (dynamic_p = 't' and
                   exists (select 1
                           from    notifications n,
                                   notification_user_map num
                           where   n.type_id = type_id
                           and     n.object_id = object_id
                           and     num.notification_id = n.notification_id
                           and     num.user_id = user_id))

               -- or not acs_permission.permission_p(object_id, user_id, 'read')
        }] {
            notification::request::delete -request_id $request_id
        }

        # Get the list of the ones to kill
        set notification_id_list [db_list select_notification_ids {}]

        # Kill them
        foreach notification_id $notification_id_list {
            notification::delete -notification_id $notification_id
        }

    }

    ad_proc -private sweep_notifications {
        {-interval_id:required}
        {-batched_p 0}
    } {
        This sweeps for notifications in a particular interval
    } {
        #
        # Look for notifications joined against the requests they may
        # match with the right interval_id order it by user_id.  Make
        # sure the users have not yet received this notification with
        # outer join on the mapping table and a null check.
        #
        set notifications [db_list_of_ns_sets select_notifications {
           select notifications.notification_id,
                   notif_subject,
                   notif_text,
                   notif_html,
                   file_ids,
                   notification_requests.user_id,
                   request_id,
                   notifications.type_id,
                   delivery_method_id,
                   response_id,
                   notif_date,
                   notif_user,
                   acs_permission.permission_p(notification_requests.object_id, notification_requests.user_id, 'read') as still_valid_p
            from notifications
            inner join notification_requests on (notifications.type_id = notification_requests.type_id
                                                and notifications.object_id = notification_requests.object_id)
              inner join acs_objects on (notification_requests.request_id = acs_objects.object_id)
              left outer join notification_user_map on (notification_user_map.notification_id = notifications.notification_id
                                                       and notification_user_map.user_id = notification_requests.user_id)
            where sent_date is null
              and creation_date <= notif_date
              and (notif_date is null or notif_date < current_timestamp)
              and interval_id = :interval_id
            order by notification_requests.user_id, notifications.type_id, notif_date
        }]

        foreach notif $notifications {
            if {![ns_set get $notif still_valid_p]} {
                #
                # The user has lost permissions on the object, so
                # delete this notification. This deletion was done
                # before in the highly expensive query in
                # "cleanup_notifications"
                #
                ns_log notice "delete notification [ns_set get $notif request_id]" \
                    "for user_id [ns_set get $notif user_id]" \
                    "since user has lost rights on object"

                notification::request::delete \
                    -request_id [ns_set get $notif request_id]
                #
                # Remove this tuple from the notification list such we
                # do not have to double-check for this.
                #
                set idx [lsearch $notifications $notif]
                set notifications [lreplace $notifications $idx $idx]
            }
        }

        if {$batched_p} {
            set prev_user_id 0
            set prev_type_id 0
            set prev_deliv_method_id ""
            set list_of_notification_ids [list]
            set batched_content_text ""
            set batched_content_html ""
            set batched_file_ids [list]
            set summary_text "[_ notifications.Contents]/n"
            set summary_html "<h4>[_ notifications.Contents]</h4><ul>"

            # Add a stop codon
            lappend notifications STOP

            # Batched sending
            foreach notif $notifications {
                ns_log Debug "NOTIF-BATCHED: one notif $notif"

                if {$notif ne "STOP"} {
                    ns_log Debug "NOTIF-BATCHED: NOT a stop codon"
                    set user_id [ns_set get $notif user_id]
                    set type_id [ns_set get $notif type_id]
                } else {
                    ns_log Debug "NOTIF-BATCHED stop codon!"
                    set user_id ""
                    set type_id ""
                }
                #
                # Check if we have a new user_id and type_id. If so,
                # batch up previous stuff and send it.
                #
                if {$notif eq "STOP" || $user_id != $prev_user_id || $type_id != $prev_type_id} {

                    ns_log Debug "NOTIF-BATCHED: batching things up for $prev_user_id"

                    # If no content, keep going
                    if {$batched_content_text ne ""} {
                        ns_log Debug "NOTIF-BATCHED: content to send!"
                        db_transaction {
                            ns_log Debug "NOTIF-BATCHED: sending content"
                            # System name is used in the subject
                            set system_name [ad_system_name]
                            notification::delivery::send \
                                -to_user_id $prev_user_id \
                                -notification_type_id $prev_type_id \
                                -subject "[_ notifications.lt_system_name_-_Batched]" \
                                -content_text "$summary_text $batched_content_text" \
                                -content_html "$summary_html </ul><hr>$batched_content_html" \
                                -file_ids $batched_file_ids \
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
                        set batched_content_text ""
                        set batched_content_html ""
                        set batched_file_ids [list]
                        set summary_text "[_ notifications.Contents]/n"
                        set summary_html "<h4>[_ notifications.Contents]</h4><ul>"
                    } else {
                        ns_log Debug "NOTIF-BATCHED: NO content to send!"
                    }
                }

                if {$notif eq "STOP"} {
                    continue
                }


                # append content to built-up content
                ns_log Debug "NOTIF-BATCHED: appending one notif!"
                #Lets see what we have:
                set notif_text [ns_set get $notif notif_text]
                set notif_html [ns_set get $notif notif_html]

                if {$notif_text eq ""} {
                    set notif_text [ad_html_text_convert -from html -to text -- $notif_html]
                }

                if {$notif_html eq ""} {
                    set notif_html [ad_html_text_convert -from text -to html -- $notif_text]
                } else {
                    set html_content_p 1
                }

                append summary_text "[ns_set get $notif notif_subject]\n"
                append summary_html \
                    "<li><a href='#[ns_set get $notif notification_id]'>" \
                    [ns_set get $notif notif_subject] \
                    "</a></li>"
                append batched_content_text \
                    "[_ notifications.SUBJECT] [ns_set get $notif notif_subject]\n" \
                    [ns_set get $notif notif_text] \
                    "\n=====================\n"
                append batched_content_html \
                    "<a name='[ns_set get $notif notification_id]'>" \
                    "[_ notifications.SUBJECT] </a> [ns_set get $notif notif_subject]\n" \
                    " $notif_html <hr><p>"

                lappend batched_file_ids {*}[ns_set get $notif file_ids]
                lappend list_of_notification_ids [ns_set get $notif notification_id]

                # Set the vars
                set prev_user_id $user_id
                set prev_type_id $type_id
                set prev_deliv_method_id [ns_set get $notif delivery_method_id]
            }

        } else {
            #
            # Unbatched
            #
            foreach notif $notifications {
                db_transaction {
                    # Send it
                    notification::delivery::send \
                        -from_user_id [ns_set get $notif notif_user] \
                        -to_user_id [ns_set get $notif user_id] \
                        -notification_type_id [ns_set get $notif type_id] \
                        -subject [ns_set get $notif notif_subject] \
                        -content_text [ns_set get $notif notif_text] \
                        -content_html [ns_set get $notif notif_html] \
                        -file_ids [ns_set get $notif file_ids] \
                        -reply_object_id [ns_set get $notif response_id] \
                        -delivery_method_id [ns_set get $notif delivery_method_id]

                    # Mark it as sent
                    notification::mark_sent \
                        -notification_id [ns_set get $notif notification_id] \
                        -user_id [ns_set get $notif user_id]
                }
            }
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
