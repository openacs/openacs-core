ad_library {

    Notification Requests

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
    } {
        create a new request
    } {
        # Set up the vars
        set extra_vars [ns_set create]
        oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {request_id type_id user_id object_id interval_id delivery_method_id format}

        # Create the request
        set request_id [package_instantiate_object -extra_vars $extra_vars notification_request]

        return $request_id
    }

    ad_proc -public get_request_id {
        {-type_id:required}
        {-object_id:required}
        {-user_id:required}
    } {
        Checks if a particular notification request exists
    } {
        return [db_string select_request_id {} -default {}]
    }

    ad_proc -public delete {
        {-request_id:required}
    } {
        delete a request
    } {
        # do the delete
        db_exec_plsql delete_request {}
    }

    ad_proc -public delete_all {
        {-object_id:required}
    } {
        remove all requests for a particular object ID
        usually because the object is getting deleted
    } {
        # Do it
        db_exec_plsql delete_all_requests {}
    }
}
