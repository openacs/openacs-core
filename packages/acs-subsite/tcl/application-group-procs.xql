<?xml version="1.0"?>
<queryset>

<fullquery name="application_group::new.group_name_query">      
      <querytext>
      
		select substr(instance_name, 1, 90)
		from apm_packages
		where package_id = :package_id
	    
      </querytext>
</fullquery>

<fullquery name="application_group::delete.delete_perms">      
      <querytext>
    
            delete from acs_permissions
            where  grantee_id = :group_id
            or     grantee_id in (select segment_id from rel_segments where group_id = :group_id)
            or     grantee_id in (select rel_id from acs_rels where object_id_one = :group_id or object_id_two = :group_id)

      </querytext>
</fullquery>
 
</queryset>
