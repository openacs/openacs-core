<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="get_states">      
      <querytext>
      select email_verified_p email_verified_p_old, member_state member_state_old, first_names || ' ' || last_name as name, email, rel_id, rowid
from cc_users
where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
