ad_library {

    Notifications

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification {

    ad_proc -public new {
    } {
        create a new notification
    } {
        # Set up the vars
        set extra_vars [ns_set create]
        oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {}

        # Create the request
        set notification_id [package_instantiate_object -extra_vars $extra_vars notification]

        return $notification_id
    }

    ad_proc -public delete {
        {-notification_id:required}
    } {
        delete a notification
    } {
        # do the delete
        # FIXME: implement this
        db_exec_plsql delete_notification {}
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
