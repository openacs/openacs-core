<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_info">      
      <querytext>
      
    select g.rel_type, g.group_id, acs_object.name(g.group_id) as group_name,
           t.pretty_name as rel_pretty_name
      from acs_object_types t, group_rels g
     where g.group_rel_id = :group_rel_id
       and t.object_type = g.rel_type

      </querytext>
</fullquery>

 
</queryset>
