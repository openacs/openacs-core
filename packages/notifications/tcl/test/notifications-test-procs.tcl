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
        }
    }
