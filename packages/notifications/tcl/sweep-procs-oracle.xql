<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="notification::sweep::cleanup_notifications.select_notification_ids">
        <querytext>
            select notifications.notification_id
            from notifications
            minus
            select notifications.notification_id
            from notifications, notification_requests, notification_user_map
            where notifications.type_id = notification_requests.type_id
              and notifications.object_id = notification_requests.object_id
              and notifications.notification_id = notification_user_map.notification_id(+)
              and sent_date is null
        </querytext>
    </fullquery>

    <fullquery name="notification::sweep::sweep_notifications.select_notifications">
        <querytext>
            select notifications.notification_id,
                   notif_subject,
                   notif_text,
                   notif_html,
                   notification_requests.user_id,
                   notification_requests.type_id,
                   notification_requests.delivery_method_id,
                   notifications.response_id
            from notifications,
                 notification_requests,
                 notification_user_map,
                 acs_objects notification_requests_object
            where notifications.type_id = notification_requests.type_id
              and interval_id = :interval_id
              and notifications.object_id = notification_requests.object_id
              and notifications.notification_id = notification_user_map.notification_id(+)
              and sent_date is null
              and notification_requests_object.object_id = notification_requests.request_id
              and notification_requests_object.creation_date <= notifications.notif_date
            order by notification_requests.user_id, notification_requests.type_id
        </querytext>
    </fullquery>

</queryset>
