<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

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
