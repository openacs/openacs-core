<?xml version="1.0"?>

<queryset>
  <rdbms><type>oracle</type><version>8.1.7</version></rdbms>

  <fullquery name="acs_sc::contract::new.insert_sc_contract">
    <querytext>
        select acs_sc_contract.new(
            :name, 
            :description
        ) from dual	
    </querytext>
  </fullquery>
  
  <fullquery name="acs_sc::contract::delete.get_name_by_id">
    <querytext>
        select acs_sc_contract.get_name(
            :contract_id
        ) from dual 	
    </querytext>
  </fullquery>
  
  <fullquery name="acs_sc::contract::delete.get_id_by_name">
    <querytext>
        select acs_sc_contract.get_id(
            :name
        ) from dual 	
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
        select acs_sc_contract.delete(
            :name
        ) from dual 	
    </querytext>
  </fullquery>
  
  <fullquery name="acs_sc::contract::operation::new.insert_operation">
    <querytext>
        select acs_sc_operation.new(
            :contract_name,
            :operation, 
            :description, 
            :is_cachable_p, 
            :nargs, 
            :input_type_name, 
            :output_type_name
        ) from dual 	
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
        select acs_sc_operation.delete(
            :contract_name, 
            :operation_name
        ) from dual
    </querytext>
  </fullquery>
  
</queryset>

