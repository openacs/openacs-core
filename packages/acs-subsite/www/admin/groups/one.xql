<?xml version="1.0"?>
<queryset>

<fullquery name="group_info">      
      <querytext>
      
    select g.group_name, g.join_policy,
           o.object_type as group_type
      from groups g, acs_objects o, acs_object_types t
     where g.group_id = o.object_id
       and o.object_type = t.object_type
       and g.group_id = :group_id

      </querytext>
</fullquery>

 
</queryset>
