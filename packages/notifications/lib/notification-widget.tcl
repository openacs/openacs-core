ad_include_contract {
    Include for notification chunk
} {
    type:token,notnull
    object_id:object_type(acs_object),notnull
    {pretty_name:allhtml}
    {url:localurl ""}
    {user_id:object_type(user) ""}
    {show_subscribers_p:boolean true}
}

if {$user_id eq ""} {
    set user_id [ad_conn user_id]
}
if {$url eq ""} {
    set url [ad_conn url]
}

set type_id [notification::type::get_type_id -short_name $type]
set request_id [notification::request::get_request_id \
                    -type_id $type_id \
                    -object_id $object_id \
                    -user_id $user_id]

if {$request_id ne ""} {
    set sub_url [notification::display::unsubscribe_url \
                     -request_id $request_id \
                     -url $url]
    set title [_ notifications.lt_Ubsubscribe_Notification_]
    set sub_chunk [_ notifications.lt_You_have_requested_no]
} else {
    set sub_url [notification::display::subscribe_url \
                     -type $type \
                     -object_id $object_id \
                     -url $url \
                     -user_id $user_id \
                     -pretty_name $pretty_name]
    set title [_ notifications.lt_Request_Notification_]
    set sub_chunk [_ notifications.lt_You_may_a_hrefsub_url]
}

if { $show_subscribers_p && [permission::permission_p -object_id $object_id -privilege admin] } {
    set subscribers_url [export_vars -base /notifications/subscribers -url {object_id}]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
