<?xml version="1.0"?>

<queryset>


<fullquery name="acs_user_extension::list_extensions.select_extensions">
<querytext>
  select 
         impl_name from acs_sc_impls, acs_sc_bindings, acs_sc_contracts
   where
         acs_sc_impls.impl_id = acs_sc_bindings.impl_id 
     and
         acs_sc_contracts.contract_id = acs_sc_bindings.contract_id 
     and 
         acs_sc_contracts.contract_name = 'UserData'
</querytext>
</fullquery>


</queryset>
