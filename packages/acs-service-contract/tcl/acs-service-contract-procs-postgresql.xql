<?xml version="1.0"?>

<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="acs_sc_binding_exists_p.binding_exists_p">
<querytext>
select acs_sc_binding__exists_p(:contract,:impl)
</querytext>
</fullquery>

<fullquery name="acs_sc_get_alias.get_alias">
<querytext>
   select impl_alias, impl_pl 	 
         from   acs_sc_impl_aliases 	 
         where  impl_contract_name = :contract 	 
         and    impl_operation_name = :operation 	 
         and    impl_name = :impl
</querytext>
</fullquery>

<fullquery name="acs_sc_proc.get_operation_definition">
<querytext>
	select 
	    operation_desc,
            coalesce(operation_iscachable_p,'f') as operation_iscachable_p,
	    operation_nargs,
	    operation_inputtype_id,
	    operation_outputtype_id
	from acs_sc_operations
	where contract_name = :contract
	and operation_name = :operation
</querytext>
</fullquery>


<fullquery name="acs_sc_proc.operation_inputtype_element">
<querytext>
	select 
	    element_name, 
	    acs_sc_msg_type__get_name(element_msg_type_id) as element_msg_type_name,
	    element_msg_type_isset_p,
	    element_pos
	from acs_sc_msg_type_elements
	where msg_type_id = :operation_inputtype_id
	order by element_pos asc
</querytext>
</fullquery>

<fullquery name="acs_sc_proc.operation_outputtype_element">
<querytext>
	select 
	    element_name, 
	    acs_sc_msg_type__get_name(element_msg_type_id) as element_msg_type_name,
	    element_msg_type_isset_p,
	    element_pos
	from acs_sc_msg_type_elements
	where msg_type_id = :operation_outputtype_id
	order by element_pos asc
</querytext>
</fullquery>


</queryset>
