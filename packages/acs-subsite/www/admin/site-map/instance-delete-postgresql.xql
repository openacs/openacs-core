<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="dbqd.acs-subsite.www.admin.site-map.instance-delete.package_mounted_p">
  <querytext>
	    select case when count(*) = 0 then 0 else 1 end
	    from apm_packages p, site_nodes s
	    where package_id = :package_id
	    and p.package_id = s.object_id
  </querytext>
</fullquery>

<fullquery name="dbqd.acs-subsite.www.admin.site-map.instance-delete.package_instance_delete">
  <querytext>
	select apm_package__delete(:package_id)
  </querytext>
</fullquery>

<fullquery name="dbqd.acs-subsite.www.admin.site-map.instance-delete.instance_delete_doubleclick_ck">
  <querytext>
	select case when count(*) = 0 then 0 else 1 end from apm_packages
	where package_id = :package_id
  </querytext>
</fullquery>

</queryset>
