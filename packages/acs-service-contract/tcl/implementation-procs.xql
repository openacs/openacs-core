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

</queryset>
