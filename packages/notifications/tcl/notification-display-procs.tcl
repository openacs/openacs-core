ad_library {

    Notifications Display Procs.

    Notifications is mostly a service package, but it does have some level of user interface.
    These procs enable other packages to simply display information about notifications.

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::display {

    ad_proc -public request_widget {
        {-type:required}
        {-object_id:required}
        {-pretty_name:required}
        {-url:required}
        {-user_id ""}
    } {
        Produce a widget for requesting notifications of a given type.   If the notifications package has not been
        mounted then return the empty string.
    } {
        if {[empty_string_p $user_id]} {
            set user_id [ad_conn user_id]
        }

        # Get the type id
        set type_id [notification::type::get_type_id -short_name $type]

        # Check if subscribed
        set request_id [notification::request::get_request_id -type_id $type_id -object_id $object_id -user_id $user_id]
        
        if {![empty_string_p $request_id]} {
            set sub_url [unsubscribe_url -request_id $request_id -url $url]
            set sub_chunk "You have requested notification for $pretty_name. You may <a href=\"$sub_url\">unsubscribe</a>."
        } else {
            set sub_url [subscribe_url -type $type -object_id $object_id -url $url -user_id $user_id -pretty_name $pretty_name]
            set sub_chunk "You may <a href=\"$sub_url\">request notification</a> for $pretty_name."
        }

        if { [empty_string_p $sub_url] } {
             return ""
        }

        return $sub_chunk
    }

    ad_proc -public subscribe_url {
        {-type:required}
        {-object_id:required}
        {-url:required}
        {-user_id:required}
        {-pretty_name}
    } {
	Returns the URL that allows one to subscribe to a notification type on a particular object.   If the
        notifications package has not been mounted return the empty string.
    } {
        set type_id [notification::type::get_type_id -short_name $type]

        set root_path [apm_package_url_from_key [notification::package_key]]

        if { [empty_string_p $root_path] } {
            return ""
        }

        set subscribe_url "${root_path}request-new?[export_vars { type_id user_id object_id pretty_name {return_url $url} }]"

        return $subscribe_url
    }

    ad_proc -public unsubscribe_url {
        {-request_id:required}
        {-url:required}
    } {
	Returns the URL that allows one to unsubscribe from a particular request.	
    } {
        set root_path [apm_package_url_from_key [notification::package_key]]

        if { [empty_string_p $root_path] } {
            return ""
        }

        set unsubscribe_url "${root_path}request-delete?request_id=$request_id&return_url=[ns_urlencode $url]"

        return $unsubscribe_url
    }
}
