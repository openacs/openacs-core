<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="grant_admin">
<querytext>
select acs_permission__grant_permission(
	acs__magic_object_id('security_context_root'), 
	:user_id, 
	'admin')
</querytext>
</fullquery>

<fullquery name="revoke_admin">
<querytext>
select acs_permission__revoke_permission(
        acs__magic_object_id('security_context_root'),
        :user_id,
        'admin')
</querytext>
</fullquery>

</queryset>
