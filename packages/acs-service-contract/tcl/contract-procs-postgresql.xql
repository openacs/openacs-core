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
  
  <fullquery name="acs_sc::contract::delete.get_name_by_id">
    <querytext>
        select acs_sc_contract__get_name(:contract_id); 	
    </querytext>
  </fullquery>
  
  <fullquery name="acs_sc::contract::delete.get_id_by_name">
    <querytext>
        select acs_sc_contract__get_id(:name); 	
    </querytext>
  </fullquery>
  
  <fullquery name="acs_sc::contract::delete.select_operations">
    <querytext>
        select operation_id,
               operation_inputtype_id,
               operation_outputtype_id
        from   acs_sc_operations
        where  contract_id = :contract_id
    </querytext>
  </fullquery>
  
  <fullquery name="acs_sc::contract::delete.delete_by_name">
    <querytext>
        select acs_sc_contract__delete(:name); 	
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

  <fullquery name="acs_sc::contract::operation::delete.select_names">
    <querytext>
        select contract_name,
               operation_name
        from   acs_sc_operations
        where  operation_id = :operation_id
    </querytext>
  </fullquery>
  
  <fullquery name="acs_sc::contract::operation::delete.delete_by_name">
    <querytext>
        select acs_sc_operation__delete(:contract_name, :operation_name); 	
    </querytext>
  </fullquery>
  
</queryset>

