-- moved from site-wide search to acs-kernel

create or replace function acs_object_util__object_type_exist_p (varchar)
returns boolean as '
declare
    p_object_type       alias for $1;
    v_exist_p           boolean := ''t'';
begin


    select (case when count(*)=1 then ''t'' else ''f'' end) into v_exist_p
    from   acs_object_types 
    where  object_type = p_object_type;
 
    return v_exist_p;
end;' language 'plpgsql' stable;


create or replace function acs_object_util__get_object_type (integer)
returns varchar as '
declare
    p_object_id         alias for $1;
    v_object_type       varchar(100);
begin
    select object_type into v_object_type
    from acs_objects
    where object_id = p_object_id;

    if not found then
        raise exception ''acs_object_util__get_object_type: Invalid Object id: % '', p_object_id;
    end if;

    return v_object_type;

end;' language 'plpgsql' stable;


create or replace function acs_object_util__type_ancestor_type_p (varchar,varchar)
returns boolean as '
declare
    p_object_type1      alias for $1;
    p_object_type2      alias for $2;
begin

    if not acs_object_util__object_type_exist_p(p_object_type1) then
        raise exception ''Object type % does not exist'', p_object_type1;
    end if;

    if not acs_object_util__object_type_exist_p(p_object_type2) then
        raise exception ''Object type % does not exist'', p_object_type2;
    end if;
        
    return exists (select 1
                   from acs_object_types o1, acs_object_types o2
                   where p_object_type2 = o2.object_type
                     and o1.object_type = p_object_type1
                     and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey));
end;' language 'plpgsql' stable;



create or replace function acs_object_util__object_ancestor_type_p (integer,varchar)
returns boolean as '
declare
    p_object_id         alias for $1;
    p_object_type       alias for $2;
    v_exist_p           boolean := ''f'';
    v_object_type       varchar(100);
begin
    v_object_type := acs_object_util__get_object_type (p_object_id);

    v_exist_p := acs_object_util__type_ancestor_type_p (v_object_type, p_object_type);
    return v_exist_p;
end;' language 'plpgsql' stable;


create or replace function acs_object_util__object_type_p (integer,varchar)
returns boolean as '
declare
    p_object_id         alias for $1;
    p_object_type       alias for $2;
    v_exist_p           boolean := ''f'';
begin
    v_exist_p := acs_object_util__object_ancestor_type_p(p_object_id, p_object_type);
    return v_exist_p;
end;' language 'plpgsql' stable;
