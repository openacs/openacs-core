<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="register_user_state_properties">      
      <querytext>
      
     select mr.member_state, p.email, u.oid as row_id
     from users u
     JOIN parties p on (p.party_id = u.user_id)
     LEFT JOIN membership_rels mr on (mr.rel_id = u.user_id)
     where u.user_id = :user_id
     and u.email_verified_p = 'f'

      </querytext>
</fullquery>

 
</queryset>
