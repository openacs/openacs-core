<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="adminable_objects">      
      <querytext>
 select o.object_id, acs_object__name(o.object_id) as name, context_id, object_type,
    (case when o.object_id = :root then 0 else 1 end) as child
  from acs_objects o
  where exists ( SELECT 1 
                   FROM acs_permissions_all map 
                  WHERE map.object_id = o.object_id
                    and map.grantee_id = :user_id
                    and map.privilege = 'admin')
    and (o.object_id = :root or o.context_id = :root)
    order by child, object_type, name
      </querytext>
</fullquery>

 
</queryset>
