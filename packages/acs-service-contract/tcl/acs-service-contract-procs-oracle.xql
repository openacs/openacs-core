<?xml version="1.0"?>

<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>


<fullquery name="acs_sc_binding_exists_p.binding_exists_p">
<querytext>
select acs_sc_binding.exists_p(:contract,:impl) from dual
</querytext>
</fullquery>

<fullquery name="acs_sc_proc.operation_inputtype_element">
<querytext>
	select 
	    element_name, 
	    acs_sc_msg_type.get_name(element_msg_type_id) as element_msg_type_name,
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
	    acs_sc_msg_type.get_name(element_msg_type_id) as element_msg_type_name,
	    element_msg_type_isset_p,
	    element_pos
	from acs_sc_msg_type_elements
	where msg_type_id = :operation_outputtype_id
	order by element_pos asc
</querytext>
</fullquery>


</queryset>
