<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::sweep::cleanup_notifications.select_notification_ids">
        <querytext>
           select notifications.notification_id
           from notifications
           except
           select distinct notifications.notification_id
           from notifications left outer join notification_user_map
             on (notifications.notification_id = notification_user_map.notification_id)
             inner join notification_requests
             on (notifications.type_id = notification_requests.type_id
                 and notifications.object_id = notification_requests.object_id)
           where sent_date is null
        </querytext>
    </fullquery>

    <fullquery name="notification::sweep::sweep_notifications.select_notifications">
        <querytext>
            select notifications.notification_id,
                   notifications.notif_subject,
                   notifications.notif_text,
                   notifications.notif_html,
                   notification_requests.user_id,
                   notification_requests.type_id,
                   notification_requests.delivery_method_id,
                   notifications.response_id
            from notifications
                     inner join notification_requests
                         on (
                                  notifications.type_id = notification_requests.type_id
                              and notifications.object_id = notification_requests.object_id
                              and notification_requests.interval_id = :interval_id
                         )
                     inner join acs_objects on (notification_requests.request_id = acs_objects.object_id)
                     left outer join notification_user_map
                         on (notifications.notification_id = notification_user_map.notification_id)
            where notification_user_map.sent_date is null
              and acs_objects.creation_date <= notifications.notif_date
            order by notification_requests.user_id, notification_requests.type_id
        </querytext>
    </fullquery>

</queryset>
