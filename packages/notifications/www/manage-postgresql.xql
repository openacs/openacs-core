<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_notifications">      
      <querytext>
     select nr.request_id,
	    nr.type_id,
            nt.pretty_name as type,
            acs_object__name(nr.object_id) as object_name,
            ni.name as interval,
            nr.object_id
       from notification_requests nr,
            notification_intervals ni,
            notification_types nt,
            persons p
      where nr.user_id = :user_id
        and nr.interval_id = ni.interval_id
        and nr.type_id = nt.type_id
        and nr.user_id = p.person_id 
        and nr.dynamic_p = 'f'
      order by lower(nt.pretty_name), lower(acs_object__name(nr.object_id))
      </querytext>
</fullquery>

</queryset>
