<?xml version="1.0"?>
<queryset>

<fullquery name="get_name">      
      <querytext>
      
  select 
    first_names || ' ' || last_name 
  from 
    persons 
  where 
    person_id = :user_id

      </querytext>
</fullquery>

 
</queryset>
