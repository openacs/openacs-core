ad_library {

    Notifications Security Library

    @creation-date 2002-05-27
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::security {

    ad_proc -public can_notify_object_p {
        {-user_id ""}
        {-object_id:required}
    } {
        # HACK
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
