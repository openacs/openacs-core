<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_notification_request">      
   <querytext>

    select type_id, interval_id, 
    acs_object__name(notification_requests.object_id) as object_name
    from notification_requests
    where request_id = :request_id

    </querytext>
</fullquery>

</queryset>
