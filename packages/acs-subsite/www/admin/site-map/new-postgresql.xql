<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="dbqd.acs-subsite.www.admin.site-map.new.site_node_duplicate_name_root_ck">
  <querytext>
          select case when count(*) = 0 then 0 else 1 end 
          from site_nodes
          where name = :name
          and parent_id = :parent_id
          and node_id &lt;&gt; :new_node_id
      
  </querytext>
</fullquery>

<fullquery name="dbqd.acs-subsite.www.admin.site-map.new.node_new">
  <querytext>
        select site_node__new (
        :new_node_id,
        :parent_id,
        :name,
	null,
        :directory_p,
        :pattern_p,
        :user_id,
        :ip_address
        )
  </querytext>
</fullquery>

<fullquery name="dbqd.acs-subsite.www.admin.site-map.new.site_node_new_doubleclick_protect">
  <querytext>
        select case when count(*) = 0 then 0 else 1 end 
        from site_nodes
        where node_id = :new_node_id
  </querytext>
</fullquery>

</queryset>
