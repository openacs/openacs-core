<?xml version="1.0"?>
<queryset>

<fullquery name="group_info">      
      <querytext>
      
    select g.group_name, g.join_policy
      from groups g
     where g.group_id = :group_id

      </querytext>
</fullquery>

 
</queryset>
