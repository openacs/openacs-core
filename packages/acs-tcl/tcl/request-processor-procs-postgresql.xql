<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="root_of_host.root_get">      
      <querytext>
      
	select site_node__url(:node_id) as url
    
      </querytext>
</fullquery>

</queryset>