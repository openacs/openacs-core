ad_library {

    Notification Delivery Methods

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::delivery {

    ad_proc -private get_impl_key {
        {-delivery_method_id:required}
    } {
        return [db_string select_impl_key {}]
    }

    ad_proc -public send {
        {-delivery_method_id:required}
        {-reply_object_id ""}
        {-notification_type_id:required}
        {-to_user_id:required}
        {-subject:required}
        {-content:required}
    } {
        do the delivery of certain content to a particular user
    } {
        # Get the implementation key
        set impl_key [get_impl_key -delivery_method_id $delivery_method_id]

        # Prepare the arguments
        set args [list $to_user_id $reply_object_id $notification_type_id $subject $content]

        # Make the generic call
        return [acs_sc_call NotificationDeliveryMethod Send $args $impl_key]
    }

    ad_proc -public scan_replies {
        {-delivery_method_id:required}
    } {
        scan for replies
    } {
        # Get the implementation key
        set impl_key [get_impl_key -delivery_method_id $delivery_method_id]

        # Prepare the arguments
        set args [list $to_user_id $reply_object_id $subject $content]

        ns_log Notice "NOTIF-DELIV-METHOD: about to call acs_sc on $impl_key"

        # Make the generic call
        return [acs_sc_call NotificationDeliveryMethod ScanReplies $args $impl_key]
    }

}
