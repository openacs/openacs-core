<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_pretty_name">      
      <querytext>
      FIX ME OUTER JOIN

    select t.dynamic_p,
           case when gt.group_type = null then 0 else 1 end as group_type_exists_p
      from acs_object_types t, group_types gt
     where t.object_type = :group_type
       and t.object_type = gt.group_type(+)

      </querytext>
</fullquery>

 
</queryset>
