<?xml version="1.0"?>
<queryset>

<fullquery name="membership_rel::change_state.update_modifying_user">
      <querytext>
      
          update acs_objects set modifying_user = :user_id where object_id = :rel_id 
    
      </querytext>
</fullquery>


</queryset>
