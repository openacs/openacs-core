-- CREATE CONTRACT

declare
    sc_sample_test	integer;
begin
    sc_sample_test :=  acs_sc_contract.new(
	    contract_name => 'ObjectDisplay',
	    contract_desc => 'Object display'
	    );

    sc_sample_test := acs_sc_msg_type.new(
	    msg_type_name => 'ObjectDisplay.Name.InputType',
	    msg_type_spec => 'object_id:integer'
	    );
    sc_sample_test := acs_sc_msg_type.new(
	    msg_type_name => 'ObjectDisplay.Name.OutputType',
	    msg_type_spec => 'object_name:string'
	    );
 
    sc_sample_test := acs_sc_operation.new(
	    contract_name => 'ObjectDisplay',
	    operation_name => 'name',
	    operation_desc => 'Returns objects name',
	    operation_iscachable_p => 'f',
	    operation_nargs => 1,
	    operation_inputttype => 'ObjectDisplay.Name.InputType',
	    operation_ouputtype => 'ObjectDisplay.Name.OutputType'
    );


    sc_sample_test := acs_sc_msg_type.new('ObjectDisplay.Url.InputType','object_id:integer');
    sc_sample_test := acs_sc_msg_type.new('ObjectDisplay.Url.OutputType','object_url:uri');

    sc_sample_test := acs_sc_operation.new(
           'ObjectDisplay',			-- contract_name
           'url',				-- operation_name
	   'Returns object''s url',		-- operation_desc
	   'f',					-- operation_iscachable_p
	   1,					-- operation_nargs
	   'ObjectDisplay.Url.InputType',		-- operation_inputtype
	   'ObjectDisplay.Url.OutputType'		-- operation_outputtype
	   );


    sc_sample_test := acs_sc_msg_type.new ('ObjectDisplay.SampleHello.InputType',
					   'object_id:integer,object_txt:string');
    sc_sample_test := acs_sc_msg_type.new ('ObjectDisplay.SampleHello.OutputType',
			 'object_sample:string[],xxx_p:boolean');

    sc_sample_test := acs_sc_operation.new (
           'ObjectDisplay',			-- contract_name
           'sample_hello',			-- operation_name
	   'Returns object''s url',		-- operation_desc
	   't',					-- operation_iscachable_p
	   1,					-- operation_nargs
	   'ObjectDisplay.SampleHello.InputType',		-- operation_inputtype
	   'ObjectDisplay.SampleHello.OutputType'		-- operation_outputtype
    );



    -- CREATE IMPLEMENTATION


    sc_sample_test := acs_sc_impl.new(
	   'ObjectDisplay',			-- impl_contract_name
           'bboard_message',			-- impl_name
	   'bboard'				-- impl_owner_name
	   );


    sc_sample_test := acs_sc_impl.new_alias(
           'ObjectDisplay',			-- impl_contract_name
           'bboard_message',			-- impl_name
	   'name',				-- impl_operation_name
	   'bboard_message__name',		-- impl_alias
	   'PLPGSQL'				-- impl_pl
    );

    sc_sample_test := acs_sc_impl.new_alias(
           'ObjectDisplay',			-- impl_contract_name
           'bboard_message',			-- impl_name
	   'url',				-- impl_operation_name
	   'bboard_message__url',		-- impl_alias
	   'PLPGSQL'				-- impl_pl
    );

    sc_sample_test := acs_sc_impl.new_alias(
           'ObjectDisplay',			-- impl_contract_name
           'bboard_message',			-- impl_name
	   'sample_hello',			-- impl_operation_name
	   'bboard_message__sample_hello',	-- impl_alias
	   'TCL'				-- impl_pl
    );


end;
/
show errors

