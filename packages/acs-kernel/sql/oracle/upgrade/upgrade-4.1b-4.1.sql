--
-- /packages/acs-kernel/sql/upgrade/upgrade-4.1b-4.1.sql
-- 
-- Upgrades ACS Kernel 4.1 beta to ACS Kernel 4.1
--
-- @author Multiple
-- @creation-date 2001-01-19
-- @cvs-id $Id$



-----------------------------
-- PACKAGE ACS_OBJECT_TYPE
-- mbryzek@arsdigita.com
-- 1/19/2001
--
-- CHANGES
-- Add is_subtype_p function
-----------------------------
create or replace package acs_object_type
is
  -- define an object type
  procedure create_type (
    object_type		in acs_object_types.object_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'acs_object',
    table_name		in acs_object_types.table_name%TYPE,
    id_column		in acs_object_types.id_column%TYPE default 'XXX',
    package_name	in acs_object_types.package_name%TYPE default null,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null
  );

  -- delete an object type definition
  procedure drop_type (
    object_type		in acs_object_types.object_type%TYPE,
    cascade_p		in char default 'f'
  );

  -- look up an object type's pretty_name
  function pretty_name (
    object_type 	in acs_object_types.object_type%TYPE
  ) return acs_object_types.pretty_name%TYPE;

  -- Returns 't' if object_type_2 is a subtype of object_type_1. Note
  -- that this function will return 'f' if object_type_1 =
  -- object_type_2
  function is_subtype_p (
    object_type_1 	in acs_object_types.object_type%TYPE,
    object_type_2 	in acs_object_types.object_type%TYPE
  ) return char;

end acs_object_type;
/
show errors


create or replace package body acs_object_type
is

  procedure create_type (
    object_type		in acs_object_types.object_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'acs_object',
    table_name		in acs_object_types.table_name%TYPE,
    id_column		in acs_object_types.id_column%TYPE,
    package_name	in acs_object_types.package_name%TYPE default null,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null
  )
  is
    v_package_name acs_object_types.package_name%TYPE;
  begin
    -- XXX This is a hack for losers who haven't created packages yet.
    if package_name is null then
      v_package_name := object_type;
    else
      v_package_name := package_name;
    end if;

    insert into acs_object_types
      (object_type, pretty_name, pretty_plural, supertype, table_name,
       id_column, abstract_p, type_extension_table, package_name,
       name_method)
    values
      (object_type, pretty_name, pretty_plural, supertype, table_name,
       id_column, abstract_p, type_extension_table, v_package_name,
       name_method);
  end create_type;

  procedure drop_type (
    object_type		in acs_object_types.object_type%TYPE,
    cascade_p		in char default 'f'
  )
  is
    cursor c_attributes (object_type IN varchar) is
      select attribute_name from acs_attributes where object_type = object_type;
  begin

    -- drop all the attributes associated with this type
    for row in c_attributes (drop_type.object_type) loop
       acs_attribute.drop_attribute ( drop_type.object_type, row.attribute_name );
    end loop;

    delete from acs_attributes
    where object_type = drop_type.object_type;

    delete from acs_object_types
    where object_type = drop_type.object_type;
  end drop_type;


  function pretty_name (
    object_type 	in acs_object_types.object_type%TYPE 
  ) return acs_object_types.pretty_name%TYPE
  is
    v_pretty_name       acs_object_types.pretty_name%TYPE;
  begin
    select t.pretty_name into v_pretty_name
      from acs_object_types t
     where t.object_type = pretty_name.object_type;

    return v_pretty_name;

  end pretty_name;


  function is_subtype_p (
    object_type_1 	in acs_object_types.object_type%TYPE,
    object_type_2 	in acs_object_types.object_type%TYPE
  ) return char
  is 
    v_result integer;
  begin
    select count(*) into v_result
      from dual
     where exists (select 1 
                     from acs_object_types t 
                    where t.object_type	= is_subtype_p.object_type_2
                  connect by prior t.object_type = t.supertype
                    start with t.supertype = is_subtype_p.object_type_1);

    if v_result > 0 then
       return 't';
    end if;

    return 'f';

   end is_subtype_p;

end acs_object_type;
/
show errors



-----------------------------
-- View: rc_violations_by_removing_rel
-- mbryzek@arsdigita.com
-- 1/19/2001
--
-- CHANGES
-- Fix bug in join
-----------------------------

-- View: rc_violations_by_removing_rel
--
-- Question: Given relation :rel_id
--
--           If we were to remove the relation specified by rel_id, 
--           what constraints would be violated and by what parties?
--
-- Answer:   select r.rel_id, r.constraint_id, r.constraint_name
--	            acs_object_type.pretty_name(r.rel_type) as rel_type_pretty_name,
--	            acs_object.name(r.object_id_one) as object_id_one_name, 
--	            acs_object.name(r.object_id_two) as object_id_two_name
--	       from rc_violations_by_removing_rel r
--	      where r.rel_id = :rel_id
--        

create or replace view rc_violations_by_removing_rel as
select r.rel_type as viol_rel_type, r.rel_id as viol_rel_id, 
       r.object_id_one as viol_object_id_one, r.object_id_two as viol_object_id_two,
       s.rel_id,
       cons.constraint_id, cons.constraint_name,
       map.segment_id, map.party_id, map.group_id, map.container_id, map.ancestor_rel_type
  from acs_rels r, rel_segment_party_map map, rel_constraints cons,
               (select s.segment_id, r.rel_id, r.object_id_two
                  from rel_segments s, acs_rels r
                 where r.object_id_one = s.group_id
                   and r.rel_type = s.rel_type) s
 where map.party_id = r.object_id_two
   and map.rel_id = r.rel_id
   and r.object_id_two = s.object_id_two
   and cons.rel_segment = map.segment_id
   and cons.required_rel_segment = s.segment_id;



-------------------------------
-- ACS_OBJECT_ATTRIBUTE_VIEW
-- mbryzek@arsdigita.com
-- 1/5/2001
-------------------------------
-- Use union all instead of union

create or replace view acs_object_type_attributes as 
select all_types.object_type, all_types.ancestor_type, 
       attr.attribute_id, attr.table_name, attr.attribute_name, 
       attr.pretty_name, attr.pretty_plural, attr.sort_order, 
       attr.datatype, attr.default_value, attr.min_n_values, 
       attr.max_n_values, attr.storage, attr.static_p, attr.column_name
from acs_attributes attr,
     (select map.object_type, map.ancestor_type
      from acs_object_type_supertype_map map, acs_object_types t
      where map.object_type=t.object_type
      UNION ALL
      select t.object_type, t.object_type as ancestor_type
        from acs_object_types t) all_types
where attr.object_type = all_types.ancestor_type;

