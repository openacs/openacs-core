<?xml version="1.0"?>
<queryset>

<fullquery name="select_pretty_name">      
      <querytext>
      FIX ME OUTER JOIN

    select t.pretty_name as group_type_pretty_name, t.dynamic_p,
           coalesce(gt.default_join_policy, 'open') as default_join_policy
      from acs_object_types t, group_types gt
     where t.object_type = :group_type
       and t.object_type = gt.group_type(+)

      </querytext>
</fullquery>

 
</queryset>
