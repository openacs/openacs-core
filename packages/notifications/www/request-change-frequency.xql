<?xml version="1.0"?>

<queryset>

<fullquery name="update_notification_frequency">      
   <querytext>

    update notification_requests
    set interval_id = :interval_id
    where request_id = :request_id

    </querytext>
</fullquery>


</queryset>
