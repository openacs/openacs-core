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

    <fullquery name="notification::sweep::cleanup_notifications.delete_dynamic_requests">
        <querytext>
           delete from notification_requests
           where  dynamic_p = 't'
           and    exists (select 1 
                          from    notifications n, 
                                  notification_user_map num
                          where   n.type_id = type_id
                          and     n.object_id = object_id
                          and     num.notification_id = n.notification_id
                          and     num.user_id = user_id)
        </querytext>
    </fullquery>


</queryset>
