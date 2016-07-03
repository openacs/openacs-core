<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="notification::sweep::cleanup_notifications.select_notification_ids">
        <querytext>
            select notifications.notification_id
            from notifications
            minus
            select nnr.notification_id
	    from (select notification_id, user_id
                  from notifications, notification_requests, acs_objects
                  where notifications.type_id = notification_requests.type_id
		    and notifications.object_id = notification_requests.object_id
		    and notification_requests.request_id = acs_objects.object_id
		    and acs_objects.creation_date <= notifications.notif_date) nnr,
              notification_user_map
            where nnr.notification_id = notification_user_map.notification_id(+)
              and nnr.user_id = notification_user_map.user_id(+)
	      and notification_user_map.sent_date is null
        </querytext>
    </fullquery>

    <fullquery name="notification::sweep::sweep_notifications.select_notifications">
        <querytext>
            select nnr.*
            from (select notifications.notification_id,
                    notifications.notif_subject,
                    notifications.notif_text,
                    notifications.notif_html,
                    notifications.file_ids,
                    notification_requests.user_id,
                    notification_requests.object_id,
                    notification_requests.type_id,
                    notification_requests.delivery_method_id,
                    notification_requests.request_id,
                    notifications.response_id,
                    notifications.notif_date,
                    notifications.notif_user
                  from notifications, notification_requests
                  where notifications.type_id = notification_requests.type_id
                    and notifications.object_id = notification_requests.object_id
                    and notification_requests.interval_id = :interval_id) nnr,
              notification_user_map, acs_objects
            where nnr.notification_id = notification_user_map.notification_id(+)
              and nnr.user_id = notification_user_map.user_id(+)
              and notification_user_map.sent_date is null
              and (nnr.notif_date is null or nnr.notif_date < sysdate)
              and acs_objects.object_id = nnr.request_id
              and acs_objects.creation_date <= nnr.notif_date
              and exists (select 1 from acs_object_party_privilege_map ppm 
                           where ppm.object_id = nnr.object_id
                             and ppm.privilege = 'read'
                             and ppm.party_id = nnr.user_id)
            order by nnr.user_id, nnr.type_id, nnr.notif_date
        </querytext>
    </fullquery>

    <fullquery name="notification::sweep::cleanup_notifications.select_invalid_request_ids">
        <querytext>
         select request_id
          from notification_requests
          where not exists (select 1 from acs_object_party_privilege_map ppm 
                             where ppm.object_id = notification_requests.object_id
                               and ppm.privilege = 'read'
                               and ppm.party_id = notification_requests.user_id)
        </querytext>
    </fullquery>

</queryset>
