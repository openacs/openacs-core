-- moved from site-wide search to acs-kernel



-- added
select define_function_args('acs_object_util__object_type_exist_p','object_type');

--
-- procedure acs_object_util__object_type_exist_p/1
--
CREATE OR REPLACE FUNCTION acs_object_util__object_type_exist_p(
   p_object_type varchar
) RETURNS boolean AS $$
DECLARE
    v_exist_p           boolean := 't';
BEGIN


    select (case when count(*)=1 then 't' else 'f' end) into v_exist_p
    from   acs_object_types 
    where  object_type = p_object_type;
 
    return v_exist_p;
END;
$$ LANGUAGE plpgsql stable;




-- added
select define_function_args('acs_object_util__get_object_type','object_id');

--
-- procedure acs_object_util__get_object_type/1
--
CREATE OR REPLACE FUNCTION acs_object_util__get_object_type(
   p_object_id integer
) RETURNS varchar AS $$
DECLARE
    v_object_type       varchar(100);
BEGIN
    select object_type into v_object_type
    from acs_objects
    where object_id = p_object_id;

    if not found then
        raise exception 'acs_object_util__get_object_type: Invalid Object id: % ', p_object_id;
    end if;

    return v_object_type;

END;
$$ LANGUAGE plpgsql stable;




-- added
select define_function_args('acs_object_util__type_ancestor_type_p','object_type1,object_type2');

--
-- procedure acs_object_util__type_ancestor_type_p/2
--
CREATE OR REPLACE FUNCTION acs_object_util__type_ancestor_type_p(
   p_object_type1 varchar,
   p_object_type2 varchar
) RETURNS boolean AS $$
DECLARE
BEGIN

    if not acs_object_util__object_type_exist_p(p_object_type1) then
        raise exception 'Object type % does not exist', p_object_type1;
    end if;

    if not acs_object_util__object_type_exist_p(p_object_type2) then
        raise exception 'Object type % does not exist', p_object_type2;
    end if;
        
    return exists (select 1
                   from acs_object_types o1, acs_object_types o2
                   where p_object_type2 = o2.object_type
                     and o1.object_type = p_object_type1
                     and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey));
END;
$$ LANGUAGE plpgsql stable;





-- added
select define_function_args('acs_object_util__object_ancestor_type_p','object_id,object_type');

--
-- procedure acs_object_util__object_ancestor_type_p/2
--
CREATE OR REPLACE FUNCTION acs_object_util__object_ancestor_type_p(
   p_object_id integer,
   p_object_type varchar
) RETURNS boolean AS $$
DECLARE
    v_exist_p           boolean := 'f';
    v_object_type       varchar(100);
BEGIN
    v_object_type := acs_object_util__get_object_type (p_object_id);

    v_exist_p := acs_object_util__type_ancestor_type_p (v_object_type, p_object_type);
    return v_exist_p;
END;
$$ LANGUAGE plpgsql stable;




-- added
select define_function_args('acs_object_util__object_type_p','object_id,object_type');

--
-- procedure acs_object_util__object_type_p/2
--
CREATE OR REPLACE FUNCTION acs_object_util__object_type_p(
   p_object_id integer,
   p_object_type varchar
) RETURNS boolean AS $$
DECLARE
    v_exist_p           boolean := 'f';
BEGIN
    v_exist_p := acs_object_util__object_ancestor_type_p(p_object_id, p_object_type);
    return v_exist_p;
END;
$$ LANGUAGE plpgsql stable;
