<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="valid_installed_binding">      
      <querytext>
        select 
            contract_id,
            impl_id,
            acs_sc_contract__get_name(contract_id) as contract_name,
            acs_sc_impl__get_name(impl_id) as impl_name
        from
            acs_sc_bindings
      </querytext>
</fullquery>
 
</queryset>

