<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="register_email_user_info_get">      
      <querytext>
      
	select c.member_state,
	       c.email,
	       c.user_id,
	       c.email_verified_p
	  from users u, cc_users c
	 where u.user_id = c.user_id
	   and u.oid = :row_id

      </querytext>
</fullquery>

 
</queryset>
