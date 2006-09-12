<?xml version="1.0"?>

<queryset>

    <fullquery name="notification::request::get_request_id.select_request_id">
        <querytext>
            select request_id
            from notification_requests
            where type_id = :type_id
            and user_id = :user_id
            and object_id = :object_id
        </querytext>
    </fullquery>

    <fullquery name="notification::request::request_exists.request_count">
        <querytext>
            select count(*)
            from notification_requests
            where type_id = :type_id
            and object_id = :object_id
        </querytext>
    </fullquery>

    <fullquery name="notification::request::request_count.request_count">
        <querytext>
            select count(*)
            from notification_requests
            where type_id = :type_id
            and object_id = :object_id
        </querytext>
    </fullquery>

    <fullquery name="notification::request::subscribers.request_subscribers">
        <querytext>
            select user_id
            from notification_requests
            where type_id = :type_id
            and object_id = :object_id
        </querytext>
    </fullquery>

    <fullquery name="notification::request::request_ids.request_ids">
        <querytext>
            select request_id
            from notification_requests
            where type_id = :type_id
            and object_id = :object_id
        </querytext>
    </fullquery>

</queryset>
