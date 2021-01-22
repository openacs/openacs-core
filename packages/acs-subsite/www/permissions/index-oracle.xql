<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="adminable_objects">      
      <querytext>
 select o.object_id, acs_object.name(o.object_id) as name, context_id, object_type,
    (case when o.object_id = :root then 0 else 1 end) as child
  from acs_objects o
  where exists (
    SELECT 1 
      FROM acs_object_party_privilege_map map
     WHERE map.object_id = o.object_id
       and map.party_id = :user_id
       and map.privilege = 'admin')
    and (o.object_id = :root or o.context_id = :root)
    order by child, object_type, name      
      </querytext>
</fullquery>

 
</queryset>

