<?xml version="1.0"?>

<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <fullquery name="acs_sc::msg_type::new.insert_msg_type">
    <querytext>
        select acs_sc_msg_type__new(
            :name, 
            :specification); 	
    </querytext>
  </fullquery>

  <fullquery name="acs_sc::msg_type::delete.delete_by_name">
    <querytext>
        select acs_sc_msg_type__delete(:name); 	
    </querytext>
  </fullquery>

  <fullquery name="acs_sc::msg_type::element::new.insert_msg_type_element">
    <querytext>
        select acs_sc_msg_type__new_element(
            :msg_type_name,
            :element_name,
            :element_msg_type_name,
            :element_msg_type_isset_p,
            :element_pos
        );
    </querytext>
  </fullquery>


</queryset>
