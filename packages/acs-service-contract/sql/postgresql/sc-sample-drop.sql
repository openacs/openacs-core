select acs_sc_contract__delete('ObjectDisplay');

select acs_sc_msg_type__delete ('ObjectDisplay.Name.InputType');
select acs_sc_msg_type__delete ('ObjectDisplay.Name.OutputType');

select acs_sc_msg_type__delete ('ObjectDisplay.Url.InputType');
select acs_sc_msg_type__delete ('ObjectDisplay.Url.OutputType');


select acs_sc_msg_type__delete ('ObjectDisplay.SampleHello.InputType');
select acs_sc_msg_type__delete ('ObjectDisplay.SampleHello.OutputType');

select acs_sc_impl__delete(
           'ObjectDisplay',			-- impl_contract_name
	   'bboard_message'			-- impl_name
);
