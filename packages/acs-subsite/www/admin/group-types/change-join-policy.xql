<?xml version="1.0"?>
<queryset>

<fullquery name="select_pretty_name">      
      <querytext>

    select t.pretty_name as group_type_pretty_name, t.dynamic_p,
           coalesce(gt.default_join_policy, 'open') as default_join_policy
      from acs_object_types t left outer join group_types gt on (t.object_type = gt.group_type)
     where t.object_type = :group_type

      </querytext>
</fullquery>

 
</queryset>
