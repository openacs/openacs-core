<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="register_user_state_properties">      
      <querytext>
      
    select member_state, email, rowid 
    from cc_users
    where user_id = :user_id and
    email_verified_p = 'f' 
      </querytext>
</fullquery>

 
</queryset>
