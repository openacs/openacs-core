<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="valid_installed_binding">      
      <querytext>
        select 
            b.contract_id,
            b.impl_id,
            acs_sc_impl.get_name(b.impl_id) as impl_name,
            impl.impl_owner_name,
            impl.impl_pretty_name
        from
            acs_sc_bindings b, 
            acs_sc_impls impl
        where
            b.contract_id = :id
        and impl.impl_id = b.impl_id
      </querytext>
</fullquery>

 
</queryset>
