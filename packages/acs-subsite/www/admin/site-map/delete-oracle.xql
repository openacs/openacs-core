<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="node_delete">      
      <querytext>
      
    begin
      site_node.delete(:node_id);
    end;
  
      </querytext>
</fullquery>

 
</queryset>
