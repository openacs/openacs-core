<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_notification_request">      
   <querytext>

    select type_id, interval_id, 
    acs_object.name(notification_requests.object_id) as object_name
    from notification_requests
    where request_id = :request_id

    </querytext>
</fullquery>

</queryset>
