ad_library {

    Notification Requests

    When a user wishes to receive notifications of a certain type on a given object,
    he issues a notification request. This request is recorded specifically for that user.
    These procs help to manage such requests.

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::request {

    ad_proc -public new {
        {-request_id ""}
        {-type_id:required}
        {-user_id:required}
        {-object_id:required}
        {-interval_id:required}
        {-delivery_method_id:required}
        {-format "text"}
        {-dynamic_p "f"}
    } {
        create a new request for a given user, notification type, object, interval and delivery method.
    } {
        set request_id [get_request_id -type_id $type_id -object_id $object_id -user_id $user_id]

        if {[empty_string_p $request_id]} {
            # Set up the vars
            set extra_vars [ns_set create]
            oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {request_id type_id user_id object_id interval_id delivery_method_id format dynamic_p}

            # Create the request
            set request_id [package_instantiate_object -extra_vars $extra_vars notification_request]
        }

        return $request_id
    }

    ad_proc -public get_request_id {
        {-type_id:required}
        {-object_id:required}
        {-user_id:required}
    } {
        Checks if a particular notification request exists, and if so return the request ID.
	Note that the primary key on notification requests is notification_type, object, user.
	Interval and delivery method are specific parameters, but do not impact the uniqueness:
	a user can choose only one interval and delivery method for a given notification type and object.
    } {
        return [db_string select_request_id {} -default {}]
    }

    ad_proc -public request_exists {
        {-type_id:required}
        {-object_id:required}
    } {
        returns true if at least one request exists for this object and type
    } {
        return [expr { [db_string request_count {}] > 0 }]
    }

    ad_proc -public request_count {
        {-type_id:required}
        {-object_id:required}
    } {
        returns number of notification requests for this type and object
    } {
        return [db_string request_count {} -default 0]
    }

    ad_proc -public subscribers {
        {-type_id:required}
        {-object_id:required}
    } {
        returns a list of subscribers for notifications on that object of this type
    } {
        return [db_list request_subscribers {}]
    }

    ad_proc -public request_ids {
        {-type_id:required}
        {-object_id:required}
    } {
        returns a list of request_ids for the object_id of the given type
    } {
        return [db_list request_ids {}]
    }

    ad_proc -public delete {
        {-request_id:required}
    } {
        delete a request for notifications by request ID.
    } {
        # do the delete
        db_exec_plsql delete_request {}
    }

    ad_proc -public delete_all {
        {-object_id:required}
    } {
        remove all requests for a particular object ID
        usually because the object is getting deleted.
    } {
        # Do it
        db_exec_plsql delete_all_requests {}
    }

    ad_proc -public delete_all_for_user {
        {-user_id:required}
    } {
        delete all the requests for a given user
    } {
        # do the delete
        db_exec_plsql delete_all_for_user {}
    }
}
