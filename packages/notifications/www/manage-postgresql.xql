<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_notifications">      
      <querytext>
	select request_id,
	       type_id,
	  (select pretty_name
	   from notification_types
	   where notification_types.type_id =
	         notification_requests.type_id) as type,
           acs_object__name(notification_requests.object_id) as object_name,
	   (select name
	   from notification_intervals
	   where notification_intervals.interval_id =
	         notification_requests.interval_id) as interval,
	   object_id
	from notification_requests
	where user_id = :user_id
        and   dynamic_p = 'f'
      </querytext>
</fullquery>

</queryset>
