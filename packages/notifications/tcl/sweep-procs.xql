<?xml version="1.0"?>

<queryset>

    <fullquery name="notification::sweep::cleanup_notifications.select_notification_ids">
        <querytext>
           select notification_id
           from notifications
           where notification_id not in (
           select distinct notification_id
           from notifications inner join notification_requests using (type_id, object_id)
             inner join acs_objects on (notification_requests.request_id = acs_objects.object_id)
             left outer join notification_user_map using (notification_id, user_id)
           where sent_date is null and creation_date <= notif_date
           )  
        </querytext>
    </fullquery>

</queryset>
