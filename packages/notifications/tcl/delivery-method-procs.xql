<?xml version="1.0"?>

<queryset>

<fullquery name="notification::delivery::get_impl_key.select_impl_key">
  <querytext>
    select impl_name from acs_sc_impls, notification_delivery_methods
    where acs_sc_impls.impl_id = notification_delivery_methods.sc_impl_id
      and delivery_method_id= :delivery_method_id
  </querytext>
</fullquery>


<fullquery name="notification::delivery::get_id_from_name.get_delivery_method_id">
  <querytext>
    select delivery_method_id
    from notification_delivery_methods where short_name = 'email'
  </querytext>
</fullquery>

</queryset>
