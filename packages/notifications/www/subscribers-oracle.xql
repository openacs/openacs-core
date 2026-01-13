<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="select_name">      
    <querytext>
      select acs_object.name(object_id) as name, type_id
      from notification_requests
      where dynamic_p = 'f'
        and object_id = :object_id
        and rownum = 1
      order by type_id
    </querytext>
  </fullquery>
</queryset>
