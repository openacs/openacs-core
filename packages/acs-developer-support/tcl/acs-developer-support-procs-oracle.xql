<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="ds_instance_id.acs_kernel_id_get">      
      <querytext>
      
	select package_id from apm_packages
	where package_key = 'acs-developer-support'
	and rownum=1
    
      </querytext>
</fullquery>

 
<fullquery name="ds_require_permission.name">      
      <querytext>
      select acs_object.name(:object_id) from dual
      </querytext>
</fullquery>

 
<fullquery name="ds_support_url.ds_support_url">      
      <querytext>
      
	select site_node.url(node_id) 
	from site_nodes s, apm_packages p
	where p.package_id = s.object_id
	and p.package_key ='acs-developer-support'
	and rownum = 1
    
      </querytext>
</fullquery>

 
<fullquery name="ds_user_select_widget.users">      
      <querytext>
       
	select u.user_id as user_id_from_db, 
	       acs_object.name(user_id) as name, 
	       p.email 
	from   users u, 
	       parties p 
	where  u.user_id = p.party_id 
    
      </querytext>
</fullquery>

 
</queryset>
