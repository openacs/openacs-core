<?xml version="1.0"?>
<queryset>

<fullquery name="register_member_state_information">      
      <querytext>
      select member_state, email, email_verified_p, rel_id
from cc_users where user_id = :user_id 
and  (member_state is null or member_state = 'rejected')
      </querytext>
</fullquery>

 
<fullquery name="register_member_state_authorized_set">      
      <querytext>
      update membership_rels set member_state = 'approved' where rel_id = :rel_id
      </querytext>
</fullquery>

 
</queryset>
