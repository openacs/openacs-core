<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="node_new">      
      <querytext>
      
        begin
        :1 := site_node.new (
        node_id => :new_node_id,
        parent_id => :parent_id,
        name => :name,
        directory_p => :directory_p,
        pattern_p => :pattern_p,
        creation_user => :user_id,
        creation_ip => :ip_address
        );
        end;
    
      </querytext>
</fullquery>

 
</queryset>
