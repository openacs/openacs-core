<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="root_of_host.root_get">      
      <querytext>
      
	select site_node.url(:node_id) as url
	from dual

      </querytext>
</fullquery>

</queryset>

