begin

   acs_sc_impl.delete(
           'ObjectDisplay',			-- impl_contract_name
	   'bboard_message'			-- impl_name
   );

   acs_sc_contract.delete(contract_name=>'ObjectDisplay',
			  operation_name=>'name');

   acs_sc_msg_type.delete ('ObjectDisplay.Name.InputType');
   acs_sc_msg_type.delete ('ObjectDisplay.Name.OutputType');

   acs_sc_msg_type.delete ('ObjectDisplay.Url.InputType');
   acs_sc_msg_type.delete ('ObjectDisplay.Url.OutputType');

   acs_sc_msg_type.delete ('ObjectDisplay.SampleHello.InputType');
   acs_sc_msg_type.delete ('ObjectDisplay.SampleHello.OutputType');



end;
/
show errors
