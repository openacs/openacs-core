ad_library {
    Tests for the notifications API
}

namespace eval notification {}
namespace eval notification::test {}

ad_proc -private notification::test::notification__get_url {
    object_id
} {
    Example of a callback retrieving the URL from an object_id
} {
    return /o/$object_id
}

ad_proc -private notification::test::notification__process_reply {
    reply_id
} {
    Example of a callback to process the reply to a notification.
} {
    ns_log notice "Reply $reply_id processed"
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        acs_sc::impl::new_from_spec
        notification::type::new
        notification::type::delete
        notification::request::new
        notification::request::delete
        notification::request::get_request_id
        notification::request::delete_all
        notification::request::delete_all_for_user
        notification::request::request_exists
        notification::request::request_count
        notification::request::request_ids
        notification::request::subscribers
        notification::new
        notification::delete
    } \
    notification_api_tests {
        Test the registration of a parameter
    } {
        aa_run_with_teardown -rollback -test_code {
            aa_section "Creating a notification type..."

            # Entire forum
            set spec {
                contract_name "NotificationType"
                owner "notifications"
                name "notifications_test_notif_type"
                pretty_name "Notifications Test Notification Type"
                aliases {
                    GetURL {
                        alias notification::test::notification__get_url
                        language TCL
                    }
                    ProcessReply {
                        alias notification::test::notification__process_reply
                        language TCL
                    }
                }
            }
            set sc_impl_id [acs_sc::impl::new_from_spec -spec $spec]

            set short_name "notifications_test_notif"
            set pretty_name "Test Notifications"
            set description "These dummy notification type is created during automated tests."

            set type_id [notification::type::new \
                             -sc_impl_id $sc_impl_id \
                             -short_name $short_name \
                             -pretty_name $pretty_name \
                             -description $description]

            aa_equals "Short name is correct" \
                $short_name [db_string q {select short_name from notification_types where type_id = :type_id}]
            aa_equals "Description is correct" \
                $description [db_string q {select description from notification_types where type_id = :type_id}]
            aa_equals "Service Contract Implementation id is correct" \
                $sc_impl_id [db_string q {select sc_impl_id from notification_types where type_id = :type_id}]

            aa_equals "No delivery methods have been assigned to the new type" \
                0 [db_string q {select count(*) from notification_types_del_methods where type_id = :type_id}]
            aa_equals "No intervals have been assigned to the new type" \
                0 [db_string q {select count(*) from notification_types_intervals where type_id = :type_id}]

            aa_log "Deleleting notification type '$short_name'"
            notification::type::delete -short_name $short_name

            aa_false "Notification type is no more" \
                [db_0or1row q {select 1 from notification_types where type_id = :type_id}]

            set pretty_name "Test Notifications 2"
            set description "These dummy notification type is created during automated tests. 2"

            notification::type::new \
                -type_id $type_id \
                -sc_impl_id $sc_impl_id \
                -short_name $short_name \
                -pretty_name $pretty_name \
                -description $description \
                -all_intervals \
                -all_delivery_methods

            aa_true "All delivery methods have been assigned to the new type" \
                [db_0or1row q {select 1 from dual where
                    (select count(*) from notification_delivery_methods)
                    =
                    (select count(*) from notification_types_del_methods where type_id = :type_id)
                }]

            aa_true "All intervals have been assigned to the new type" \
                [db_0or1row q {select 1 from dual where
                    (select count(*) from notification_intervals)
                    =
                    (select count(*) from notification_types_intervals where type_id = :type_id)
                }]

            aa_section "Creating a notification with no subscriptions..."

            set object_id [db_string q {select object_id from acs_objects fetch first 1 rows only}]
            set user_id [db_string q {select user_id from users fetch first 1 rows only}]

            set object_id_2 [db_string q {select object_id from acs_objects where object_id <> :object_id fetch first 1 rows only}]
            set user_id_2 [db_string q {select user_id from users where user_id <> :user_id fetch first 1 rows only}]

            aa_false "There are no subscriptions for object_id '$object_id' and type_id '$type_id'" {
                [notification::request::request_exists -object_id $object_id -type_id $type_id] ||
                [notification::request::request_count -object_id $object_id -type_id $type_id] ||
                [llength [notification::request::request_ids -object_id $object_id -type_id $type_id]] ||
                [llength [notification::request::subscribers -object_id $object_id -type_id $type_id]]
            }

            notification::new  \
                -type_id $type_id -object_id $object_id
            aa_false "Without somebody subscribing, notifications are not created" \
                [db_0or1row q {select 1 from notifications where type_id = :type_id}]

            aa_section "Generating some subscriptions..."
            set delivery_method_id [db_string q {
                select delivery_method_id
                from notification_types_del_methods
                where type_id = :type_id
                fetch first 1 rows only
            }]
            set interval_id [db_string q {
                select interval_id
                from notification_types_intervals
                where type_id = :type_id
                fetch first 1 rows only
            }]

            aa_log "Creating a subscription for user_id '$user_id' on object_id '$object_id' and type_id '$type_id'"
            set request_id [notification::request::new \
                                -type_id $type_id \
                                -user_id $user_id \
                                -object_id $object_id \
                                -interval_id $interval_id \
                                -delivery_method_id $delivery_method_id]

            set old_request_id $request_id

            set request_id [notification::request::new \
                                -type_id $type_id \
                                -user_id $user_id \
                                -object_id $object_id \
                                -interval_id $interval_id \
                                -delivery_method_id $delivery_method_id]

            aa_equals "A subscription is unique per user, object and notification type" \
                $old_request_id $request_id

            set request_ids [list $request_id]

            aa_log "Subscribe user '$user_id_2' to object '$object_id'"
            lappend request_ids [notification::request::new \
                                     -type_id $type_id \
                                     -user_id $user_id_2 \
                                     -object_id $object_id \
                                     -interval_id $interval_id \
                                     -delivery_method_id $delivery_method_id]

            aa_log "Subscribe user '$user_id' to object '$object_id_2'"
            notification::request::new \
                -type_id $type_id \
                -user_id $user_id \
                -object_id $object_id_2 \
                -interval_id $interval_id \
                -delivery_method_id $delivery_method_id

            aa_log "Subscribe user '$user_id_2' to object '$object_id_2'"
            notification::request::new \
                -type_id $type_id \
                -user_id $user_id_2 \
                -object_id $object_id_2 \
                -interval_id $interval_id \
                -delivery_method_id $delivery_method_id

            aa_true "Subscription exists for object_id '$object_id' and type_id '$type_id'" \
                [notification::request::request_exists -object_id $object_id -type_id $type_id]
            aa_true "2 subscriptions exists for object_id '$object_id' and type_id '$type_id'" \
                {[notification::request::request_count -object_id $object_id -type_id $type_id] == 2}
            aa_equals "Subscriptions for object_id '$object_id' and type_id '$type_id' are the ones we created" \
                [lsort [notification::request::request_ids -object_id $object_id -type_id $type_id]] [lsort $request_ids]
            aa_equals "Subscribers for object_id '$object_id' and type_id '$type_id' are the users we picked" \
                [lsort [notification::request::subscribers -object_id $object_id -type_id $type_id]] [lsort [list $user_id $user_id_2]]

            aa_section "Send a notification with some subscribers..."
            notification::new  \
                -type_id $type_id -object_id $object_id

            aa_true "An entry was created this time" \
                [db_0or1row q {
                    select notification_id from notifications
                    where type_id = :type_id and object_id = :object_id
                }]

            aa_log "Deleting the new notification '$notification_id'"
            notification::delete -notification_id $notification_id

            aa_false "Notification is no more" \
                [db_0or1row q {select 1 from notifications where notification_id = :notification_id}]

            aa_log "Delete all subscriptions for object '$object_id'"
            notification::request::delete_all -object_id $object_id
            aa_false "There are no subscriptions for object_id '$object_id' and type_id '$type_id'" {
                [notification::request::request_exists -object_id $object_id -type_id $type_id] ||
                [notification::request::request_count -object_id $object_id -type_id $type_id] ||
                [llength [notification::request::request_ids -object_id $object_id -type_id $type_id]] ||
                [llength [notification::request::subscribers -object_id $object_id -type_id $type_id]]
            }

            set request_id [notification::request::get_request_id \
                                -type_id $type_id \
                                -object_id $object_id_2 \
                                -user_id $user_id_2]
            aa_false "We found the subscription for object $object_id_2 by user $user_id_2" \
                {$request_id eq ""}

            aa_log "Delete all subscriptions for user '$user_id_2'"
            notification::request::delete_all_for_user -user_id $user_id_2

            set request_id [notification::request::get_request_id \
                                -type_id $type_id \
                                -object_id $object_id_2 \
                                -user_id $user_id_2]
            aa_true "Subscription for object $object_id_2 by user $user_id_2 is no more" \
                {$request_id eq ""}

            set remaining_requests [notification::request::request_ids \
                                        -object_id $object_id_2 \
                                        -type_id $type_id]
            aa_equals "There is still 1 leftover request" \
                1 [llength $remaining_requests]

            aa_log "Delete last request"
            notification::request::delete -request_id [lindex $remaining_requests 0]
            aa_false "No requests anymore" \
                [db_0or1row q {select 1 from notification_requests where request_id = :request_id}]

        }
    }
