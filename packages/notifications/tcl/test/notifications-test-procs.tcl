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
        notification::package_key
        acs_sc::impl::new_from_spec
        notification::type::new
        notification::type::get
        notification::type::get_type_id
        notification::type::get_impl_key
        notification::type::delivery_method_enable
        notification::type::delivery_method_disable
        notification::type::interval_enable
        notification::type::interval_disable
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
        notification::mark_sent
        notification::get_delivery_methods
        notification::get_all_intervals
        notification::get_intervals
        notification::delete
        notification::email::get_package_id
        notification::delivery::get_id
        notification::interval::get_id_from_name
    } \
    notification_api_tests {
        Tests various API in the package
    } {
        aa_section "We start with the easy stuff..."

        aa_equals "This API returns a constant..." \
            [notification::package_key] notifications

        aa_equals "This API return the package id of the notifications instance" \
            [notification::email::get_package_id] \
            [apm_package_id_from_key notifications]

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

            set api_type_id [notification::type::get_type_id -short_name $short_name]
            aa_equals "id from API is the same as that from creation" $api_type_id $type_id

            set impl_key [notification::type::get_impl_key -type_id $type_id]
            aa_equals "Implementation key retrieval works as expected" \
                "notifications_test_notif_type" $impl_key

            aa_log "Fetching the new type"
            notification::type::get -short_name $short_name \
                -column_array notif
            foreach {key value} [array get notif] {
                aa_equals "'$key' is correct" [set $key] $notif($key)
            }

            aa_equals "No delivery methods have been assigned to the new type" \
                0 [llength [notification::get_delivery_methods -type_id $type_id]]
            aa_equals "No intervals have been assigned to the new type" \
                0 [llength [notification::get_intervals -type_id $type_id]]

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

            aa_section "Some fun with the delivery methods API"

            set all_delivery_methods [db_list_of_lists q {
                select delivery_method_id, short_name
                from notification_delivery_methods
            }]
            set delivery_methods [notification::get_delivery_methods -type_id $type_id]

            aa_equals "All delivery methods have been assigned to the new type" \
                [llength $all_delivery_methods] [llength $delivery_methods]

            foreach m $all_delivery_methods {
                lassign $m id name
                aa_equals "Lookup delivery method '$name' returns the right id" \
                    [notification::delivery::get_id -short_name $name] $id
            }

            set one_delivery_method_id [lindex $delivery_methods 0 1]
            aa_log "Disabling delivery method '$one_delivery_method_id' for type '$type_id'"
            notification::type::delivery_method_disable -type_id $type_id -delivery_method_id $one_delivery_method_id
            aa_equals "Delivery methods are one less for the type" \
                [llength [notification::get_delivery_methods -type_id $type_id]] [expr {[llength $delivery_methods] - 1}]
            aa_log "Enabling delivery method '$one_delivery_method_id' for type '$type_id' again"
            notification::type::delivery_method_enable -type_id $type_id -delivery_method_id $one_delivery_method_id
            aa_equals "Delivery methods are back as before" \
                [lsort $delivery_methods] [lsort [notification::get_delivery_methods -type_id $type_id]]

            aa_section "Some fun with the intervals API"

            set all_intervals [notification::get_all_intervals]
            set intervals [notification::get_intervals -localized -type_id $type_id]
            aa_equals "All intervals have been assigned to the new type" \
                [llength $all_intervals] [llength $intervals]

            foreach i $all_intervals {
                lassign $i name id seconds
                aa_true "Seconds '$seconds' is an integer" [string is integer -strict $seconds]
                aa_equals "Lookup interval '$name' returns the right id" \
                    [notification::interval::get_id_from_name -name $name] $id
            }

            set one_interval_id [lindex $intervals 0 1]
            aa_log "Disabling interval '$one_interval_id' for type '$type_id'"
            notification::type::interval_disable -type_id $type_id -interval_id $one_interval_id
            aa_equals "Intervals are one less for the type" \
                [llength [notification::get_intervals -type_id $type_id]] [expr {[llength $intervals] - 1}]
            aa_log "Enabling interval '$one_interval_id' for type '$type_id' again"
            notification::type::interval_enable -type_id $type_id -interval_id $one_interval_id
            aa_equals "Intervals are back as before" \
                [lsort $intervals] [lsort [notification::get_intervals -type_id $type_id]]

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
            set delivery_method_id $one_delivery_method_id
            set interval_id $one_interval_id

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

            aa_log "Mark the notification on object '$object_id' to user '$user_id' as sent"
            notification::mark_sent \
                -notification_id $notification_id \
                -user_id $user_id
            aa_true "Notification was marked as expected" [db_0or1row q {
                select 1 from notification_user_map
                where notification_id = :notification_id
                and user_id = :user_id
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

aa_register_case \
    -cats {api smoke} \
    -procs {
        notification::delivery::new
        notification::delivery::delete
        notification::delivery::get_id
        notification::get_delivery_methods
    } \
    notification_delivery_tests {
        Tests delivery API
    } {
        aa_run_with_teardown -rollback -test_code {
            db_1row q {
                select delivery_method_id,
                       sc_impl_id,
                       short_name,
                       pretty_name
                from notification_delivery_methods
                fetch first 1 rows only
            }

            aa_false "Trying to lookup the deleted delivery method succeeds" [catch {
                notification::delivery::get_id -short_name $short_name
            } errmsg]

            aa_log "Deleting method '$short_name'"
            notification::delivery::delete -delivery_method_id $delivery_method_id

            aa_true "Trying to lookup the deleted delivery method fails" [catch {
                notification::delivery::get_id -short_name $short_name
            } errmsg]

            aa_log "Recreating the delivery method as a new object"
            set new_delivery_method_id [notification::delivery::new \
                                            -sc_impl_id $sc_impl_id \
                                            -short_name $short_name \
                                            -pretty_name $pretty_name]

            aa_true "The delivery method was recreated as expected " [db_0or1row q {
                select 1
                from notification_delivery_methods
                where delivery_method_id = :new_delivery_method_id
                  and sc_impl_id = :sc_impl_id
                  and short_name = :short_name
                  and pretty_name = :pretty_name
            }]

            aa_log "Deleting method '$short_name' again"
            notification::delivery::delete -delivery_method_id $new_delivery_method_id

            aa_log "Recreating the delivery method with the old id"
            notification::delivery::new \
                -delivery_method_id $delivery_method_id \
                -sc_impl_id $sc_impl_id \
                -short_name $short_name \
                -pretty_name $pretty_name

            aa_true "The delivery method was recreated as expected " [db_0or1row q {
                select 1
                from notification_delivery_methods
                where delivery_method_id = :delivery_method_id
                  and sc_impl_id = :sc_impl_id
                  and short_name = :short_name
                  and pretty_name = :pretty_name
            }]
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        acs_sc::impl::new_from_spec
        notification::type::new
        notification::request::new
        notification::request::delete
        notification::display::subscribe_url
        notification::display::unsubscribe_url
        notification::display::get_urls
        notification::display::request_widget
        notification::get_intervals
        notification::get_delivery_methods
        util::external_url_p
    } \
    notification_display_tests {
        Tests display API
    } {
        aa_run_with_teardown -rollback -test_code {

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
                             -description $description \
                             -all_intervals \
                             -all_delivery_methods]

            set object_id [db_string q {select object_id from acs_objects fetch first 1 rows only}]
            set user_id [db_string q {select user_id from users fetch first 1 rows only}]
            set return_url my-test-url

            aa_log "Generate subscribe URL"
            set subscribe_url [notification::display::subscribe_url \
                                   -type $short_name \
                                   -object_id $object_id \
                                   -url $return_url \
                                   -user_id $user_id \
                                   -pretty_name $pretty_name]
            aa_false "Returned URL is our own" [util::external_url_p $subscribe_url]
            foreach p {type_id user_id object_id pretty_name return_url} {
                aa_true "Returned URL contains the expected information $p" \
                    [string match *[ns_urlencode [set p]]* $subscribe_url]
            }

            set delivery_methods [notification::get_delivery_methods -type_id $type_id]
            set intervals [notification::get_intervals -localized -type_id $type_id]
            set one_delivery_method_id [lindex $delivery_methods 0 1]
            set one_interval_id [lindex $intervals 0 1]

            aa_log "Create a subscription"
            set request_id [notification::request::new \
                                -type_id $type_id \
                                -user_id $user_id \
                                -object_id $object_id \
                                -interval_id $one_interval_id \
                                -delivery_method_id $one_delivery_method_id]

            aa_log "Generate the unsubscribe URL"
            set unsubscribe_url [notification::display::unsubscribe_url \
                                     -request_id $request_id -url $return_url]
            aa_false "Returned URL is our own" [util::external_url_p $subscribe_url]
            foreach p {request_id return_url} {
                aa_true "Returned URL contains the expected information $p" \
                    [string match *[ns_urlencode [set p]]* $unsubscribe_url]
            }

            set root_path [apm_package_url_from_key [notification::package_key]]

            aa_log "Generate the subscription URL we expect from notification::display::subscribe_url"
            set subscribe_url_api [notification::display::subscribe_url \
                                   -type $short_name \
                                   -object_id $object_id \
                                   -url $return_url \
                                   -user_id $user_id \
                                   -pretty_name $pretty_name]
            aa_equals "The API returns the expected subscription URL"\
                $subscribe_url_api [export_vars -base "${root_path}request-new" {
                    type_id user_id object_id pretty_name return_url
                }]


            aa_log "Generate the subscription URL we expect from notification::display::get_urls"
            set subscribe_url [export_vars -base "${root_path}request-new" {
                type_id object_id pretty_name return_url
            }]

            aa_log "Generate the two URLs"
            set urls [notification::display::get_urls \
                          -type $short_name \
                          -object_id $object_id \
                          -return_url $return_url \
                          -pretty_name $pretty_name \
                          -user_id $user_id]
            aa_equals "Subscribe URL is empty because user '$user_id' has subscribed" \
                "" [lindex $urls 0]
            aa_equals "Unsubscribe URL is correct" \
                $unsubscribe_url [lindex $urls 1]

            aa_log "Generate the request widget"
            set widget [notification::display::request_widget \
                            -type $short_name \
                            -object_id $object_id \
                            -pretty_name $pretty_name \
                            -url $return_url \
                            -user_id $user_id]
            aa_true "The widget is HTML" [ad_looks_like_html_p $widget]
            aa_false "Widget does not contain the subscribe URL" \
                [string match *[ns_quotehtml $subscribe_url_api]* $widget]
            aa_true "Widget contains the unsubscribe URL" \
                [string match *[ns_quotehtml $unsubscribe_url]* $widget]

            aa_log "Unsubscribe user '$user_id'"
            notification::request::delete -request_id $request_id

            aa_log "Generate the two URLs again"
            set urls [notification::display::get_urls \
                          -type $short_name \
                          -object_id $object_id \
                          -return_url $return_url \
                          -pretty_name $pretty_name \
                          -user_id $user_id]
            aa_equals "Unsubscribe URL is empty because user '$user_id' has not subscribed" \
                "" [lindex $urls 1]
            aa_equals "Subscribe URL is correct" \
                $subscribe_url [lindex $urls 0]

            aa_log "Generate the request widget again"
            set widget [notification::display::request_widget \
                            -type $short_name \
                            -object_id $object_id \
                            -pretty_name $pretty_name \
                            -url $return_url \
                            -user_id $user_id]
            aa_true "The widget is HTML" [ad_looks_like_html_p $widget]
            aa_true "Widget contains the subscribe URL" \
                [string match *[ns_quotehtml $subscribe_url_api]* $widget]
            aa_false "Widget does not contain the unsubscribe URL" \
                [string match *[ns_quotehtml $unsubscribe_url]* $widget]
        }
    }
