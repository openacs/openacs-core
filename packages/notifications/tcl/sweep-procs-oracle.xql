<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="notification::sweep::cleanup_notifications.select_notification_ids">
        <querytext>
            select notification_id
            from notifications
            where not exists (select notifications.notification_id
                              from notifications,
                                   notification_requests,
                                   notification_user_map
                              where notifications.type_id = notification_requests.type_id
                              and notifications.object_id = notification_requests.object_id
                              and notifications.notification_id = notification_user_map.notification_id(+)
                              and sent_date is null)
        </querytext>
    </fullquery>

    <fullquery name="notification::sweep::sweep_notifications.select_notifications">
        <querytext>
            select notifications.notification_id,
                   notif_subject,
                   notif_text,
                   notif_html,
                   notification_requests.user_id,
                   type_id,
                   acs_object.name(notifications.object_id) as object_name
            from notifications,
                 notification_requests,
                 notification_user_map
            where notifications.type_id = notification_requests.type_id
            and interval_id = :interval_id
            and notifications.object_id = notification_requests.object_id
            and notifications.notification_id = notification_user_map.notification_id(+)
            and sent_date is null
        </querytext>
    </fullquery>

</queryset>
