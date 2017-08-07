-- register function record
select define_function_args('acs_sc_contract__new','contract_name,contract_desc');
-- declare function


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


-- register function record
select define_function_args('acs_sc_contract__get_id','contract_name');
-- declare function


--
-- procedure acs_sc_contract__get_id/1
--
CREATE OR REPLACE FUNCTION acs_sc_contract__get_id(
   p_contract_name varchar
) RETURNS integer AS $$
DECLARE
    v_contract_id               integer;
BEGIN

    select contract_id into v_contract_id
    from acs_sc_contracts
    where contract_name = p_contract_name;

    return v_contract_id;

END;
$$ LANGUAGE plpgsql stable strict;


-- register function record
select define_function_args('acs_sc_contract__get_name','contract_id');
-- declare function


--
-- procedure acs_sc_contract__get_name/1
--
CREATE OR REPLACE FUNCTION acs_sc_contract__get_name(
   p_contract_id integer
) RETURNS varchar AS $$
DECLARE
    v_contract_name             varchar;
BEGIN

    select contract_name into v_contract_name
    from acs_sc_contracts
    where contract_id = p_contract_id;

    return v_contract_name;

END;
$$ LANGUAGE plpgsql stable strict;




--
-- procedure acs_sc_contract__delete/1
--
CREATE OR REPLACE FUNCTION acs_sc_contract__delete(
   p_contract_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

    delete from acs_sc_contracts
    where contract_id = p_contract_id;

    return 0;

END;
$$ LANGUAGE plpgsql;


-- register function record

-- old define_function_args('acs_sc_contract__delete','contract_name')
-- new
select define_function_args('acs_sc_contract__delete','contract_id');

-- declare function


--
-- procedure acs_sc_contract__delete/1
--
CREATE OR REPLACE FUNCTION acs_sc_contract__delete(
   p_contract_name varchar
) RETURNS integer AS $$
DECLARE
    v_contract_id               integer;
BEGIN

    v_contract_id := acs_sc_contract__get_id(p_contract_name);

    perform acs_sc_contract__delete(v_contract_id);

    return 0;

END;
$$ LANGUAGE plpgsql;


-- register function record
select define_function_args('acs_sc_operation__new','contract_name,operation_name,operation_desc,operation_iscachable_p;f,operation_nargs,operation_inputtype,operation_outputtype');
-- declare function


--
-- procedure acs_sc_operation__new/7
--
CREATE OR REPLACE FUNCTION acs_sc_operation__new(
   p_contract_name varchar,
   p_operation_name varchar,
   p_operation_desc text,
   p_operation_iscachable_p boolean, -- default 'f'
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


-- register function record
select define_function_args('acs_sc_operation__get_id','contract_name,operation_name');
-- declare function


--
-- procedure acs_sc_operation__get_id/2
--
CREATE OR REPLACE FUNCTION acs_sc_operation__get_id(
   p_contract_name varchar,
   p_operation_name varchar
) RETURNS integer AS $$
DECLARE
    v_operation_id               integer;
BEGIN

    select operation_id into v_operation_id
    from acs_sc_operations
    where contract_name = p_contract_name 
    and operation_name = p_operation_name;

    return v_operation_id;

END;
$$ LANGUAGE plpgsql stable strict;

-- register function record

-- old define_function_args('acs_sc_operation__delete','operation_id')
-- new
select define_function_args('acs_sc_operation__delete','contract_name,operation_name');

-- declare function


--
-- procedure acs_sc_operation__delete/1
--
CREATE OR REPLACE FUNCTION acs_sc_operation__delete(
   p_operation_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

    delete from acs_sc_operations
    where operation_id = p_operation_id;

    return 0;

END;
$$ LANGUAGE plpgsql;


-- XXX: should it exception on null?


--
-- procedure acs_sc_operation__delete/2
--
CREATE OR REPLACE FUNCTION acs_sc_operation__delete(
   p_contract_name varchar,
   p_operation_name varchar
) RETURNS integer AS $$
DECLARE
    v_operation_id              integer;
BEGIN

    v_operation_id := acs_sc_operation__get_id(
                          p_contract_name,
                          p_operation_name
                      );

    perform acs_sc_operation__delete(v_operation_id);

    return v_operation_id;

END;
$$ LANGUAGE plpgsql strict;

-- register function record
select define_function_args('acs_sc_impl__new','impl_contract_name,impl_name,impl_pretty_name,impl_owner_name');
-- declare function


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

-- Only three arguments, defaults pretty name to empty string


--
-- procedure acs_sc_impl__new/3
--
CREATE OR REPLACE FUNCTION acs_sc_impl__new(
   p_impl_contract_name varchar,
   p_impl_name varchar,
   p_impl_owner_name varchar
) RETURNS integer AS $$
--
-- acs_sc_impl__new/3 maybe obsolete, when we define proper defaults for /4
--
DECLARE
    v_impl_id                   integer;
BEGIN
    -- Using an empty pretty name
    v_impl_id := acs_sc_impl__new(
        p_impl_contract_name,
        p_impl_name,
        p_impl_name,
        p_impl_owner_name
    );

    return v_impl_id;

END;
$$ LANGUAGE plpgsql;

-- register function record
select define_function_args('acs_sc_impl__get_id','impl_contract_name,impl_name');
-- declare function


--
-- procedure acs_sc_impl__get_id/2
--
CREATE OR REPLACE FUNCTION acs_sc_impl__get_id(
   p_impl_contract_name varchar,
   p_impl_name varchar
) RETURNS integer AS $$
DECLARE
    v_impl_id                   integer;
BEGIN

    select impl_id into v_impl_id
    from acs_sc_impls
    where impl_name = p_impl_name
    and impl_contract_name = p_impl_contract_name;

    return v_impl_id;

END;
$$ LANGUAGE plpgsql stable strict;

-- register function record
select define_function_args('acs_sc_impl__get_name','impl_id');
-- declare function


--
-- procedure acs_sc_impl__get_name/1
--
CREATE OR REPLACE FUNCTION acs_sc_impl__get_name(
   p_impl_id integer
) RETURNS varchar AS $$
DECLARE
    v_impl_name                 varchar;
BEGIN

    select impl_name into v_impl_name
    from acs_sc_impls
    where impl_id = p_impl_id;

    return v_impl_name;

END;
$$ LANGUAGE plpgsql stable strict;

-- register function record
select define_function_args('acs_sc_impl__delete','impl_contract_name,impl_name');
-- declare function


--
-- procedure acs_sc_impl__delete/2
--
CREATE OR REPLACE FUNCTION acs_sc_impl__delete(
   p_impl_contract_name varchar,
   p_impl_name varchar
) RETURNS integer AS $$
DECLARE
  v_impl_id integer;
BEGIN

    v_impl_id := acs_sc_impl__get_id(p_impl_contract_name,p_impl_name);

    perform acs_object__delete(v_impl_id);

    return 0;

END;
$$ LANGUAGE plpgsql;





-- register function record
select define_function_args('acs_sc_impl_alias__new','impl_contract_name,impl_name,impl_operation_name,impl_alias,impl_pl');
-- declare function


--
-- procedure acs_sc_impl_alias__new/5
--
CREATE OR REPLACE FUNCTION acs_sc_impl_alias__new(
   p_impl_contract_name varchar,
   p_impl_name varchar,
   p_impl_operation_name varchar,
   p_impl_alias varchar,
   p_impl_pl varchar
) RETURNS integer AS $$
DECLARE
    v_impl_id                   integer;
BEGIN

    v_impl_id := acs_sc_impl__get_id(p_impl_contract_name,p_impl_name);

    insert into acs_sc_impl_aliases (
        impl_id,
        impl_name,
        impl_contract_name,
        impl_operation_name,
        impl_alias,
        impl_pl
    ) values (
        v_impl_id,
        p_impl_name,
        p_impl_contract_name,
        p_impl_operation_name,
        p_impl_alias,
        p_impl_pl
    );

    return v_impl_id;

END;
$$ LANGUAGE plpgsql;



-- register function record
select define_function_args('acs_sc_impl_alias__delete','impl_contract_name,impl_name,impl_operation_name');
-- declare function


--
-- procedure acs_sc_impl_alias__delete/3
--
CREATE OR REPLACE FUNCTION acs_sc_impl_alias__delete(
   p_impl_contract_name varchar,
   p_impl_name varchar,
   p_impl_operation_name varchar
) RETURNS integer AS $$
DECLARE
    v_impl_id                   integer;
BEGIN

    v_impl_id := acs_sc_impl__get_id(p_impl_contract_name, p_impl_name);

    delete from acs_sc_impl_aliases 
    where impl_contract_name = p_impl_contract_name 
    and impl_name = p_impl_name
    and impl_operation_name = p_impl_operation_name;

    return v_impl_id;

END;
$$ LANGUAGE plpgsql;




--
-- procedure acs_sc_binding__new/2
--
--select define_function_args('acs_sc_binding__new','contract_id,impl_id');

CREATE OR REPLACE FUNCTION acs_sc_binding__new(
   p_contract_id integer,
   p_impl_id integer
) RETURNS integer AS $$
DECLARE
    v_contract_name             varchar;
    v_impl_name                 varchar;
    v_count                     integer;
    v_missing_op                varchar;
BEGIN

    v_contract_name := acs_sc_contract__get_name(p_contract_id);
    v_impl_name := acs_sc_impl__get_name(p_impl_id);

    select count(*),min(operation_name) into v_count, v_missing_op
    from acs_sc_operations
    where contract_id = p_contract_id
    and operation_name not in (select impl_operation_name
                               from acs_sc_impl_aliases
                               where impl_contract_name = v_contract_name
                               and impl_id = p_impl_id);

    if v_count > 0 then
        raise exception 'Binding of % to % failed since certain operations are not implemented like: %.', v_contract_name, v_impl_name, v_missing_op;
    end if;

    insert into acs_sc_bindings (
        contract_id,
        impl_id
    ) values (
        p_contract_id,
        p_impl_id
    );

    return 0;

END;
$$ LANGUAGE plpgsql;


--
-- procedure acs_sc_binding__new/2
--
-- variant with names
--
select define_function_args('acs_sc_binding__new','contract_name,impl_name');

CREATE OR REPLACE FUNCTION acs_sc_binding__new(
   p_contract_name varchar,
   p_impl_name varchar
) RETURNS integer AS $$
DECLARE
    v_contract_id               integer;
    v_impl_id                   integer;
    v_count                     integer;
BEGIN

    v_contract_id := acs_sc_contract__get_id(p_contract_name);

    v_impl_id := acs_sc_impl__get_id(p_contract_name,p_impl_name);

    if v_contract_id is null or v_impl_id is null then
        raise exception 'Binding of % to % failed.', p_contract_name, p_impl_name;
    else
        perform acs_sc_binding__new(v_contract_id,v_impl_id);
    end if;

    return 0;

END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_sc_binding__delete/2
--
-- select define_function_args('acs_sc_binding__delete','contract_id,impl_id');
--
CREATE OR REPLACE FUNCTION acs_sc_binding__delete(
   p_contract_id integer,
   p_impl_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

    delete from acs_sc_bindings
    where contract_id = p_contract_id
    and impl_id = p_impl_id;

    return 0;
END;
$$ LANGUAGE plpgsql;


--
-- procedure acs_sc_binding__delete/2
--
select define_function_args('acs_sc_binding__delete','contract_name,impl_name');

CREATE OR REPLACE FUNCTION acs_sc_binding__delete(
   p_contract_name varchar,
   p_impl_name varchar
) RETURNS integer AS $$
DECLARE
    v_contract_id               integer;
    v_impl_id                   integer;
BEGIN

    v_contract_id := acs_sc_contract__get_id(p_contract_name);

    v_impl_id := acs_sc_impl__get_id(p_contract_name,p_impl_name);

    perform acs_sc_binding__delete(v_contract_id,v_impl_id);

    return 0;

END;
$$ LANGUAGE plpgsql;


-- register function record
select define_function_args('acs_sc_binding__exists_p','contract_name,impl_name');
-- declare function


--
-- procedure acs_sc_binding__exists_p/2
--
CREATE OR REPLACE FUNCTION acs_sc_binding__exists_p(
   p_contract_name varchar,
   p_impl_name varchar
) RETURNS integer AS $$
DECLARE
    v_contract_id               integer;
    v_impl_id                   integer;
    v_exists_p                  integer;
BEGIN

    v_contract_id := acs_sc_contract__get_id(p_contract_name);

    v_impl_id := acs_sc_impl__get_id(p_contract_name,p_impl_name);

    select case when count(*)=0 then 0 else 1 end into v_exists_p
    from acs_sc_bindings
    where contract_id = v_contract_id
    and impl_id = v_impl_id;

    return v_exists_p;

END;
$$ LANGUAGE plpgsql stable;




