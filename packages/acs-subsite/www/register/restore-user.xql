<?xml version="1.0"?>
<queryset>

<fullquery name="user_state_info">      
      <querytext>
      
    select member_state, email, rel_id from cc_users where user_id = :user_id

      </querytext>
</fullquery>

 
<fullquery name="member_state_authorized_transistion">      
      <querytext>
      
	update membership_rels
	set member_state = 'approved'  
	where rel_id = :rel_id
    
      </querytext>
</fullquery>

 
</queryset>
