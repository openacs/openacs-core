<?xml version="1.0"?>

<queryset>

<fullquery name="notification::interval::get_id_from_name.get_interval_id">
  <querytext>
     select interval_id
     from notification_intervals where name = :name
  </querytext>
</fullquery>

</queryset>
