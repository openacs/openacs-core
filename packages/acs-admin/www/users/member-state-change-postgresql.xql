<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_states">      
      <querytext>
      select u.email_verified_p as email_verified_p_old,
          mr.member_state as member_state_old,
          per.first_names || ' ' || per.last_name as name,
          part.email, mr.rel_id
      from users u
      JOIN parties part on (part.party_id = u.user_id)
        JOIN persons per on (per.person_id = u.user_id)
      LEFT JOIN membership_rels mr on (mr.rel_id = u.user_id)
      where u.user_id = :user_id
      
      </querytext>
</fullquery>


<fullquery name="approve_email">
	<querytext>
	select acs_user__approve_email (:user_id);
	</querytext>
</fullquery>

<fullquery name="unapprove_email">
	<querytext>
	select acs_user__unapprove_email (:user_id);
	</querytext>
</fullquery>

</queryset>
