<?xml version="1.0"?>
<queryset>

<fullquery name="select_info">      
      <querytext>
      
    select g.rel_type, g.group_type, 
           t.pretty_name as rel_pretty_name, t2.pretty_name as group_type_pretty_name
      from acs_object_types t, acs_object_types t2, group_type_rels g
     where g.group_rel_type_id = :group_rel_type_id
       and t.object_type = g.rel_type
       and t2.object_type = g.group_type

      </querytext>
</fullquery>

 
</queryset>
