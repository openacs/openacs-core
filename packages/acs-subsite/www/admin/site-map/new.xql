<?xml version="1.0"?>
<queryset>

<fullquery name="site_node_duplicate_name_root_ck">      
      <querytext>
      
          select case when count(*) = 0 then 0 else 1 end 
          from site_nodes
          where name = :name
          and parent_id = :parent_id
          and node_id <> :new_node_id
      
      </querytext>
</fullquery>

 
<fullquery name="site_node_new_doubleclick_protect">      
      <querytext>
      
        select case when count(*) = 0 then 0 else 1 end 
        from site_nodes
        where node_id = :new_node_id
    
      </querytext>
</fullquery>

 
</queryset>
