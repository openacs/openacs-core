-- moved from site-wide search to acs-kernel

create function acs_object_util__object_type_exist_p (varchar)
returns boolean as '
declare
    p_object_type       alias for $1;
    v_exist_p           boolean := ''t'';
begin


    select (case when count(*)=1 then ''t'' else ''f'' end) into v_exist_p
    from   acs_object_types 
    where  object_type = p_object_type;
 
    return v_exist_p;
end;' language 'plpgsql';


create function acs_object_util__get_object_type (integer)
returns varchar as '
declare
    p_object_id         alias for $1;
    v_object_type       varchar(100);
begin
    select object_type into v_object_type
    from acs_objects
    where object_id = p_object_id;

    return v_object_type;

    if not found then
        raise exception ''Invalid Object id: % '', p_object_id;
    end if;

end;' language 'plpgsql';



create function acs_object_util__type_ancestor_type_p (varchar,varchar)
returns boolean as '
declare
    p_object_type1      alias for $1;
    p_object_type2      alias for $2;
    v_exist_p           boolean := ''f'';
    v_count             integer := 0;
begin
    v_exist_p := acs_object_util__object_type_exist_p(p_object_type1);

    if v_exist_p = ''f'' then
        raise exception ''Object type % does not exist'', p_object_type1;
    end if;

    v_exist_p := acs_object_util__object_type_exist_p(p_object_type2);

    if v_exist_p = ''f'' then
        raise exception ''Object type % does not exist'', p_object_type2;
    end if;
        
    select count(*) into v_count
    from dual 
    where p_object_type2 in (select o2.object_type
                           from acs_object_types o1, acs_object_types o2
                          where o1.object_type = p_object_type1
                            and o2.tree_sortkey <= o1.tree_sortkey
                            and o1.tree_sortkey like (o2.tree_sortkey || ''%''));

    select (case when v_count=1 then ''t'' else ''f'' end) into v_exist_p;

    return v_exist_p;
end;' language 'plpgsql';



create function acs_object_util__object_ancestor_type_p (integer,varchar)
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
end;' language 'plpgsql';


create function acs_object_util__object_type_p (integer,varchar)
returns boolean as '
declare
    p_object_id         alias for $1;
    p_object_type       alias for $2;
    v_exist_p           boolean := ''f'';
begin
    v_exist_p := acs_object_util__object_ancestor_type_p(p_object_id, p_object_type);
    return v_exist_p;
end;' language 'plpgsql';
