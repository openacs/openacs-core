<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="user_exists">
<querytext>
select email from cc_users limit 1
</querytext>
</fullquery>

</queryset>
