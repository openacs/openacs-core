<?xml version="1.0"?>
<queryset>

<fullquery name="security_inherit_p">      
      <querytext>
      
    select security_inherit_p
    from acs_objects
    where object_id = :object_id
  
      </querytext>
</fullquery>

 
<fullquery name="children_count">      
      <querytext>
      
	select count(*) as num_children
	from acs_objects o
	where context_id = :object_id
              and exists (select 1
                          from acs_object_party_privilege_map
                          where object_id = o.object_id
                          and party_id = :user_id
                          and privilege = 'admin')    
    
      </querytext>
</fullquery>

 
</queryset>
