<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_states">      
      <querytext>
      select email_verified_p as email_verified_p_old,
          member_state as member_state_old,
          first_names || ' ' || last_name as name,
          email, rel_id, oid as rowid
      from cc_users
      where user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
