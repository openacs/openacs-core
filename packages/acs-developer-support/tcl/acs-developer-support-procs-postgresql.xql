<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="ds_instance_id.acs_kernel_id_get">
<querytext>
	select package_id from apm_packages
	where package_key = 'acs-developer-support'
	limit 1
</querytext>
</fullquery>

</queryset>
