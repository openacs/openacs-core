
ad_library {
    APM callback procedures.
    
    @creation-date 2003-06-12
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval notification::apm {}

ad_proc -public notification::apm::after_install {} {
    After install callback.  Create service contracts.
} {
    db_transaction {

        # Create the delivery method service contract
        create_delivery_method_contract

        # Register email delivery method service contract implementation
        set impl_id [create_email_delivery_method_impl]

        # Register the service contract implementation with the notifications service
        register_email_delivery_method -impl_id $impl_id

        # Create the notification type service contract
        create_notification_type_contract
    }
}

ad_proc -public notification::apm::before_uninstall {} {
    Before uninstall callback.  Get rid of service contracts.
} {
    db_transaction {

        # Delete the notification type service contract
        delete_notification_type_contract

        # Delete the service contract implementation from the notifications service
        unregister_email_delivery_method

        # Unregister email delivery method service contract implementation
        delete_email_delivery_method_impl
        
        # Delete the delivery method service contract
        delete_delivery_method_contract

    }
}

ad_proc -public notification::apm::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    After upgrade callback.
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.1.0d1 5.1.0d2 {
                db_transaction {
                    
                    # Delete and recreate contract
                    delete_delivery_method_contract
                    create_delivery_method_contract

                    # The old implementation is still there, but now it's unbound

                    # Now change the name of the old implementation
                    db_dml update { update acs_sc_impls set impl_name = 'notification_email_old' where impl_name = 'notification_email' }
                    db_dml update { update acs_sc_impl_aliases set impl_name = 'notification_email_old' where impl_name = 'notification_email' }

                    # Create the new implementation
                    set impl_id [create_email_delivery_method_impl]

                    # Register the new impl ID with notification_delivery_methods
                    update_email_delivery_method_impl -impl_id $impl_id

                    # Delete the old implementation
                    delete_email_delivery_method_impl -impl_name "notification_email_old"

                }
            }
            5.4.0d2 5.4.0d3 {
                db_transaction {
                    
                    # Delete and recreate contract
                    delete_delivery_method_contract
                    create_delivery_method_contract

                    # The old implementation is still there, but now it's unbound

                    # Now change the name of the old implementation
                    db_dml update { update acs_sc_impls set impl_name = 'notification_email_old' where impl_name = 'notification_email' }
                    db_dml update { update acs_sc_impl_aliases set impl_name = 'notification_email_old' where impl_name = 'notification_email' }

                    # Create the new implementation
                    set impl_id [create_email_delivery_method_impl]

                    # Register the new impl ID with notification_delivery_methods
                    update_email_delivery_method_impl -impl_id $impl_id

                    # Delete the old implementation
                    delete_email_delivery_method_impl -impl_name "notification_email_old"

                }
            }
        }
}


ad_proc -public notification::apm::create_delivery_method_contract {} {
    Create the delivery method service contract.
} {
    acs_sc::contract::new_from_spec \
        -spec {
            name "NotificationDeliveryMethod"
            description "Notification Delivery Method"
            operations {
                Send {
                    description "Send a notification"
                    input { 
                        from_user_id:integer
                        to_user_id:integer
                        reply_object_id:integer
                        notification_type_id:integer
                        subject:string
                        content_text:string 
                        content_html:string
                        file_ids:string
                    }
                }
                ScanReplies {
                    description "Scan for replies"
                }
            }
        }
}

ad_proc -public notification::apm::delete_delivery_method_contract {} {
    Delete the delivery method contract.
} {
    acs_sc::contract::delete -name "NotificationDeliveryMethod"
}

ad_proc -public notification::apm::create_email_delivery_method_impl {} {
    Register the service contract implementation and return the impl_id
    
    @return impl_id of the created implementation
} {
    return [acs_sc::impl::new_from_spec -spec {
        contract_name "NotificationDeliveryMethod"
        name "notification_email"
        owner "notifications"
        aliases {
            Send notification::email::send
            ScanReplies notification::email::scan_replies
        }
    }]
}

ad_proc -public notification::apm::delete_email_delivery_method_impl {
    {-impl_name "notification_email"}
} {
    Unregister the NotificationDeliveryMethod service contract implementation for email.
} {
    acs_sc::impl::delete \
        -contract_name "NotificationDeliveryMethod" \
        -impl_name $impl_name
}

ad_proc -public notification::apm::register_email_delivery_method {
    -impl_id:required
} {
    Register the email delivery method with the notifications service.
    
    @param impl_id The ID of the NotificationDeliveryMethod service contract implementation.
} {
    notification::delivery::new \
        -sc_impl_id $impl_id \
        -short_name "email" \
        -pretty_name "Email"
}

ad_proc -public notification::apm::update_email_delivery_method_impl {
    -impl_id:required
} {
    Register the email delivery method with the notifications service.
    
    @param impl_id The ID of the NotificationDeliveryMethod service contract implementation.
} {
    set delivery_method_id [notification::delivery::get_id -short_name "email"]

    notification::delivery::update_sc_impl_id \
        -delivery_method_id $delivery_method_id \
        -sc_impl_id $impl_id
}

ad_proc -public notification::apm::unregister_email_delivery_method {} {
    Unregister the service contract delivery method with the notifications service.
} {
    set delivery_method_id [notification::delivery::get_id -short_name "email"]
    
    notification::delivery::delete \
        -delivery_method_id $delivery_method_id
}

ad_proc -public notification::apm::create_notification_type_contract {} {
    Create the notification type service contract, used by client packages to define notification
    types specific to the client's object types.
} {
    acs_sc::contract::new_from_spec \
        -spec {
            name "NotificationType"
            description "Notification Type"
            operations {
                GetURL {
                    description "Gets the URL for an object in this notification type"
                    input { 
                        object_id:integer
                    }
                    output {
                        url:string
                    }
                }
                ProcessReply {
                    description "Process a single reply"
                    input {
                        reply_id:integer
                    }
                    output {
                        success_p:boolean
                    }
                    
                }
            }
        }
}

ad_proc -public notification::apm::delete_notification_type_contract {} {
    Delete the notification type service contract.
} {
    acs_sc::contract::delete -name "NotificationType"
}
