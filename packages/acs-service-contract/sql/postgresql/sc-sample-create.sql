-- CREATE CONTRACT

select acs_sc_contract__new (
           'ObjectDisplay',			-- contract_name
	   'Object display'			-- contract_desc
);


select acs_sc_msg_type__new ('ObjectDisplay.Name.InputType','object_id:integer');
select acs_sc_msg_type__new ('ObjectDisplay.Name.OutputType','object_name:string');

select acs_sc_operation__new (
           'ObjectDisplay',			-- contract_name
           'name',				-- operation_name
	   'Returns object''s name',		-- operation_desc
	   'f',					-- operation_iscachable_p
	   1,					-- operation_nargs
	   'ObjectDisplay.Name.InputType',	-- operation_inputtype
	   'ObjectDisplay.Name.OutputType'	-- operation_outputtype
);


select acs_sc_msg_type__new ('ObjectDisplay.Url.InputType','object_id:integer');
select acs_sc_msg_type__new ('ObjectDisplay.Url.OutputType','object_url:uri');

select acs_sc_operation__new (
           'ObjectDisplay',			-- contract_name
           'url',				-- operation_name
	   'Returns object''s url',		-- operation_desc
	   'f',					-- operation_iscachable_p
	   1,					-- operation_nargs
	   'ObjectDisplay.Url.InputType',		-- operation_inputtype
	   'ObjectDisplay.Url.OutputType'		-- operation_outputtype
);

select acs_sc_msg_type__new ('ObjectDisplay.SampleHello.InputType','object_id:integer,object_txt:string');
select acs_sc_msg_type__new ('ObjectDisplay.SampleHello.OutputType','object_sample:string[],xxx_p:boolean');

select acs_sc_operation__new (
           'ObjectDisplay',			-- contract_name
           'sample_hello',			-- operation_name
	   'Returns object''s url',		-- operation_desc
	   't',					-- operation_iscachable_p
	   1,					-- operation_nargs
	   'ObjectDisplay.SampleHello.InputType',		-- operation_inputtype
	   'ObjectDisplay.SampleHello.OutputType'		-- operation_outputtype
);



-- CREATE IMPLEMENTATION


select acs_sc_impl__new(
	   'ObjectDisplay',			-- impl_contract_name
           'bboard_message',			-- impl_name
	   'bboard'				-- impl_owner_name
);


select acs_sc_impl_alias__new(
           'ObjectDisplay',			-- impl_contract_name
           'bboard_message',			-- impl_name
	   'name',				-- impl_operation_name
	   'bboard_message__name',		-- impl_alias
	   'PLPGSQL'				-- impl_pl
);

select acs_sc_impl_alias__new(
           'ObjectDisplay',			-- impl_contract_name
           'bboard_message',			-- impl_name
	   'url',				-- impl_operation_name
	   'bboard_message__url',		-- impl_alias
	   'PLPGSQL'				-- impl_pl
);

select acs_sc_impl_alias__new(
           'ObjectDisplay',			-- impl_contract_name
           'bboard_message',			-- impl_name
	   'sample_hello',			-- impl_operation_name
	   'bboard_message__sample_hello',	-- impl_alias
	   'TCL'				-- impl_pl
);




