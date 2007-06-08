select acs_object_type__create_type (
    'acs_sc_msg_type',                  -- object_type
    'ACS SC Message Type',              -- pretty_name
    'ACS SC Message Types',             -- pretty_plural
    'acs_object',                       -- supertype 
    'acs_sc_msg_types',                  -- table_name
    'msg_type_id',                      -- id_column
    null,                               -- package_name
    'f',                                -- abstract_p
    null,                               -- type_extension_table
    null                                -- name_method
);



create table acs_sc_msg_types (
    msg_type_id		     integer
			     constraint acs_sc_msg_types_id_fk
			     references acs_objects(object_id)
			     on delete cascade
			     constraint acs_sc_msg_types_pk
			     primary key,
    msg_type_name	     varchar(100)
			     constraint acs_sc_msg_types_name_un
			     unique
);


create table acs_sc_msg_type_elements (
    msg_type_id		     integer
			     constraint acs_sc_msg_type_el_mtype_id_fk
			     references acs_sc_msg_types(msg_type_id)
			     on delete cascade,
    element_name	     varchar(100),
    element_msg_type_id	     integer
			     constraint acs_sc_msg_type_el_emti_id_fk
			     references acs_sc_msg_types(msg_type_id),
    element_msg_type_isset_p boolean,
    element_pos		     integer
);

-- register function record
select define_function_args('acs_sc_msg_type__new','msg_type_name,msg_type_spec');
-- declare function
create or replace function acs_sc_msg_type__new(varchar,varchar)
returns integer as '
declare
    p_msg_type_name             alias for $1;
    p_msg_type_spec		alias for $2;
    v_msg_type_id               integer;
