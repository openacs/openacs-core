<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="valid_installed_binding">      
      <querytext>
        select q.* 
        from (select 
                  b.contract_id,
                  b.impl_id,
                  acs_sc_contract.get_name(contract_id) as contract_name,
                  acs_sc_impl.get_name(b.impl_id) as impl_name,
                  impl.impl_owner_name,
                  impl.impl_pretty_name
              from
                  acs_sc_bindings b, 
                  acs_sc_impls impl
              where
                  impl.impl_id = b.impl_id) q
        order  by upper(contract_name), contract_name, upper(impl_name), impl_name
      </querytext>
</fullquery>

 
</queryset>
