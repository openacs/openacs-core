update acs_objects
set title = (select msg_type_name
             from acs_sc_msg_types
             where msg_type_id = object_id)
where object_type = 'acs_sc_msg_type';

update acs_objects
set title = (select contract_name
             from acs_sc_contracts
             where contract_id = object_id)
where object_type = 'acs_sc_contract';

update acs_objects
set title = (select operation_name
             from acs_sc_operations
             where operation_id = object_id)
where object_type = 'acs_sc_operation';

update acs_objects
set title = (select impl_pretty_name
             from acs_sc_impls
             where impl_id = object_id)
where object_type = 'acs_sc_implementation';



drop function acs_sc_msg_type__new(varchar,varchar);



-- added
select define_function_args('acs_sc_msg_type__new','msg_type_name,msg_type_spec');

--
-- procedure acs_sc_msg_type__new/2
--
CREATE OR REPLACE FUNCTION acs_sc_msg_type__new(
   p_msg_type_name varchar,
   p_msg_type_spec varchar
) RETURNS integer AS $$
DECLARE
    v_msg_type_id               integer;
BEGIN

    v_msg_type_id := acs_object__new(
                null,
                'acs_sc_msg_type',
                now(),
                null,
                null,
                null,
                't',
                p_msg_type_name,
                null
            );

    insert into acs_sc_msg_types (
        msg_type_id,
        msg_type_name
   ) values (
        v_msg_type_id,
        p_msg_type_name
    );

    perform acs_sc_msg_type__parse_spec(p_msg_type_name,p_msg_type_spec);

    return v_msg_type_id;

END;
$$ LANGUAGE plpgsql;



drop function acs_sc_contract__new(varchar,text);



-- added
select define_function_args('acs_sc_contract__new','contract_name,contract_desc');

--
-- procedure acs_sc_contract__new/2
--
CREATE OR REPLACE FUNCTION acs_sc_contract__new(
   p_contract_name varchar,
   p_contract_desc text
) RETURNS integer AS $$
DECLARE
    v_contract_id               integer;
BEGIN

    v_contract_id := acs_object__new(
                null,
                'acs_sc_contract',
                now(),
                null,
                null,
                null,
                't',
                p_contract_name,
                null
            );

    insert into acs_sc_contracts (
        contract_id,
        contract_name,
        contract_desc
    ) values (
        v_contract_id,
        p_contract_name,
        p_contract_desc
    );

    return v_contract_id;

END;
$$ LANGUAGE plpgsql;



drop function acs_sc_operation__new(varchar,varchar,text,boolean,integer,varchar,varchar);



-- added
select define_function_args('acs_sc_operation__new','contract_name,operation_name,operation_desc,operation_iscachable_p,operation_nargs,operation_inputtype,operation_outputtype');

--
-- procedure acs_sc_operation__new/7
--
CREATE OR REPLACE FUNCTION acs_sc_operation__new(
   p_contract_name varchar,
   p_operation_name varchar,
   p_operation_desc text,
   p_operation_iscachable_p boolean,
   p_operation_nargs integer,
   p_operation_inputtype varchar,
   p_operation_outputtype varchar
) RETURNS integer AS $$
DECLARE
    v_contract_id               integer;
    v_operation_id              integer;
    v_operation_inputtype_id    integer;
    v_operation_outputtype_id   integer;
BEGIN

    v_contract_id := acs_sc_contract__get_id(p_contract_name);

    v_operation_id := acs_object__new(
                         null,
                         'acs_sc_operation',
                         now(),
                         null,
                         null,
                         null,
                         't',
                         p_operation_name,
                         null
                     );

     v_operation_inputtype_id := acs_sc_msg_type__get_id(p_operation_inputtype);

     v_operation_outputtype_id := acs_sc_msg_type__get_id(p_operation_outputtype);

    insert into acs_sc_operations (
        contract_id,
        operation_id,
        contract_name,
        operation_name,
        operation_desc,
        operation_iscachable_p,
        operation_nargs,
        operation_inputtype_id,
        operation_outputtype_id
    ) values (
        v_contract_id,
        v_operation_id,
        p_contract_name,
        p_operation_name,
        p_operation_desc,
        p_operation_iscachable_p,
        p_operation_nargs,
        v_operation_inputtype_id,
        v_operation_outputtype_id
    );

    return v_operation_id;

END;
$$ LANGUAGE plpgsql;



drop function acs_sc_impl__new(varchar,varchar,varchar,varchar);



-- added
select define_function_args('acs_sc_impl__new','impl_contract_name,impl_name,impl_pretty_name,impl_owner_name');

--
-- procedure acs_sc_impl__new/4
--
CREATE OR REPLACE FUNCTION acs_sc_impl__new(
   p_impl_contract_name varchar,
   p_impl_name varchar,
   p_impl_pretty_name varchar,
   p_impl_owner_name varchar
) RETURNS integer AS $$
DECLARE
    v_impl_id                   integer;
BEGIN

    v_impl_id := acs_object__new(
                null,
                'acs_sc_implementation',
                now(),
                null,
                null,
                null,
                't',
                p_impl_pretty_name,
                null
            );

    insert into acs_sc_impls (
        impl_id,
        impl_name,
        impl_pretty_name,
        impl_owner_name,
        impl_contract_name
    ) values (
        v_impl_id,
        p_impl_name,
        p_impl_pretty_name,
        p_impl_owner_name,
        p_impl_contract_name
    );

    return v_impl_id;

END;
$$ LANGUAGE plpgsql;
