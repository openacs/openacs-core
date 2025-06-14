ad_page_contract {

    Request a new notification - Ask for more stuff

    @author Ben Adida (ben@openforce.net)
    @creation-date 2002-05-24
    @cvs-id $Id$
} {
    type_id:naturalnum,notnull
    object_id:naturalnum,notnull
    {pretty_name:allhtml ""}
    return_url:localurl
    interval_id:integer,optional
    delivery_method_id:integer,optional
}

set user_id [auth::require_login]

# Check that the object can be subscribed to
permission::require_permission -object_id $object_id -privilege "read"

set doc(title) [_ notifications.Request_Notification]
set context [list $doc(title)]

if {$pretty_name eq ""} {
    set page_title [_ notifications.Request_Notification]
} else {
    set page_title [_ notifications.lt_Request_Notification_]
}

set intervals_pretty [notification::get_intervals -localized -type_id $type_id]
set delivery_methods [notification::get_delivery_methods -type_id $type_id]

set sse_notifications_p [::parameter::get_global_value \
                             -boolean \
                             -package_key notifications \
                             -parameter SSENotifications \
                             -default false]

set sse_delivery_method_id [::notification::delivery::get_id -short_name sse]

if {!$sse_notifications_p} {
    set delivery_methods [lsearch -all -not -inline -index 1 \
                              $delivery_methods $sse_delivery_method_id]
}

ad_form -name subscribe -export {
    type_id object_id return_url
} -form {
    {interval_id:integer(select)
        {label "[_ notifications.lt_Notification_Interval]"}
        {options $intervals_pretty}}
    {delivery_method_id:integer(select)
        {label "[_ notifications.Delivery_Method]"}
        {options $delivery_methods}
        {value {[lindex $delivery_methods 0 1]}}
    }
} -on_submit {

    db_transaction {
        # Add the subscribe
        notification::request::new \
            -type_id $type_id \
            -user_id $user_id \
            -object_id $object_id \
            -interval_id $interval_id \
            -delivery_method_id $delivery_method_id
    }

    ad_returnredirect $return_url
    ad_script_abort
}

if { [llength $delivery_methods] == 1 } {
    element set_properties subscribe delivery_method_id -widget hidden
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
