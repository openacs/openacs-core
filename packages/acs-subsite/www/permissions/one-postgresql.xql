<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="name">      
      <querytext>
      select acs_object__name(:object_id) 
      </querytext>
</fullquery>

 
<fullquery name="inherited_permissions">      
      <querytext>

  select grantee_id, grantee_name, privilege
  from (
	select grantee_id, acs_object__name(grantee_id) as grantee_name, privilege, 1 as counter
	from acs_permission.permissions_all(:object_id)
        union all
        select grantee_id, acs_object__name(grantee_id) as grantee_name, privilege, -1 as counter
        from acs_permissions
        where object_id = :object_id ) dummy
  group by grantee_id, grantee_name, privilege
  having sum(counter) > 0

      </querytext>
</fullquery>

 
<fullquery name="acl">      
      <querytext>
      
  select grantee_id, acs_object__name(grantee_id) as grantee_name,
         privilege
  from acs_permissions
  where object_id = :object_id
      </querytext>
</fullquery>

 
<fullquery name="context">      
      <querytext>

SELECT acs_object__name(context_id) as context_name, context_id, security_inherit_p
  FROM acs_objects
 WHERE object_id = :object_id

      </querytext>
</fullquery>

 
<fullquery name="children">      
  <querytext>
    
  select
    o.object_id as c_object_id,
    acs_object__name(o.object_id) as c_name,
    o.object_type as c_type
  from
    acs_permission.permission_p_recursive_array(array(
       select object_id from acs_objects o where context_id = :object_id
    ), :user_id, 'admin') p
  join acs_objects o on (p.orig_object_id = o.object_id)
			  
  </querytext>
</fullquery>


<fullquery name="children_count">      
  <querytext>

  select count(*) as num_children
  from acs_permission.permission_p_recursive_array(array(
       select object_id from acs_objects o where context_id = :object_id
    ), :user_id, 'admin')

  </querytext>
</fullquery>
 
</queryset>
