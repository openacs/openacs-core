
ad_page_contract {

    Request a new notification

    @author Ben Adida (ben@openforce.net)
    @creation-date 2002-05-24
    @cvs-id $Id$
} {
    type_id:integer,notnull
    object_id:integer,notnull
    return_url
}

set user_id [ad_conn user_id]

# Check that the object can be subcribed to
notification::security::require_notify_object -object_id $object_id

# Add the request
notification::request::new \
        -type_id $type_id \
        -user_id $user_id \
        -object_id $object_id \
        -interval_id $interval_id \
        -delivery_method_id $delivery_method_id

ad_returnredirect $return_url

        
