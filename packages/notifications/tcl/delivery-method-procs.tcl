ad_library {

    Notification Delivery Methods
    
    Functions to support notification delivery methods. A delivery method is a means by which
    a notification is sent to a user. "Email" is a common one, but others, like "sms", may exist.

    The delivery method integration is done via acs-service-contract: any new delivery method must implement
    this service contract.

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::delivery {}


ad_proc -private notification::delivery::get_impl_key {
    {-delivery_method_id:required}
} {
    Return the service contract implementation key for notification delivery methods
} {
    return [db_string select_impl_key {}]
}

ad_proc -public notification::delivery::send {
    {-delivery_method_id:required}
    {-reply_object_id ""}
    {-notification_type_id:required}
    {-from_user_id ""}
    {-to_user_id:required}
    {-subject:required}
    {-content_text:required}
    {-content_html:required}
    {-file_ids ""}
} {
    do the delivery of certain content to a particular user using a particular delivery method.
    This is just a wrapper proc that sets up the call to the service contract implementation for
    a given delivery method.
} {
    #need to check if its ok to notify this user in this way.  For now just checks if they are an approved user.
    if { ![notification::security::can_notify_user -user_id $to_user_id -delivery_method_id $delivery_method_id] } {
        ns_log debug "notification::delivery::send: Blocked notification to $to_user_id subject:$subject"
        return "Blocked"
    }

    # Get the implementation key
    set impl_key [get_impl_key -delivery_method_id $delivery_method_id]

    # Prepare the arguments
    set args [list $from_user_id $to_user_id $reply_object_id $notification_type_id $subject $content_text $content_html $file_ids]

    # Make the generic call
    return [acs_sc_call NotificationDeliveryMethod Send $args $impl_key]
}

ad_proc -public notification::delivery::scan_replies {
    {-delivery_method_id:required}
} {
    scan for replies.
    
    Every delivery method allows for replies. This is the wrapper proc that
    indicates to the delivery method service contract implementation that it's time to
    scan for replies.
} {
    # Get the implementation key
    set impl_key [get_impl_key -delivery_method_id $delivery_method_id]

    # Prepare the arguments
    set args [list]

    # ns_log Notice "NOTIF-DELIV-METHOD: about to call acs_sc on $impl_key"

    # Make the generic call
    return [acs_sc_call NotificationDeliveryMethod ScanReplies $args $impl_key]
}

ad_proc -public notification::delivery::new {
    {-delivery_method_id ""}
    {-sc_impl_id:required}
    {-short_name:required}
    {-pretty_name:required}
} {
    Register a new delivery method with the notification service.
} {
    set extra_vars [ns_set create]

    oacs_util::vars_to_ns_set \
        -ns_set $extra_vars \
        -var_list {delivery_method_id sc_impl_id short_name pretty_name}
    
    return [package_instantiate_object \
                -extra_vars $extra_vars \
                "notification_delivery_method"]
}

ad_proc -public notification::delivery::delete {
    {-delivery_method_id:required}
} {
    Unregister a delivery method with the notification service.
} {
    db_exec_plsql delete {}
}

ad_proc -public notification::delivery::update_sc_impl_id {
    {-delivery_method_id ""}
    {-sc_impl_id:required}
} {
    Register a new service contract implementation with an existing delivery method.
} {
    db_dml update {}
}

ad_proc -public notification::delivery::get_id {
    {-short_name:required}
} {
    Return the delivery_method_id from the short_name.
} {
    return [db_string select_delivery_method_id {}]
}

