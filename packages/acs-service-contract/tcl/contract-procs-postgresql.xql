<?xml version="1.0"?>

<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <fullquery name="acs_sc::contract::new.insert_sc_contract">
    <querytext>
        select acs_sc_contract__new(
            :name, 
            :description
        ); 	
    </querytext>
  </fullquery>

  <fullquery name="acs_sc::contract::operation::new.insert_operation">
    <querytext>
        select acs_sc_operation__new(
            :contract_name,
            :operation, 
            :description, 
            :is_cachable_p, 
            :nargs, 
            :input_type_name, 
            :output_type_name
        ); 	
    </querytext>
  </fullquery>

</queryset>

