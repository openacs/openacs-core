<?xml version="1.0"?>
  <queryset>
    <fullquery name="select_notifications">      
      <querytext>
         select nr.user_id, ni.name as interval, nt.pretty_name as type
         from notification_requests nr, notification_intervals ni, notification_types nt,
           persons p
         where nr.object_id = :object_id
           and nr.interval_id = ni.interval_id
           and nr.type_id = nt.type_id
           and nr.user_id = p.person_id 
           and nr.dynamic_p = 'f'
         order by lower(p.last_name), lower(p.first_names)
      </querytext>
    </fullquery>
  </queryset>
