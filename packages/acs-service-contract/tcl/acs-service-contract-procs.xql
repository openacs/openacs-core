<?xml version="1.0"?>

<queryset>

  <fullquery name="acs_sc_proc.operation_msgtype_element">
    <querytext>
	select 
	    element_name, 
            (select msg_type_name from acs_sc_msg_types
              where msg_type_id = element_msg_type_id) as element_msg_type_name,
	    element_msg_type_isset_p,
	    element_pos
	from acs_sc_msg_type_elements
	where msg_type_id = :msg_type_id
	order by element_pos asc        
    </querytext>
  </fullquery>

</queryset>
