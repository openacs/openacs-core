
--
-- A service contract for allowing packages to be notified of changes in user information
--
-- The operations defined here are
--     UserData.UserNew
--     UserData.UserApprove
--     UserData.UserDeapprove
--     UserData.UserDelete
--     UserData.UserModify
--
-- ben@openforce
-- Jan 22, 2002

declare
    foo	integer;
begin
    foo :=  acs_sc_contract.new(
	    contract_name => 'UserData',
	    contract_desc => 'User Data Updates'
	    );

    -- The UserNew operation            

    foo := acs_sc_msg_type.new(
	    msg_type_name => 'UserData.UserNew.InputType',
	    msg_type_spec => 'user_id:integer'
	    );

    foo := acs_sc_msg_type.new(
	    msg_type_name => 'UserData.UserNew.OutputType',
	    msg_type_spec => ''
	    );
 
    foo := acs_sc_operation.new(
	    contract_name => 'UserData',
	    operation_name => 'UserNew',
	    operation_desc => 'Notify that a new user has been created',
	    operation_iscachable_p => 'f',
	    operation_nargs => 1,
	    operation_inputtype => 'UserData.UserNew.InputType',
	    operation_outputtype => 'UserData.UserNew.OutputType'
    );


    -- The UserApprove operation            

    foo := acs_sc_msg_type.new(
	    msg_type_name => 'UserData.UserApprove.InputType',
	    msg_type_spec => 'user_id:integer'
	    );

    foo := acs_sc_msg_type.new(
	    msg_type_name => 'UserData.UserApprove.OutputType',
	    msg_type_spec => ''
	    );
 
    foo := acs_sc_operation.new(
	    contract_name => 'UserData',
	    operation_name => 'UserApprove',
	    operation_desc => 'Notify that a user has been approved',
	    operation_iscachable_p => 'f',
	    operation_nargs => 1,
	    operation_inputtype => 'UserData.UserApprove.InputType',
	    operation_outputtype => 'UserData.UserApprove.OutputType'
    );


    -- The UserDeapprove operation            

    foo := acs_sc_msg_type.new(
	    msg_type_name => 'UserData.UserDeapprove.InputType',
	    msg_type_spec => 'user_id:integer'
	    );

    foo := acs_sc_msg_type.new(
	    msg_type_name => 'UserData.UserDeapprove.OutputType',
	    msg_type_spec => ''
	    );
 
    foo := acs_sc_operation.new(
	    contract_name => 'UserData',
	    operation_name => 'UserDeapprove',
	    operation_desc => 'Notify that a user has been deapproved',
	    operation_iscachable_p => 'f',
	    operation_nargs => 1,
	    operation_inputtype => 'UserData.UserDeapprove.InputType',
	    operation_outputtype => 'UserData.UserDeapprove.OutputType'
    );


    -- The UserModify operation            

    foo := acs_sc_msg_type.new(
	    msg_type_name => 'UserData.UserModify.InputType',
	    msg_type_spec => 'user_id:integer'
	    );

    foo := acs_sc_msg_type.new(
	    msg_type_name => 'UserData.UserModify.OutputType',
	    msg_type_spec => ''
	    );
 
    foo := acs_sc_operation.new(
	    contract_name => 'UserData',
	    operation_name => 'UserModify',
	    operation_desc => 'Notify that a user has been modified',
	    operation_iscachable_p => 'f',
	    operation_nargs => 1,
	    operation_inputtype => 'UserData.UserModify.InputType',
	    operation_outputtype => 'UserData.UserModify.OutputType'
    );



    -- The UserDelete operation            

    foo := acs_sc_msg_type.new(
	    msg_type_name => 'UserData.UserDelete.InputType',
	    msg_type_spec => 'user_id:integer'
	    );

    foo := acs_sc_msg_type.new(
	    msg_type_name => 'UserData.UserDelete.OutputType',
	    msg_type_spec => ''
	    );
 
    foo := acs_sc_operation.new (
	    contract_name => 'UserData',
	    operation_name => 'UserDelete',
	    operation_desc => 'Notify that a user has been deleted',
	    operation_iscachable_p => 'f',
	    operation_nargs => 1,
	    operation_inputtype => 'UserData.UserDelete.InputType',
	    operation_outputtype => 'UserData.UserDelete.OutputType'
    );




end;
/
show errors

