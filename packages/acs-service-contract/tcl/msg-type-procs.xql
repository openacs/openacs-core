<?xml version="1.0"?>

<queryset>

  <fullquery name="acs_sc::msg_type::delete.select_name">
    <querytext>
        select msg_type_name as name
        from   acs_sc_msg_types 
        where  msg_type_id = :msg_type_id
    </querytext>
  </fullquery>
  
</queryset>
