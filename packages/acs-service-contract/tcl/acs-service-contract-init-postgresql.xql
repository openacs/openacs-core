<?xml version="1.0"?>

<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="binding_exists_p">
<querytext>
select acs_sc_binding__exists_p(:impl_contract_name,:impl_name)
</querytext>
</fullquery>

</queryset>
