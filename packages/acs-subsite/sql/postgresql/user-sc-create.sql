
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
-- ported by dan chak (chak@openforce.net)
-- Jan 22, 2002

create function inline_0()
returns integer as '
declare
    foo	integer;
begin
    foo :=  acs_sc_contract__new(
	    ''UserData'',
	    ''User Data Updates''
	    );

    -- The UserNew operation            

    foo := acs_sc_msg_type__new(
	    ''UserData.UserNew.InputType'',
	    ''user_id:integer''
	    );

    foo := acs_sc_msg_type__new(
	    ''UserData.UserNew.OutputType'',
	    ''''
	    );
 
    foo := acs_sc_operation__new(
	    ''UserData'',
	    ''UserNew'',
	    ''Notify that a new user has been created'',
	    ''f'',
	    1,
	    ''UserData.UserNew.InputType'',
	    ''UserData.UserNew.OutputType''
    );


    -- The UserApprove operation            

    foo := acs_sc_msg_type__new(
	    ''UserData.UserApprove.InputType'',
	    ''user_id:integer''
	    );

    foo := acs_sc_msg_type__new(
	    ''UserData.UserApprove.OutputType'',
	    ''''
	    );
 
    foo := acs_sc_operation__new(
	    ''UserData'',
	    ''UserApprove'',
	    ''Notify that a user has been approved'',
	    ''f'',
	    1,
	    ''UserData.UserApprove.InputType'',
	    ''UserData.UserApprove.OutputType''
    );


    -- The UserDeapprove operation            

    foo := acs_sc_msg_type__new(
	    ''UserData.UserDeapprove.InputType'',
	    ''user_id:integer''
	    );

    foo := acs_sc_msg_type__new(
	    ''UserData.UserDeapprove.OutputType'',
	    ''''
	    );
 
    foo := acs_sc_operation__new(
	    ''UserData'',
	    ''UserDeapprove'',
	    ''Notify that a user has been deapproved'',
	    ''f'',
	    1,
	    ''UserData.UserDeapprove.InputType'',
	    ''UserData.UserDeapprove.OutputType''
    );


    -- The UserModify operation            

    foo := acs_sc_msg_type__new(
	    ''UserData.UserModify.InputType'',
	    ''user_id:integer''
	    );

    foo := acs_sc_msg_type__new(
	    ''UserData.UserModify.OutputType'',
	    ''''
	    );
 
    foo := acs_sc_operation__new(
	    ''UserData'',
	    ''UserModify'',
	    ''Notify that a user has been modified'',
	    ''f'',
	    1,
	    ''UserData.UserModify.InputType'',
	    ''UserData.UserModify.OutputType''
    );



    -- The UserDelete operation            

    foo := acs_sc_msg_type__new(
	    ''UserData.UserDelete.InputType'',
	    ''user_id:integer''
	    );

    foo := acs_sc_msg_type__new(
	    ''UserData.UserDelete.OutputType'',
	    ''''
	    );

    foo := acs_sc_operation__new (
	    ''UserData'',
	    ''UserDelete'',
	    ''Notify that a user has been deleted'',
	    ''f'',
	    1,
	    ''UserData.UserDelete.InputType'',
	    ''UserData.UserDelete.OutputType''
    );

    return 0;

end;' language 'plpgsql';

select inline_0();
drop function inline_0();
