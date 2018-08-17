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

        @see permission::permission_p
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

        @see permission::require_permission
    } {
        # require user to be logged in
        auth::require_login
        return [can_notify_object_p -user_id $user_id -object_id $object_id]
    }

    ad_proc -public can_admin_request_p {
        {-user_id ""}
        {-request_id:required}
    } {
        Checks if a user can manage a given notification request.

        @param user_id
        @param request_id

        @see permission::permission_p
    } {
        # owner of notification or side-wide admin
        set allowed 0
        if {$user_id eq ""} {
            set user_id [ad_conn user_id]
        }
        if {[acs_user::site_wide_admin_p -user_id $user_id]} {
            set allowed 1
        } else {
            set sql "select user_id from notification_requests where object_id = :request_id"
            set owner_id [db_string get_user_id $sql -default ""]
            if {$owner_id eq $user_id} {
                set allowed 1
            }
        }
        return $allowed
    }

    ad_proc -public require_admin_request {
        {-user_id ""}
        {-request_id:required}
    } {
        Require the ability to admin a request.

        @param user_id
        @param request_id

        @see permission::require_permission
    } {
        # require user to be logged in
        auth::require_login
        return [can_admin_request_p -user_id $user_id -request_id $request_id]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
