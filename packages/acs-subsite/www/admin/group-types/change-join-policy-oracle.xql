<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_pretty_name">      
      <querytext>
      
    select t.pretty_name as group_type_pretty_name, t.dynamic_p,
           nvl(gt.default_join_policy, 'open') as default_join_policy
      from acs_object_types t, group_types gt
     where t.object_type = :group_type
       and t.object_type = gt.group_type(+)

      </querytext>
</fullquery>

 
</queryset>
