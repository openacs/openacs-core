ad_library {

    Notifications

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification {

    ad_proc -public package_key {} {
        return "notifications"
    }

    ad_proc -public get_all_intervals {} {
        return [db_list_of_lists select_all_intervals {}]
    }
    
    ad_proc -public get_intervals {
        {-type_id:required}
    } {
        return [db_list_of_lists select_intervals {}]
    }

    ad_proc -public get_delivery_methods {
        {-type_id:required}
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
