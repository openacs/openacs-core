begin

   acs_sc_impl.del(
           'ObjectDisplay',			-- impl_contract_name
	   'bboard_message'			-- impl_name
   );

   acs_sc_contract.del(contract_name=>'ObjectDisplay',
			  operation_name=>'name');

   acs_sc_msg_type.del ('ObjectDisplay.Name.InputType');
   acs_sc_msg_type.del ('ObjectDisplay.Name.OutputType');

   acs_sc_msg_type.del ('ObjectDisplay.Url.InputType');
   acs_sc_msg_type.del ('ObjectDisplay.Url.OutputType');

   acs_sc_msg_type.del ('ObjectDisplay.SampleHello.InputType');
   acs_sc_msg_type.del ('ObjectDisplay.SampleHello.OutputType');



end;
/
show errors
