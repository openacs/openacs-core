<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="acs_sc::contract::new.insert_sc_contract">
    <querytext>
        begin
            :1 := acs_sc_contract.new(
                :name, 
                :description
            );
        end;
    </querytext>
  </fullquery>

  <fullquery name="acs_sc::contract::operation::new.insert_operation">
    <querytext>
        begin
            :1 := acs_sc_operation.new(
                :contract_name,
                :operation, 
                :description, 
                :is_cachable_p, 
                :nargs, 
                :input_type_name, 
                :output_type_name
            );
        end;
    </querytext>
  </fullquery>

</queryset>

