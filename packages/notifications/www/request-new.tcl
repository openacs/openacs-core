ad_page_contract {

    Request a new notification - Ask for more stuff

    @author Ben Adida (ben@openforce.net)
    @creation-date 2002-05-24
    @cvs-id $Id$
} {
    type_id:integer,notnull
    object_id:integer,notnull
    {pretty_name ""}
    return_url
}

set user_id [ad_maybe_redirect_for_registration]

# Check that the object can be subcribed to
notification::security::require_notify_object -object_id $object_id


if {[empty_string_p $pretty_name]} { 
    set page_title "Request Notification"
} else { 
    set page_title "Request Notification for $pretty_name"
}

set context [list "Request Notification"]


form create subscribe

element create subscribe type_id \
        -label "Type ID" -datatype integer -widget hidden

element create subscribe object_id \
        -label "Object ID" -datatype integer -widget hidden

element create subscribe return_url \
        -label "Return URL" -datatype text -widget hidden

element create subscribe interval_id \
        -label "Notification Interval" -datatype integer -widget select -options [notification::get_intervals -type_id $type_id]

element create subscribe delivery_method_id \
        -label "Delivery Method" -datatype integer -widget select -options [notification::get_delivery_methods -type_id $type_id]

if {[form is_valid subscribe]} {
    template::form get_values subscribe type_id object_id return_url interval_id delivery_method_id

    # Add the subscribe
    notification::request::new \
            -type_id $type_id \
            -user_id $user_id \
            -object_id $object_id \
            -interval_id $interval_id \
            -delivery_method_id $delivery_method_id

    ad_returnredirect $return_url
    ad_script_abort
}
        
element set_properties subscribe type_id -value $type_id
element set_properties subscribe object_id -value $object_id
element set_properties subscribe return_url -value $return_url
