<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="dbqd.acs-subsite.www.admin.site-map.package-new.new_doubleclick_ck">
  <querytext>
	select case when count(*) = 0 then 0 else 1 end 
 	from apm_packages
	where package_id = :new_package_id
  </querytext>
</fullquery>

</queryset>
