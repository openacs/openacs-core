<?xml version="1.0"?>
<queryset>

<fullquery name="update_join_policy">      
      <querytext>
      
    update groups
    set join_policy = :join_policy
    where group_id = :group_id

      </querytext>
</fullquery>

 
</queryset>
