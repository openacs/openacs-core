<?xml version="1.0"?>

<queryset>

    <fullquery name="ad_permission_p.n_privs">      
        <querytext>
            select count(*)
            from acs_privileges
            where privilege = :privilege
        </querytext>
    </fullquery>

    <fullquery name="permission::inherit_p.select_inherit_p">
        <querytext>
            select case when security_inherit_p = 't' then 1 else 0 end
            from acs_objects
            where object_id = :object_id
        </querytext>
    </fullquery>
 
    <fullquery name="permission::set_inherit.set_inherit">
        <querytext>
            update acs_objects
            set security_inherit_p = 't'
            where object_id = :object_id
        </querytext>
    </fullquery>
 
    <fullquery name="permission::set_not_inherit.set_not_inherit">
        <querytext>
            update acs_objects
            set security_inherit_p = 'f'
            where object_id = :object_id
        </querytext>
    </fullquery>
 
    <fullquery name="permission::permission_p_not_cached.select_permission_p">
        <querytext>
		select 1 from dual
		where exists
	        	( select 1
                	from acs_object_party_privilege_map ppm
	  		where ppm.object_id = :object_id and ppm.party_id = :party_id and ppm.privilege = :privilege )
        </querytext>
    </fullquery>

</queryset>