begin

    v_msg_type_id := acs_object__new(
                null,
                ''acs_sc_msg_type'',
                now(),
                null,
                null,
                null,
                ''t'',
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

end;' language 'plpgsql';

-- register function record
select define_function_args('acs_sc_msg_type__get_id','msg_type_name');
-- declare function
create or replace function acs_sc_msg_type__get_id(varchar)
returns integer as '
declare
    p_msg_type_name		alias for $1;
    v_msg_type_id		integer;
begin

    select msg_type_id into v_msg_type_id
    from acs_sc_msg_types
    where msg_type_name = p_msg_type_name;
   
    return v_msg_type_id;

end;' language 'plpgsql' stable strict;

-- register function record
select define_function_args('acs_sc_msg_type__get_name','msg_type_id');
-- declare function
create or replace function acs_sc_msg_type__get_name(integer)
returns varchar as '
declare
    p_msg_type_id		alias for $1;
    v_msg_type_name		varchar;
begin

    select msg_type_name into v_msg_type_name
    from acs_sc_msg_types
    where msg_type_id = p_msg_type_id;
   
    return v_msg_type_name;

end;' language 'plpgsql' stable strict;

create or replace function acs_sc_msg_type__delete(integer)
returns integer as '
declare
    p_msg_type_id		alias for $1;
begin

    delete from acs_sc_msg_types
    where msg_type_id = p_msg_type_id;

    return 0;

end;' language 'plpgsql';

-- XXX: this might be a bug that it does not return 0 as the above does.
-- anyway now it is strict as being called with null is a noop and returns null
-- register function record
select define_function_args('acs_sc_msg_type__delete','msg_type_name');
-- declare function
create or replace function acs_sc_msg_type__delete(varchar)
returns integer as '
declare
    p_msg_type_name		alias for $1;
    v_msg_type_id		integer;
begin

    v_msg_type_id := acs_sc_msg_type__get_id(p_msg_type_name);

    perform acs_sc_msg_type__delete(v_msg_type_id);

    return v_msg_type_id;

end;' language 'plpgsql' strict;





-- register function record
select define_function_args('acs_sc_msg_type__new_element','msg_type_name,element_name,element_msg_type_name,element_msg_type_isset_p;f,element_pos');
-- declare function
create or replace function acs_sc_msg_type__new_element(varchar,varchar,varchar,boolean,integer)
returns integer as '
declare
    p_msg_type_name		alias for $1;
    p_element_name		alias for $2;
    p_element_msg_type_name	alias for $3;
    p_element_msg_type_isset_p	alias for $4;
    p_element_pos		alias for $5;
    v_msg_type_id		integer;
    v_element_msg_type_id	integer;
begin

    v_msg_type_id := acs_sc_msg_type__get_id(p_msg_type_name);

    if v_msg_type_id is null then
        raise exception ''Unknown Message Type: %'', p_msg_type_name;
    end if;

    v_element_msg_type_id := acs_sc_msg_type__get_id(p_element_msg_type_name);

    if v_element_msg_type_id is null then
        raise exception ''Unknown Message Type: %'', p_element_msg_type_name;
    end if;

    insert into acs_sc_msg_type_elements (
        msg_type_id,
	element_name,
	element_msg_type_id,
	element_msg_type_isset_p,
	element_pos
    ) values (
        v_msg_type_id,
	p_element_name,
	v_element_msg_type_id,
	p_element_msg_type_isset_p,
	p_element_pos
    );

    return v_msg_type_id;

end;' language 'plpgsql';



-- register function record
select define_function_args('acs_sc_msg_type__parse_spec','msg_type_name,msg_type_spec');
-- declare function
create or replace function acs_sc_msg_type__parse_spec(varchar,varchar)
returns integer as '
declare
    p_msg_type_name		alias for $1;
    p_msg_type_spec		alias for $2;
    v_element			varchar;
    v_element_type		varchar;
    v_str_pos			integer;
    v_element_name		varchar;
    v_element_msg_type_name	varchar;
    v_element_msg_type_isset_p	boolean;
    v_element_pos		integer;
begin

    v_element_pos := 1;
    v_element := split(p_msg_type_spec, '','', v_element_pos);

    while v_element is not null loop

        v_str_pos = instr(v_element, '':'', 1, 1);

	if v_str_pos > 0 then
	    v_element_name := trim(substr(v_element, 1, v_str_pos-1));
	    v_element_type := trim(substr(v_element, v_str_pos+1, length(v_element) - v_str_pos));
	    if (instr(v_element_type, ''['',1,1) = length(v_element_type)-1) and 
	       (instr(v_element_type, '']'',1,1) = length(v_element_type)) then
	        v_element_msg_type_isset_p := ''t'';
	        v_element_msg_type_name := trim(substr(v_element_type,1,length(v_element_type)-2));
		if v_element_msg_type_name = '''' then
		    raise exception ''Wrong Format: Message Type Specification'';
		end if;
	    else
	        v_element_msg_type_isset_p := ''f'';
	        v_element_msg_type_name := v_element_type;
	    end if;
        else
	    raise exception ''Wrong Format: Message Type Specification'';
        end if;

        perform acs_sc_msg_type__new_element(
                   p_msg_type_name,				-- msg_type_id
		   v_element_name,				-- element_name
		   v_element_msg_type_name,			-- element_msg_type_id
		   v_element_msg_type_isset_p,			-- element_msg_type_isset_p
		   v_element_pos				-- element_pos
        );

        v_element_pos := v_element_pos + 1;
	v_element := split(p_msg_type_spec, '','', v_element_pos);

    end loop;

    return v_element_pos-1;

end;' language 'plpgsql';



--
-- Primitive Message Types
--
select acs_sc_msg_type__new('integer','');
select acs_sc_msg_type__new('string','');
select acs_sc_msg_type__new('boolean','');
select acs_sc_msg_type__new('timestamp','');
select acs_sc_msg_type__new('uri','');
select acs_sc_msg_type__new('version','');
select acs_sc_msg_type__new('float','');
select acs_sc_msg_type__new('bytearray','');
