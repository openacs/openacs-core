<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="dbqd.acs-subsite.www.admin.site-map.auto-mount.select_node_url">
  <querytext>
	select site_node__url(s.node_id) as return_url
	  from site_nodes s, apm_packages p
	 where s.object_id = p.package_id
	   and s.node_id = :node_id    
  </querytext>
</fullquery>

</queryset>
