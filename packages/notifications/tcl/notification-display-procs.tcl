ad_library {

    Notifications Display Procs.

    Notifications is mostly a service package, but it does have some level of user interface.
    These procs enable other packages to simply display information about notifications.

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::display {}

ad_proc -public notification::display::request_widget {
    {-type:required}
    {-object_id:required}
    {-pretty_name:required}
    {-url:required}
    {-user_id ""}
} {
    Produce a widget for requesting notifications of a given type.   If the notifications package has not been
    mounted then return the empty string.
} {
    # Check that we're mounted
    if { [empty_string_p [apm_package_url_from_key [notification::package_key]]] } {
        return {}
    }
    
    if {[empty_string_p $user_id]} {
        set user_id [ad_conn user_id]
    }

    # Get the type id
    set type_id [notification::type::get_type_id -short_name $type]

    # Check if subscribed
    set request_id [notification::request::get_request_id -type_id $type_id -object_id $object_id -user_id $user_id]
    
    if {![empty_string_p $request_id]} {
        set icon /resources/acs-subsite/email_delete.gif
        set icon_alt [_ acs-subsite.icon_of_envelope]
        set sub_url [ad_quotehtml [unsubscribe_url -request_id $request_id -url $url]]
        set pretty_name [ad_quotehtml $pretty_name]
        set title [_ notifications.lt_Ubsubscribe_Notification_]
        set sub_chunk "[_ notifications.lt_You_have_requested_no]"
    } else {
        set icon /resources/acs-subsite/email_add.gif
        set icon_alt [_ acs-subsite.icon_of_envelope]
        set sub_url [ad_quotehtml [subscribe_url -type $type -object_id $object_id -url $url -user_id $user_id -pretty_name $pretty_name]]
        set pretty_name [ad_quotehtml $pretty_name]
        set title [_ notifications.lt_Request_Notification_]
        set sub_chunk "[_ notifications.lt_You_may_a_hrefsub_url]"
    }
    set notif_chunk "<a href=\"$sub_url\" title=\"$title\"><img src=\"$icon\" alt=\"$icon_alt\" style=\"border:0\"> $sub_chunk</a>"
    # if they are an admin give them to view all subscribers
    if { [permission::permission_p -object_id $object_id -privilege admin] } {
        append notif_chunk " \[<a href=\"[export_vars -base /notifications/subscribers -url {object_id}]\">[_ notifications.Subscribers]</a>\]"
    }

    if { ![empty_string_p $sub_url] } {
        return $notif_chunk
    } else {
         return ""
    }

}

ad_proc -public notification::display::subscribe_url {
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

    set subscribe_url [export_vars -base "${root_path}request-new" { type_id user_id object_id pretty_name {return_url $url} }]

    return $subscribe_url
}

ad_proc -public notification::display::unsubscribe_url {
    {-request_id:required}
    {-url:required}
} {
    Returns the URL that allows one to unsubscribe from a particular request.	
} {
    set root_path [apm_package_url_from_key [notification::package_key]]

    if { [empty_string_p $root_path] } {
        return ""
    }

    set unsubscribe_url [export_vars -base "${root_path}request-delete" { request_id { return_url $url } }]

    return $unsubscribe_url
}

ad_proc -public notification::display::get_urls {
    {-type:required}
    {-object_id:required}
    {-return_url {}}
    {-pretty_name}
} {
    Get both subscribe_url and unsubscribe_url as . 
    At most one of them will be set.

    Example: <pre>
    foreach { subscribe_url unsubscribe_url } \
        [notification::display::get_urls \
             -type "my_notif_type" \
             -object_id $object_id \
             -pretty_name $title] {}</pre>

    The above foreach trick will cause subscribe_url and unsubscribe_url 
    to be set correctly. Don't forget the end pair of curly braces.

    @return a Tcl list with two elements (subscribe_url, unsubscribe_url)
} {
    set root_path [apm_package_url_from_key [notification::package_key]]
    if { [empty_string_p $root_path] } {
        return [list {} {}]
    }
    set type_id [notification::type::get_type_id -short_name $type]

    if { [empty_string_p $return_url] } {
        set return_url [ad_return_url]
    }

    # Check if subscribed
    set request_id [notification::request::get_request_id -type_id $type_id -object_id $object_id -user_id [ad_conn untrusted_user_id]]


    if { [empty_string_p $request_id] } {
        return [list [export_vars -base "${root_path}request-new" { type_id object_id pretty_name return_url }] {}]
    } else {
        return [list {} [export_vars -base "${root_path}request-delete" { request_id return_url }]]
    }
}

