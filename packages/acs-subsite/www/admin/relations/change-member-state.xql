<?xml version="1.0"?>
<queryset>

<fullquery name="update_member_state">      
      <querytext>
      
    update membership_rels
    set member_state = :member_state
    where rel_id = :rel_id

      </querytext>
</fullquery>

 
</queryset>
