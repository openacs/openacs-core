ad_library {

    Notifications Security Library

    Manage permissions for notifications.

    @creation-date 2002-05-27
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::security {

    ad_proc -public can_notify_user {
        {-user_id:required}
        {-delivery_method_id ""}
    } {
        Can a user be notified for a given delivery method.

        This proc can be expanded to deal with cases when we don't want to
        send a notification.  For instance we could check email_bouncing_p
        or if a user is on vacation. Right now it just makes sure its an
        approved user.

        @param user_id
        @param delivery_method_id
    } {
        return [db_string user_approved_p {} -default 0]
    }

    ad_proc -public can_notify_object_p {
        {-user_id ""}
        {-object_id:required}
    } {
        This checks if a user can request notification on a given object.

        @param user_id
        @param object_id
    } {
        return [permission::permission_p -party_id $user_id -object_id $object_id -privilege "read"]
    }

    ad_proc -public require_notify_object {
        {-user_id ""}
        {-object_id:required}
    } {
        Require the ability to notify on an object.

        @param user_id
        @param object_id
    } {
        permission::require_permission -party_id $user_id -object_id $object_id -privilege "read"
    }

    ad_proc -public can_admin_request_p {
        {-user_id ""}
        {-request_id:required}
    } {
        Checks if a user can manage a given notification request.

        @param user_id
        @param request_id
    } {
        return [permission::permission_p -party_id $user_id -object_id $request_id -privilege "admin"]
    }

    ad_proc -public require_admin_request {
        {-user_id ""}
        {-request_id:required}
    } {
        Require the ability to admin a request.

        @param user_id
        @param request_id
    } {
        permission::require_permission -party_id $user_id -object_id $object_id -privilege "admin"
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
