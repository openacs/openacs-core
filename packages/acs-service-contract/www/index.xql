<?xml version="1.0"?>

<queryset>

<fullquery name="valid_uninstalled_binding">      
   <querytext>
     select contract_id, contract_name, impl_name, impl_owner_name, impl_pretty_name, impl_id 
     from   valid_uninstalled_bindings
     order  by upper(contract_name), contract_name, upper(impl_name), impl_name
   </querytext>
</fullquery>

<fullquery name="invalid_uninstalled_binding">      
   <querytext>
      select contract_id, contract_name, impl_name, impl_owner_name, impl_pretty_name, impl_id 
      from   invalid_uninstalled_bindings
      order  by upper(contract_name), contract_name, upper(impl_name), impl_name
   </querytext>
</fullquery>

<fullquery name="orphan_implementation">      
   <querytext>
      select impl_id, impl_name, impl_pretty_name, impl_contract_name  
      from   orphan_implementations
      order  by upper(impl_name), impl_name
   </querytext>
</fullquery>
 
</queryset>

