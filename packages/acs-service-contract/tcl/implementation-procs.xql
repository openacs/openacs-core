<?xml version="1.0"?>

<queryset>

  <fullquery name="acs_sc::impl::get_id.select_impl_id">
    <querytext>
        select impl_id
        from   acs_sc_impls
        where  impl_owner_name = :owner
        and    impl_name = :name
    </querytext>
  </fullquery>

  <fullquery name="acs_sc::impl::get_id.select_impl_id_with_contract">
    <querytext>
        select impl_id
        from   acs_sc_impls
        where  impl_owner_name = :owner
        and    impl_name = :name
        and    impl_contract_name = :contract
    </querytext>
  </fullquery>
  
  <fullquery name="acs_sc::impl::get.select_impl">
    <querytext>
        select impl_name,
               impl_pretty_name,
               impl_owner_name, 
               impl_contract_name
        from   acs_sc_impls
        where  impl_id = :impl_id
    </querytext>
  </fullquery>

</queryset>
