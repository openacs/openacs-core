<?xml version="1.0"?>

<queryset>

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
