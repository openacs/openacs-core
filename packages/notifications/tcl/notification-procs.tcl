ad_library {

    Notifications

    Core procs for managing notifications. Important concepts:
    <ul>
    <li> notification: a single message that needs to be sent to users. 
    <li> intervals: the duration of time between notifications. Ranges from "instantaneous" to "weekly".
    <li> delivery method: the means by which a notification is delivered. "email" is the obvious one, but "sms" might be another.
    <li> notification type: a category of notifications, like forum_notification for forum postings, or forum_statistics for regular updates on forum statistics (this latest one is for illustration purposes only and doesn't currently exist in the forums package).
    </ul>

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification {

    ad_proc -public package_key {} {
	The package key
    } {
        return "notifications"
    }

    ad_proc -public get_interval_id {
        {-name:required}
    } {
	obtain the interval ID for an interval with the given name.
	Interval names are unique, but are not the primary key.
    } {
        return [db_string select_interval_id {} -default ""]
    }

    ad_proc -public get_delivery_method_id {
        {-name:required}
    } {
	obtain the delivery method ID with the given name.
	Delivery method names are unique, but are not the primary key.
    } {
        return [db_string select_delivery_method_id {} -default ""]
    }

    ad_proc -public get_all_intervals {} {
	return a list of all available intervals in a list of lists format,
	with the following fields: name, interval_id, n_seconds.
    } {
        return [db_list_of_lists select_all_intervals {}]
    }
    
    ad_proc -public get_intervals {
        {-localized:boolean}
        {-type_id:required}
    } {
        return a list of intervals that are associated with a given notification type
        (not all intervals are available to all notification types).
        The fields for each interval is: name, interval_id, n_seconds.
        If the localized flag is set, then the name of the interval will be localized.
    } {
        set intervals [db_list_of_lists select_intervals {}]
        if { $localized_p } {
            # build pretty names for intervals
            set intervals_pretty [list]
            foreach elm $intervals {
                set elm_name [lindex $elm 0]
                set elm_id [lindex $elm 1]
                lappend intervals_pretty [list [_ notifications.${elm_name}] $elm_id]
            }
            return $intervals_pretty
        } else {
            return $intervals
        }
    }

    ad_proc -public get_delivery_methods {
        {-type_id:required}
    } {
	return a list of delivery methods associated with a given notification type
	(not all delivery methods are available to all notification types).
	The fields are: pretty_name, delivery_method_id
    } {
        return [db_list_of_lists select_delivery_methods {}]
    }

    ad_proc -public new {
        {-notification_id ""}
        {-type_id:required}
        {-object_id:required}
        {-response_id ""}
        {-notif_subject ""}
        {-notif_text ""}
        {-notif_html ""}
        {-subset {}}
        {-already_notified {}}
        {-action_id {}}
        {-force:boolean}
        {-default_request_data {}}
        {-return_notified:boolean}
        {-notif_user {}}
	{-notif_date {}}
        {-file_ids {}}
    } {
        Create a new notification if any notification requests exist for the object and type.
        
        <p>

        The normal function is to send one notification per notification_request that match this notification.
        However, by supplying one or more of the parameters below, it's possible to notify only a subset of 
        those people who have requested notification.

        <p>
        
        This is useful in two situations. One is when you have multiple notification types that cover the 
        same event, for example notification for an entire forum, and for a single thread within that forum.
        In this situation, you typically want people to receive only one notification per event (per delivery 
        method and interval). The 'already_notified' and 'return_notified' switches help you do this.

        <p>

        Another situation is when your relevant audience really depends on something dynamic in your application, 
        such as who's assigned to a certain action in a workflow, or if you want to offer a 'notify me of all activity 
        in all forum threads that I've posted to'. In this case, the notification type would be 'my_threads' or similar.
        But when you notify, you only want to notify the users who've requested this notification, and who have posted
        to this thread. Thus, you'll need to pass in a list of user_id's of the users who posted to the current thread
        in the 'subset' parameter, and only those who have both a request and are in the subset list will get notified.

        <p>
        
        A variation on this is when you want people to get notified, even if they didn't request notification. This is 
        what the -force flag does, it causes all users in the subset to get notified, whether or not they have a
        notification request.

        <p>
        
        In this case, the request will use the interval, delivery method, and format as specified in the 
        'default_request_data' parameter. If such a parameter is not specified, default values of 'instant', 
        'email', and 'text' will be used. The value to 'default_request_data' should be an array list with entries 
        interval_id, delivery_method_id, and format.
        
        <p>

        In any situation where you're doing dynamic notifications, you must supply the ID of an ACS object which is
        specific to the underlying event in the 'action_id' parameter. This is required for the interal functioning of 
        dynamic recipient groups. Typically this would be the ID of a forums posting, a workflow log entry, or a 
        web log entry.

        <p>

        @param already_notified A list of 'user_id interval_id delivery_method_id' of users 
        already notified of this action. This is used in conjunction with the 'return_notification' 
        boolean flag, which causes this proc to return a similar list of users notified by this call.
        This is used to ensure that a user is never notified twice in the same way for the same action,
        which could otherwise happen if you have, for example, notification requests for both an entire 
        forum and a particular thread.

        @param return_notified. Set this flag if you want the proc to return a list of users notified 
        by this call. The output can then be fed to the next call to this proc. Don't set this flag if you 
        don't intend to use the result, as it requires an extra query to get.

        @param subset A list of user_id's of a subset of users who should be notified. Only those who have a 
        notification request for this object, and who are in the subset list will get notified. Unless you specifiy the 
        -force flag, in which case everybody in the subset list will get notified, whether they requested the notification
        or not. In this case, the 'default_request_data' will be used for these new requests.

        @param force See the 'subset' parameter.

        @param default_request_data An array list with entries interval_id, delivery_method_id, and format, used to initialize
        new requests caused by the combination of the 'subset' and the 'force' parameters.

        @param action_id If you're supplying either the 'subset' or the 'already_notified' parameter, you 
        must also supply the action_id parameter. The action_id parameter should be the object ID of an ACS Object,
        and should be specific to the underlying event.

        @author Ben Adida
        @author Lars Pind
    } {

        set requests_p [notification::request::request_exists -object_id $object_id -type_id $type_id]
        
        # We're only going to do anything if there are people who have requests, 
        # or if we have a non-empty subset and a force flag.
        
        set subset_arg_p [expr {[llength $subset] > 0}]
        set already_notified_arg_p [expr {[llength $already_notified] > 0}]

        if { ($subset_arg_p || $already_notified_arg_p) && $action_id eq "" } {
            error "You must supply an action_id if you have a subset or already_notified list"
        }

        # This will store the list of user_id,interval_id,delivery_method_id of notifications sent
        set notified_list {}

        if { $requests_p || ($subset_arg_p && $force_p) } {
            if { $subset_arg_p || $already_notified_arg_p } {
                # This is going to be a non-standard notification with a dynamic group of recipients
                
                # Variables:
                #
                # default_request_data: default request, if the -force switch makes us sign people up automatically
                #                       array get list of interval_id, delivery_method_id, format
                # 
                # default_request:      same, but as an array
                #
                # request:              array, keyed by (user_id interval_id delivery_method_id) which holds
                #                       the dynamic requests which we'll need to create
                #
                # already_notified:     list of "user_id interval_id delivery_method_id" of people already notified
                #                       who shouldn't be notified again
                #
                # already_notified_p:   Above as an array for quick lookup, so we don't have to do a sequential scan
                #                       on the list above to find out if a given (user_id interval_id delivery_method_id)
                #                       has already been notified
                #

                if { $default_request_data eq "" } {
                    set default_request_data [list \
                            interval_id [get_interval_id -name "instant"] \
                            delivery_method_id [get_delivery_method_id -name "email"] \
                            format "text"]
                }
                array set default_request $default_request_data

                array set request [list]

                # Start with the existing requests for the original object_id
                db_foreach select_notification_requests {} -column_array row {
                    set "request(${row(user_id)} ${row(interval_id)} ${row(delivery_method_id)})" $row(format)
                }

                # Restructure already_notified as an array for quick lookups
                foreach entry $already_notified {
                    set already_notified_p($entry) 1
                }

                if { $subset_arg_p } {

                    # Restructure subset as an array for quick lookups
                    foreach user_id $subset {
                        set subset_member_p($user_id) 1
                    }

                    # Delete request that shouldn't be there
                    foreach entry [array names request] {
                        # if not in subset, delete
                        # if in already_notified, delete

                        set user_id [lindex $entry 0]
                        
                        if { ![info exists subset_member_p($user_id)] || [info exists already_notified_p($entry)] } {
                            array unset request $entry
                        }
                    }
                    
                    if { $force_p } {
                        # Add requests that should be forced
                        foreach user_id $subset {
                            if { [llength [array get request "$user_id,*"]] == 0 } {
                                set entry "$user_id $default_request(interval_id) $default_request(delivery_method_id)"
                                set request($entry) $default_request(format)
                            }
                        }
                    }
                } else { 
                    # Get rid of users who are on the already notified list
                    foreach entry $already_notified {
                        # If user has already received a notification with the same 
                        # interval and delivery method, don't send again
                        if { [info exists request($entry)] } {
                            array unset request $entry
                        }
                    }
                }

                if { $return_notified_p } {
                    set notified_list [array names request]
                }
            } else {
                # Normal notification
                if { $return_notified_p } {
                    set notified_list [db_list_of_lists select_notified {}]
                }
            }
            
            if { $notif_user eq "" && [ad_conn isconnected] } {
                set notif_user [ad_conn user_id]
            }
           
            # Actually carry out inserting the notification
            db_transaction {
                if { $subset_arg_p || $already_notified_arg_p } {
                    foreach entry [array names request] {

                        set user_id [lindex $entry 0]
                        set interval_id [lindex $entry 1]
                        set delivery_method_id [lindex $entry 2]
                        set format $request($entry)

                        notification::request::new \
                                -type_id $type_id \
                                -user_id $user_id \
                                -object_id $action_id \
                                -interval_id $interval_id \
                                -delivery_method_id $delivery_method_id \
                                -format $format \
                                -dynamic_p "t"
                    }
                }

                # The notification below should be for the action_id object, not for the default object_id
                if { $subset_arg_p || $already_notified_arg_p } {
                  set object_id $action_id
                }

                # Truncate notif_subject to the max len of 100
                set notif_subject [string_truncate -len 100 -- $notif_subject]

                # Set up the vars
                set extra_vars [ns_set create]
                oacs_util::vars_to_ns_set \
                    -ns_set $extra_vars \
                    -var_list {notification_id type_id object_id response_id notif_subject notif_text notif_html notif_user file_ids}

                if { $notif_date ne "" } {
                    oacs_util::vars_to_ns_set \
                        -ns_set $extra_vars \
                        -var_list {notif_date}
                }
                
                # Create the notification
                package_instantiate_object -extra_vars $extra_vars notification

                # teadams@alum.mit.edu - pl/sql has a 32K limit for paramaters.

                # Updating the clob columns directly
                # to avoid this limitation.
                db_dml update_message {} -clobs [list $notif_html $notif_text]

            }
        }
        
        # This var will only be set if we were asked to return the list of user_ids notified
        return $notified_list
    }

    ad_proc -public delete {
        {-notification_id:required}
    } {
        delete a notification
    } {
        db_transaction {
            # Remove the mappings
            db_dml delete_mappings {}

            # do the delete
            db_exec_plsql delete_notification {}
        }
    }
    
    ad_proc -public mark_sent {
        {-notification_id:required}
        {-user_id:required}
    } {
        mark that a user has been sent a notification
    } {
        # Do the insert
        db_dml insert_notification_user_map {}
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
