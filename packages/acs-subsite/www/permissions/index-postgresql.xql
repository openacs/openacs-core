<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="adminable_objects">      
      <querytext>
         select o.object_id,
                acs_object__name(o.object_id) as name,
                context_id,
                object_type,
                (case when o.object_id = :root then 0 else 1 end) as child
         from acs_permission.permission_p_recursive_array(array(
             select object_id from acs_objects where object_id = :root or context_id = :root
           ), :user_id, 'admin') p, acs_objects o
         where p.orig_object_id = o.object_id
         order by child, object_type, name 
      </querytext>
</fullquery>

 
</queryset>
