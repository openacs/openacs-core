<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="grant_admin">
<querytext>
acs_permission.grant_permission (object_id => acs.magic_object_id('security_context_root'),
				 grantee_id => :user_id,
				 privilege => 'admin'
				);
</querytext>
</fullquery>

<fullquery name="all_unmounted_package_key">
<querytext>
	select t.package_key 
	from apm_package_types t, apm_packages p
	where t.package_key = p.package_key(+) 
	and p.package_id is null
</querytext>
</fullquery>

</queryset>
