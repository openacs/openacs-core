<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.7</version></rdbms>

  <fullquery name="acs_sc::msg_type::new.insert_msg_type">
    <querytext>
        select acs_sc_msg_type.new(
            :name, 
            :specification
        ) from dual
    </querytext>
  </fullquery>

  <fullquery name="acs_sc::msg_type::delete.delete_by_id">
    <querytext>
        select acs_sc_msg_type.delete(
            :msg_type_id
        ) from dual
    </querytext>
  </fullquery>
  
  <fullquery name="acs_sc::msg_type::delete.delete_by_name">
    <querytext>
        select acs_sc_msg_type.delete(
            :name
        ) from dual
    </querytext>
  </fullquery>

</queryset>



