<?xml version="1.0"?>
<queryset>

<fullquery name="db_types_exists">
<querytext>
	select case when count(*) = 0 then 0 else 1 end
	from apm_package_db_types
</querytext>
</fullquery>

<fullquery name="insert_apm_db_type">
<querytext>
	insert into apm_package_db_types
		(db_type_key, pretty_db_name)
	values
		(:db_type, :db_pretty_name)
</querytext>
</fullquery>

<fullquery name="all_unmounted_package_key">
<querytext>
	select t.package_key
	from apm_package_types t
	    left join apm_packages p
	    using (package_key)
	where p.package_id is null
</querytext>
</fullquery>

<fullquery name="main_site_id_select">
<querytext>
	select package_id
	from apm_packages
	where instance_name = 'Main Site' 
</querytext>
</fullquery>

</queryset>
