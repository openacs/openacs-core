<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::sweep::cleanup_notifications.select_notification_ids">
        <querytext>
           select notification_id
           from notifications
           except
           select distinct notification_id
           from notifications inner join notification_requests using (type_id, object_id)
             inner join acs_objects on (notification_requests.request_id = acs_objects.object_id)
             left outer join notification_user_map using (notification_id, user_id)
           where sent_date is null and creation_date <= notif_date
        </querytext>
    </fullquery>

    <fullquery name="notification::sweep::sweep_notifications.select_notifications">
        <querytext>
            select notification_id,
                   notif_subject,
                   notif_text,
                   notif_html,
                   file_ids,
                   user_id,
                   type_id,
                   delivery_method_id,
		   response_id,
		   notif_date,
                   notif_user
            from notifications inner join notification_requests using (type_id, object_id)
              inner join acs_objects on (notification_requests.request_id = acs_objects.object_id)
              left outer join notification_user_map using (notification_id, user_id)
            where sent_date is null
              and creation_date <= notif_date
              and (notif_date is null or notif_date < current_timestamp)
              and interval_id = :interval_id
              and acs_permission__permission_p(notification_requests.object_id, notification_requests.user_id, 'read')
          order by user_id, type_id, notif_date
        </querytext>
    </fullquery>

    <fullquery name="notification::sweep::cleanup_notifications.select_invalid_request_ids">
        <rdbms><type>postgresql</type><version>8.4</version></rdbms>
        <querytext>
         select request_id
           from notification_requests
          where acs_permission__permission_p(object_id, user_id, 'read') is false;
        </querytext>
    </fullquery>

</queryset>
