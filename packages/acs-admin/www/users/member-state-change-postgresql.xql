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

 
<fullquery name="member_approve">      
      <querytext>
          select membership_rel__approve(:rel_id)
      </querytext>
</fullquery>

 
<fullquery name="member_ban">      
      <querytext>
          select membership_rel__ban(:rel_id)
      </querytext>
</fullquery>

 
<fullquery name="member_reject">      
      <querytext>
          select membership_rel__reject(:rel_id)
      </querytext>
</fullquery>

 
<fullquery name="member_deleted">      
      <querytext>
          select membership_rel__deleted(:rel_id)
      </querytext>
</fullquery>

 
<fullquery name="member_unapprove">      
      <querytext>
          select membership_rel__unapprove(:rel_id)
      </querytext>
</fullquery>

 
<fullquery name="approve_email">      
      <querytext>
          select acs_user__approve_email (:user_id)
      </querytext>
</fullquery>

 
<fullquery name="unapprove_email">      
      <querytext>
          select acs_user__unapprove_email (:user_id)
      </querytext>
</fullquery>

 
</queryset>
