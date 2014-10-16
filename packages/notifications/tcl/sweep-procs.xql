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
