ad_library {

    Notifications Display Procs

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
    } {
        Produce a widget for requesting notifications
    } {
        set user_id [ad_conn user_id]

        # Get the type id
        set type_id [notification::type::get_type_id -short_name $type]

        # Check if subscribed
        set request_id [notification::request::get_request_id -type_id $type_id -object_id $object_id -user_id $user_id]
        
        set root_path [apm_package_url_from_key [notification::package_key]]
        set encoded_stuff "pretty_name=[ns_urlencode $pretty_name]&return_url=[ns_urlencode $url]"

        if {![empty_string_p $request_id]} {
            set sub_url "${root_path}request-delete?request_id=$request_id&$encoded_stuff"
            set sub_chunk "You have requested notification for $pretty_name. You may <a href=\"$sub_url\">unsubscribe</a>."
        } else {
            set sub_url "${root_path}request-new?type_id=$type_id&user_id=$user_id&object_id=$object_id&$encoded_stuff"
            set sub_chunk "You may <a href=\"$sub_url\">request notification</a> for $pretty_name."
        }

        return "<font size=-1>\[ $sub_chunk \]</font>"
    }
}
