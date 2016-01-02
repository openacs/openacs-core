<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="acs_sc::msg_type::new.insert_msg_type">
    <querytext>
        begin
            :1 := acs_sc_msg_type.new(
                :name, 
                :specification
            );
        end;
    </querytext>
  </fullquery>
  
  <fullquery name="acs_sc::msg_type::delete.delete_by_name">
    <querytext>
        begin
            acs_sc_msg_type.del(
                msg_type_name => :name
            );
        end;
    </querytext>
  </fullquery>

  <fullquery name="acs_sc::msg_type::element::new.insert_msg_type_element">
    <querytext>
        begin
            :1 := acs_sc_msg_type.new_element(
                :msg_type_name,
                :element_name,
                :element_msg_type_name,
                :element_msg_type_isset_p,
                :element_pos
            );
        end;
    </querytext>
  </fullquery>


</queryset>



