<?xml version="1.0"?>
<queryset>

<fullquery name="select_privileges_hierarchy">      
      <querytext>
          select privilege, child_privilege
          from acs_privilege_hierarchy
          order by privilege desc, child_privilege desc
      </querytext>
</fullquery>

<fullquery name="select_privileges_list">      
      <querytext>
      
  select privilege
  from acs_privileges
  order by privilege

      </querytext>
</fullquery>

 
</queryset>
