<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="grant_admin">
<querytext>
select acs_permission.grant_permission(
	acs.magic_object_id('security_context_root'), 
	:user_id, 
	'admin')
</querytext>
</fullquery>

<fullquery name="revoke_admin">
<querytext>
select acs_permission.revoke_permission(
        acs.magic_object_id('security_context_root'),
        :user_id,
        'admin')
</querytext>
</fullquery>

</queryset>
