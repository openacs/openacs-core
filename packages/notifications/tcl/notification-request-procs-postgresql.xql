<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::request::delete.delete_request">
        <querytext>
            select notification_request__delete(:request_id);
        </querytext>
    </fullquery>

    <fullquery name="notification::request::delete_all.delete_all_requests">
        <querytext>
            select notification_request__delete_all(:object_id);
        </querytext>
    </fullquery>

    <fullquery name="notification::request::delete_all.delete_all_requests_for_all_users">
        <querytext>
            select notification_request__delete_all_for_user(:user_id);
        </querytext>
    </fullquery>

</queryset>
