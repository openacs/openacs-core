<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::sweep::cleanup_notifications.select_notification_ids">
        <querytext>
            select notification_id
            from notifications
            where now() - notif_date > 2
              and not exists (select notifications.notification_id
                              from notifications
                                  inner join notification_requests
                                      on (
                                               notifications.type_id = notification_requests.type_id
                                           and notifications.object_id = notification_requests.object_id
                                      )
                                  left outer join notification_user_map
                                      on (notifications.notification_id = notification_user_map.notification_id)
                              where notification_user_map.sent_date is null)
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
                         )
                     left outer join notification_user_map
                         on (notifications.notification_id = notification_user_map.notification_id)
            where notification_requests.interval_id = :interval_id
            and notification_user_map.sent_date is null
        </querytext>
    </fullquery>

</queryset>
