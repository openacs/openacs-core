<?xml version="1.0"?>

<queryset>
  <rdbms><type>postgresql</type><version>7.1</version></rdbms>
  <fullquery name="select_name">      
    <querytext>
      select acs_object__name(object_id) as name, type_id
      from notification_requests
      where dynamic_p = 'f'
        and object_id = :object_id
      order by type_id limit 1
    </querytext>
  </fullquery>
</queryset>
