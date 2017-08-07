<?xml version="1.0"?>
<queryset>

<fullquery name="ad_acs_kernel_id_mem.acs_kernel_id_get">      
      <querytext>
      
	select package_id from apm_packages
	where package_key = 'acs-kernel'
    
      </querytext>
</fullquery>

<fullquery name="rp_lookup_node_from_host.node_id">
      <querytext>

        select node_id 
	from host_node_map
	where host = :host

      </querytext>
</fullquery>

 
</queryset>
