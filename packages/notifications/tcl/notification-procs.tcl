ad_library {

    Notifications

    Core procs for managing notifications. Important concepts:
    <ul>
    <li> notification: a single message that needs to be sent to users. 
    <li> intervals: the duration of time between notifications. Ranges from "instantaneous" to "weekly".
    <li> delivery method: the means by which a notification is delivered. "email" is the obvious one, but "sms" might be another.
    <li> notification type: a category of notifications, like forum_notification for forum postings, or forum_statistics for regular updates on forum statistics (this latest one is for illustration purposes only and doesn't currently exist in the forums package).
    </ul>

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification {

    ad_proc -public package_key {} {
	The package key
    } {
        return "notifications"
    }

    ad_proc -public get_interval_id {
        {-name:required}
    } {
	obtain the interval ID for an interval with the given name.
	Interval names are unique, but are not the primary key.
    } {
        return [db_string select_interval_id {} -default ""]
    }

    ad_proc -public get_delivery_method_id {
        {-name:required}
    } {
	obtain the delivery method ID with the given name.
	Delivery method names are unique, but are not the primary key.
    } {
        return [db_string select_delivery_method_id {} -default ""]
    }

    ad_proc -public get_all_intervals {} {
	return a list of all available intervals in a list of lists format,
	with the following fields: name, interval_id, n_seconds.
    } {
        return [db_list_of_lists select_all_intervals {}]
    }
    
    ad_proc -public get_intervals {
        {-type_id:required}
    } {
	return a list of intervals that are associated with a given notification type
	(not all intervals are available to all notification types).
	The fields for each interval is: name, interval_id, n_seconds.
    } {
        return [db_list_of_lists select_intervals {}]
    }

    ad_proc -public get_delivery_methods {
        {-type_id:required}
    } {
	return a list of delivery methods associated with a given notification type
	(not all delivery methods are available to all notification types).
	The fields are: pretty_name, delivery_method_id
    } {
        return [db_list_of_lists select_delivery_methods {}]
    }

    ad_proc -public new {
        {-notification_id ""}
        {-type_id:required}
        {-object_id:required}
        {-response_id ""}
        {-notif_subject ""}
        {-notif_text ""}
        {-notif_html ""}
    } {
        create a new notification
    } {
        # Set up the vars
        set extra_vars [ns_set create]
        oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {notification_id type_id object_id response_id notif_subject notif_text notif_html}

        # Create the request
        set notification_id [package_instantiate_object -extra_vars $extra_vars notification]

        return $notification_id
    }

    ad_proc -public delete {
        {-notification_id:required}
    } {
        delete a notification
    } {
        db_transaction {
            # Remove the mappings
            db_dml delete_mappings {}

            # do the delete
            db_exec_plsql delete_notification {}
        }
    }
    
    ad_proc -public mark_sent {
        {-notification_id:required}
        {-user_id:required}
    } {
        mark that a user has been sent a notification
    } {
        # Do the insert
        db_dml insert_notification_user_map {}
    }
}
