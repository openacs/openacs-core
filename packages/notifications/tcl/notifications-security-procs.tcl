ad_library {

    Notifications Security Library

    @creation-date 2002-05-27
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::security {

    ad_proc -public can_notify_user {
        {-user_id:required}
        {-delivery_method_id ""}
    } {
        This proc can be expanded to deal with cases when we don't want to 
        send a notification.  For instance we could check email_bouncing_p 
        or if a user is on vacation. Right now it just makes sure its an 
        approved user.
    } {
        return [db_string user_approved_p {} -default 0]
    }

    ad_proc -public can_notify_object_p {
        {-user_id ""}
        {-object_id:required}
    } { 
        # hack
        return 1
    }

    ad_proc -public require_notify_object {
        {-user_id ""}
        {-object_id:required}
    } {
    }

    ad_proc -public can_admin_request_p {
        {-user_id ""}
        {-request_id:required}
    } {
        # hack
        return 1
    } 

    ad_proc -public require_admin_request {
        {-user_id ""}
        {-request_id:required}
    } {
    }
    

}
