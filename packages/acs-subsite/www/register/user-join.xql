<?xml version="1.0"?>
<queryset>

<fullquery name="group_info">      
      <querytext>
      
    select group_name, join_policy
    from groups
    where group_id = :group_id

      </querytext>
</fullquery>

 
</queryset>
