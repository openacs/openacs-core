<?xml version="1.0"?>

<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>


<fullquery name="binding_exists_p">
<querytext>
select acs_sc_binding.exists_p(:impl_contract_name,:impl_name) from dual
</querytext>
</fullquery>


</queryset>
