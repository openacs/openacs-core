--
-- packages/site-wide-search/sql/acs-object-util.sql
-- 
-- @author khy@arsdigita.com
-- @creation-date 2000-11-24
-- @cvs-id $Id$
--

create or replace package acs_object_util
as 
    function object_type_exist_p (
        object_type       in acs_object_types.object_type%TYPE
    ) return char;

    function get_object_type (
        object_id         in acs_objects.object_id%TYPE
    ) return acs_object_types.object_type%TYPE;

    function type_ancestor_type_p (
        object_type1      in acs_object_types.object_type%TYPE,
        object_type2      in acs_object_types.object_type%TYPE
    ) return char;

    function object_ancestor_type_p (
        object_id         in acs_objects.object_id%TYPE,
        object_type       in acs_object_types.object_type%TYPE
    ) return char;

    function object_type_p (
        object_id         in acs_objects.object_id%TYPE,
        object_type       in acs_object_types.object_type%TYPE
    ) return char;
end acs_object_util;    
/

create or replace package body acs_object_util
as
    function object_type_exist_p (
        object_type       in acs_object_types.object_type%TYPE
    ) return char
    is
        v_exist_p         char(1) := 't';
    begin
        select decode(count(*),1,'t','f') into v_exist_p
        from   acs_object_types 
        where  object_type = acs_object_util.object_type_exist_p.object_type;
 
        return v_exist_p;
    end object_type_exist_p;

    function get_object_type (
        object_id         in acs_objects.object_id%TYPE
    ) return acs_object_types.object_type%TYPE 
    is 
        v_object_type     acs_object_types.object_type%TYPE;
    begin

	
        select 	object_type into v_object_type
        from 	acs_objects
        where 	object_id = acs_object_util.get_object_type.object_id;

        return v_object_type;
        exception 
             when no_data_found then
                raise_application_error(-20003,'Invalid Object id '||to_char(object_id));
    end get_object_type;        

    function type_ancestor_type_p (
        object_type1      in acs_object_types.object_type%TYPE,
        object_type2      in acs_object_types.object_type%TYPE
    ) return char
    is 
        v_exist_p       char(1) := 'f';
        v_count         integer := 0;
    begin
        v_exist_p := acs_object_util.object_type_exist_p(object_type1);
        if v_exist_p = 'f' THEN
           raise_application_error(-20002, 'Object type '|| object_type1 || ' does not exist');
        end if;

        v_exist_p := acs_object_util.object_type_exist_p(object_type2);
        if v_exist_p = 'f' THEN
           raise_application_error(-20002, 'Object type '|| object_type2 || ' does not exist');
        end if;
        
        select count(*) into v_count
        from dual 
        where acs_object_util.type_ancestor_type_p.object_type2 in (
            select object_type 
            from acs_object_types
            start with object_type = acs_object_util.type_ancestor_type_p.object_type1
            connect by prior supertype = object_type);

       select decode(v_count,1,'t','f') into v_exist_p from dual;

    return v_exist_p;
    end type_ancestor_type_p;    
   
    function object_ancestor_type_p (
        object_id         in acs_objects.object_id%TYPE,
        object_type       in acs_object_types.object_type%TYPE
    ) return char
    is 
        v_exist_p       char(1) := 'f';
        v_object_type   acs_object_types.object_type%TYPE;
    begin
  
        v_object_type := acs_object_util.get_object_type (object_id);
        
        v_exist_p := acs_object_util.type_ancestor_type_p (v_object_type, object_type);
        return v_exist_p;        
    end object_ancestor_type_p;

    function object_type_p (
        object_id         in acs_objects.object_id%TYPE,
        object_type       in acs_object_types.object_type%TYPE
    ) return char
    is 
        v_exist_p      char(1) := 'f';
    begin
        v_exist_p := object_ancestor_type_p(object_id, object_type);
        return v_exist_p;
    end object_type_p;
end acs_object_util;
/







