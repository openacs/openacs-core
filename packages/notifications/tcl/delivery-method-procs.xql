<?xml version="1.0"?>

<queryset>

  <fullquery name="notification::delivery::get_impl_key.select_impl_key">
    <querytext>
      select impl_name from acs_sc_impls, notification_delivery_methods
      where acs_sc_impls.impl_id = notification_delivery_methods.sc_impl_id
      and delivery_method_id= :delivery_method_id
    </querytext>
  </fullquery>

  <fullquery name="notification::delivery::get_id.select_delivery_method_id">
    <querytext>
      select delivery_method_id
      from   notification_delivery_methods
      where  short_name = :short_name
    </querytext>
  </fullquery>

  <fullquery name="notification::delivery::update_sc_impl_id.update">
    <querytext>
      update notification_delivery_methods
      set    sc_impl_id = :sc_impl_id
      where  delivery_method_id = :delivery_method_id
    </querytext>
  </fullquery>

</queryset>
