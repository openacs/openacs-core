--
-- packages/acs-kernel/sql/acs-relationships-create.sql
--
-- XXX Fill this in later.
--
-- @creation-date 2000-08-13
--
-- @author rhs@mit.edu
--
-- @cvs-id $Id$
--

----------------------------------------------------------------
-- KNOWLEDGE LEVEL: RELATIONSHIP TYPES AND RELATIONSHIP RULES --
----------------------------------------------------------------

create table acs_rel_roles (
	role		varchar(100) not null
			constraint acs_rel_roles_role_pk primary key,
        pretty_name	varchar(100) not null,
        pretty_plural	varchar(100) not null
);

create table acs_rel_types (
	rel_type	varchar(1000) not null
			constraint acs_rel_types_rel_type_pk primary key
			constraint acs_rel_types_rel_type_fk
			references acs_object_types(object_type),
	object_type_one	varchar(1000) not null
			constraint acs_rel_types_obj_type_1_fk
			references acs_object_types (object_type),
	role_one	varchar(100) constraint acs_rel_types_role_one_fk
			references acs_rel_roles (role),
	min_n_rels_one	integer default 0 not null
			constraint acs_rel_types_min_n_1_ck
			check (min_n_rels_one >= 0),
	max_n_rels_one	integer
			constraint acs_rel_types_max_n_1_ck
			check (max_n_rels_one >= 0),
	object_type_two	varchar(1000) not null
			constraint acs_rel_types_obj_type_2_fk
			references acs_object_types (object_type),
	role_two	varchar(100) constraint acs_rel_types_role_two_fk
			references acs_rel_roles (role),
	min_n_rels_two	integer default 0 not null
			constraint acs_rel_types_min_n_2_ck
			check (min_n_rels_two >= 0),
	max_n_rels_two	integer
			constraint acs_rel_types_max_n_2_ck
			check (max_n_rels_two >= 0),
        composable_p    boolean
	                default 't' not null,
	constraint acs_rel_types_n_rels_one_ck
	check (min_n_rels_one <= max_n_rels_one),
	constraint acs_rel_types_n_rels_two_ck
	check (min_n_rels_two <= max_n_rels_two)
);

create index acs_rel_types_objtypeone_idx on acs_rel_types (object_type_one);
create index acs_rel_types_role_one_idx on acs_rel_types (role_one);
create index acs_rel_types_objtypetwo_idx on acs_rel_types (object_type_two);
create index acs_rel_types_role_two_idx on acs_rel_types (role_two);

comment on table acs_rel_types is $$
 Each row in <code>acs_rel_types</code> represents a type of
 relationship between objects. For example, the following DML
 statement:
 <blockquote><pre>
 insert into acs_rel_types
  (rel_type,
   object_type_one, role_one, min_n_rels_one, max_n_rels_one,
   object_type_two, role_two, min_n_rels_two, max_n_rels_two)
 values
  ('employment',
   'person', 'employee', 0, null,
   'company', 'employer', 0, null)
 </pre></blockquote>
 defines an "employment" relationship type that can be expressed in
 in natural language as:
 <blockquote>
 A person may be the employee of zero or more companies, and a company
 may be the employer of zero or more people.
 </blockquote>
$$;



-- added
select define_function_args('acs_rel_type__create_role','role,pretty_name;null,pretty_plural;null');

--
-- procedure acs_rel_type__create_role/3
--
CREATE OR REPLACE FUNCTION acs_rel_type__create_role(
   create_role__role varchar,
   create_role__pretty_name varchar,  -- default null
   create_role__pretty_plural varchar -- default null

) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_rel_roles
     (role, pretty_name, pretty_plural)
    values
     (create_role__role, coalesce(create_role__pretty_name,create_role__role), coalesce(create_role__pretty_plural,create_role__role));

    return 0; 
END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_rel_type__create_role/1
--
CREATE OR REPLACE FUNCTION acs_rel_type__create_role(
   create_role__role varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    perform acs_rel_type__create_role(create_role__role, NULL, NULL);
    return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure drop_role


-- added
select define_function_args('acs_rel_type__drop_role','role');

--
-- procedure acs_rel_type__drop_role/1
--
CREATE OR REPLACE FUNCTION acs_rel_type__drop_role(
   drop_role__role varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from acs_rel_roles
    where role = drop_role__role;

    return 0; 
END;
$$ LANGUAGE plpgsql;


-- function role_pretty_name


-- added
select define_function_args('acs_rel_type__role_pretty_name','role');

--
-- procedure acs_rel_type__role_pretty_name/1
--
CREATE OR REPLACE FUNCTION acs_rel_type__role_pretty_name(
   role_pretty_name__role varchar
) RETURNS varchar AS $$
DECLARE
  v_pretty_name                 acs_rel_roles.pretty_name%TYPE;
BEGIN
    select r.pretty_name into v_pretty_name
      from acs_rel_roles r
     where r.role = role_pretty_name__role;

    return v_pretty_name;
   
END;
$$ LANGUAGE plpgsql stable strict;


-- function role_pretty_plural


-- added
select define_function_args('acs_rel_type__role_pretty_plural','role');

--
-- procedure acs_rel_type__role_pretty_plural/1
--
CREATE OR REPLACE FUNCTION acs_rel_type__role_pretty_plural(
   role_pretty_plural__role varchar
) RETURNS varchar AS $$
DECLARE
  v_pretty_plural               acs_rel_roles.pretty_plural%TYPE;
BEGIN
    select r.pretty_plural into v_pretty_plural
      from acs_rel_roles r
     where r.role = role_pretty_plural__role;

    return v_pretty_plural;
   
END;
$$ LANGUAGE plpgsql stable strict;


-- procedure create_type


-- procedure create_type

--  acs_rel_type__create_type /15 vs. /16 has
--  /15 has no "roles" (one and two), but "type_extension_table"

-- /16
--   pos 1-7: same as /15
--   pos 08: object_type_one (varchar) 
--   pos 09: role_one (varchar) 
--   pos 10: min_n_rels_one (integer)
--   pos 11: max_n_rels (integer)
--   pos 12: object_type_one (varchar) 
--   pos 13: role_two (varchar) 
--   pos 14: min_n_rels_two (integer)
--   pos 15: max_n_rels_two (integer) 
--   pos 16: composable_p (boolean)

-- /15 
--   pos 1-7: same as /15
--   pos 08: type_extension_table (varchar)
--   pos 09: object_type_one (varchar) 
--   pos 10: min_n_rels_one (integer)
--   pos 11: max_n_rels (integer)
--   pos 12: object_type_two (varchar) 
--   pos 13: min_n_rels_two (integer)
--   pos 14: max_n_rels_two (integer) 
--   pos 15: composable_p (boolean)


select define_function_args('acs_rel_type__create_type','rel_type,pretty_name,pretty_plural,supertype;relationship,table_name,id_column,package_name,object_type_one,role_one;null,min_n_rels_one,max_n_rels_one,object_type_two,role_two;null,min_n_rels_two,max_n_rels_two,composable_p;t');

--
-- procedure acs_rel_type__create_type/16
--
CREATE OR REPLACE FUNCTION acs_rel_type__create_type(
   create_type__rel_type varchar,
   create_type__pretty_name varchar,
   create_type__pretty_plural varchar,
   create_type__supertype varchar, -- default 'relationship'
   create_type__table_name varchar,
   create_type__id_column varchar,
   create_type__package_name varchar,
   create_type__object_type_one varchar,
   create_type__role_one varchar,  -- default null
   create_type__min_n_rels_one integer,
   create_type__max_n_rels_one integer,
   create_type__object_type_two varchar,
   create_type__role_two varchar,  -- default null
   create_type__min_n_rels_two integer,
   create_type__max_n_rels_two integer,
   create_type__composable_p boolean default true

) RETURNS integer AS $$
DECLARE

  type_extension_table acs_object_types.type_extension_table%TYPE default null;
  abstract_p   acs_object_types.abstract_p%TYPE      default 'f';
  name_method  acs_object_types.name_method%TYPE     default null;     
BEGIN
    PERFORM acs_object_type__create_type(
      create_type__rel_type,
      create_type__pretty_name,
      create_type__pretty_plural,
      create_type__supertype,
      create_type__table_name,
      create_type__id_column,
      create_type__package_name,
      abstract_p,
      type_extension_table,
      name_method
    );

    insert into acs_rel_types
     (rel_type,
      object_type_one, role_one,
      min_n_rels_one, max_n_rels_one,
      object_type_two, role_two,
      min_n_rels_two, max_n_rels_two,
      composable_p)
    values
     (create_type__rel_type,
      create_type__object_type_one, create_type__role_one,
      create_type__min_n_rels_one, create_type__max_n_rels_one,
      create_type__object_type_two, create_type__role_two,
      create_type__min_n_rels_two, create_type__max_n_rels_two,
      create_type__composable_p);

    return 0; 
END;
$$ LANGUAGE plpgsql;





--
-- procedure acs_rel_type__create_type/15
--
CREATE OR REPLACE FUNCTION acs_rel_type__create_type(
   create_type__rel_type varchar,
   create_type__pretty_name varchar,
   create_type__pretty_plural varchar,
   create_type__supertype varchar,            -- default 'relationship'
   create_type__table_name varchar,
   create_type__id_column varchar,
   create_type__package_name varchar,
   create_type__type_extension_table varchar, -- default null
   create_type__object_type_one varchar,
   create_type__min_n_rels_one integer,
   create_type__max_n_rels_one integer,
   create_type__object_type_two varchar,
   create_type__min_n_rels_two integer,
   create_type__max_n_rels_two integer,
   create_type__composable_p boolean default true

) RETURNS integer AS $$
DECLARE

  abstract_p   acs_object_types.abstract_p%TYPE      default 'f';
  name_method  acs_object_types.name_method%TYPE     default null;     
  create_type__role_one  acs_rel_types.role_one%TYPE default null;           
  create_type__role_two  acs_rel_types.role_two%TYPE default null;
BEGIN

    PERFORM acs_object_type__create_type(
      create_type__rel_type,
      create_type__pretty_name,
      create_type__pretty_plural,
      create_type__supertype,
      create_type__table_name,
      create_type__id_column,
      create_type__package_name,
      abstract_p,
      create_type__type_extension_table,
      name_method
    );

    insert into acs_rel_types
     (rel_type,
      object_type_one, role_one,
      min_n_rels_one, max_n_rels_one,
      object_type_two, role_two,
      min_n_rels_two, max_n_rels_two,
      composable_p)
    values
     (create_type__rel_type,
      create_type__object_type_one, create_type__role_one,
      create_type__min_n_rels_one, create_type__max_n_rels_one,
      create_type__object_type_two, create_type__role_two,
      create_type__min_n_rels_two, create_type__max_n_rels_two,
      create_type__composable_p);

    return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure drop_type


-- added
select define_function_args('acs_rel_type__drop_type','rel_type,cascade_p;f');

--
-- procedure acs_rel_type__drop_type/2
--
CREATE OR REPLACE FUNCTION acs_rel_type__drop_type(
   drop_type__rel_type varchar,
   drop_type__cascade_p boolean -- default 'f'

) RETURNS integer AS $$
DECLARE
  v_cascade_p                       boolean;
BEGIN
    -- XXX do cascade_p.
    -- JCD: cascade_p seems to be ignored in acs_o_type__drop_type anyway...

    if drop_type__cascade_p is null then 
	v_cascade_p := 'f';
    else 
	v_cascade_p := drop_type__cascade_p;
    end if;

    delete from acs_rel_types
	  where rel_type = drop_type__rel_type;

    PERFORM acs_object_type__drop_type(drop_type__rel_type, 
                                       v_cascade_p);

    return 0; 
END;
$$ LANGUAGE plpgsql;



-- show errors
 select acs_rel_type__create_type (
   'relationship',
   'Relationship',
   'Relationships',
   'acs_object',
   'acs_rels',
   'rel_id',
   'acs_rel',
   'acs_rel_types',
   'acs_object',
   0,
   null::integer,
   'acs_object',
   0,
   null::integer
 );


-- show errors

--------------------------------------
-- OPERATIONAL LEVEL: RELATIONSHIPS --
--------------------------------------

create sequence t_acs_rel_id_seq;
create view acs_rel_id_seq as
select nextval('t_acs_rel_id_seq') as nextval;

create table acs_rels (
	rel_id		integer not null
			constraint acs_rels_rel_id_fk
			references acs_objects (object_id)
                        on delete cascade
			constraint acs_rels_rel_id_pk primary key,
	rel_type	varchar(100) not null
			constraint acs_rels_rel_type_fk
			references acs_rel_types (rel_type),
	object_id_one	integer not null
			constraint acs_rels_object_id_one_fk
			references acs_objects (object_id)
                        on delete cascade,
	object_id_two	integer not null
			constraint acs_rels_object_id_two_fk
			references acs_objects (object_id)
                        on delete cascade,
	constraint acs_object_rels_un unique
	(rel_type, object_id_one, object_id_two)
);

create index acs_rels_object_id_one_idx on acs_rels (object_id_one);
create index acs_rels_object_id_two_idx on acs_rels (object_id_two);

comment on table acs_rels is '
 The acs_rels table is essentially a generic mapping table for
 acs_objects. Once we come up with a way to associate attributes with
 relationship types, we could replace many of the ACS 3.x mapping
 tables like user_content_map, user_group_map, and
 user_group_type_modules_map with this one table. Much application
 logic consists of asking questions like "Does object X have a
 relationship of type Y to object Z?" where all that differs is
 X, Y, and Z. Thus, the value of consolidating many mapping tables
 into one is that we can provide a generic API for defining and
 querying relationships. In addition, we may need to design a way to
 enable "type_specific" storage for relationships (i.e., foreign key
 columns for one-to-many relationships and custom mapping tables for
 many-to-many relationships), instead of only supporting "generic"
 storage in the acs_rels table. This would parallel what we do with
 acs_attributes.
';


----------------------------
-- Application Data Links --
----------------------------

create sequence acs_data_links_seq start with 1;

create table acs_data_links (
        rel_id          integer not null
                        constraint acs_data_links_rel_id_pk primary key,
        object_id_one   integer not null
                        constraint acs_data_links_obj_one_fk
                        references acs_objects (object_id)
                        on delete cascade,
        object_id_two   integer not null
                        constraint acs_data_links_obj_two_fk
                        references acs_objects (object_id)
                        on delete cascade,
        relation_tag    varchar(100),
        constraint acs_data_links_un unique
        (object_id_one, object_id_two, relation_tag)
);

create index acs_data_links_id_one_idx on acs_data_links (object_id_one);
create index acs_data_links_id_two_idx on acs_data_links (object_id_two);
create index acs_data_links_rel_tag_idx on acs_data_links (relation_tag);


--------------
-- TRIGGERS --
--------------

-- added by oumi@arsdigita.com - Jan 11, 2001



--
-- procedure acs_rels_in_tr/0
--
CREATE OR REPLACE FUNCTION acs_rels_in_tr(

) RETURNS trigger AS $$
DECLARE
  dummy integer;
  target_object_type_one acs_object_types.object_type%TYPE;
  target_object_type_two acs_object_types.object_type%TYPE;
  actual_object_type_one acs_object_types.object_type%TYPE;
  actual_object_type_two acs_object_types.object_type%TYPE;
BEGIN

    -- DRB: The obvious rewrite to use Dan's port of this to use tree_ancestor_keys kills
    -- Postgres!!!  Argh!!!  This is fast, to, so there ...

    -- Get all the object type info from the relationship.

    select rt.object_type_one, rt.object_type_two,
           o1.object_type, o2.object_type
    into target_object_type_one, target_object_type_two,
         actual_object_type_one, actual_object_type_two
    from acs_rel_types rt, acs_objects o1, acs_objects o2
    where rt.rel_type = new.rel_type
      and o1.object_id = new.object_id_one
      and o2.object_id = new.object_id_two;

    if not exists (select 1
                    from 
                    (select tree_ancestor_keys(acs_object_type_get_tree_sortkey(actual_object_type_one))
                      as tree_sortkey) parents1,
                    (select tree_ancestor_keys(acs_object_type_get_tree_sortkey(actual_object_type_two))
                      as tree_sortkey) parents2,
                    (select tree_sortkey from acs_object_types where object_type = target_object_type_one)
                      root1,
                    (select tree_sortkey from acs_object_types where object_type = target_object_type_two)
                      root2
                   where root1.tree_sortkey = parents1.tree_sortkey
                     and root2.tree_sortkey = parents2.tree_sortkey) then

      raise EXCEPTION '-20001: %  violation: Invalid object types. Object % (%) must be of type % Object % (%) must be of type %', new.rel_type, 
                                         new.object_id_one,
                                         actual_object_type_one,
                                         target_object_type_one,
                                         new.object_id_two,
                                         actual_object_type_two,
                                         target_object_type_two;

    end if;

    return new;

END;
$$ LANGUAGE plpgsql;


 create trigger acs_rels_in_tr before insert or update on acs_rels
 for each row execute procedure acs_rels_in_tr ();

-- show errors


-- create or replace package acs_rel
-- as
-- 
--   function new (
--     rel_id		in acs_rels.rel_id%TYPE default null,
--     rel_type		in acs_rels.rel_type%TYPE default 'relationship',
--     object_id_one	in acs_rels.object_id_one%TYPE,
--     object_id_two	in acs_rels.object_id_two%TYPE,
--     context_id		in acs_objects.context_id%TYPE default null,
--     creation_user	in acs_objects.creation_user%TYPE default null,
-- x    creation_ip		in acs_objects.creation_ip%TYPE default null
--   ) return acs_rels.rel_id%TYPE;
-- 
--   procedure delete (
--     rel_id	in acs_rels.rel_id%TYPE
--   );
-- 
-- end;

-- show errors

-- create or replace package body acs_rel
-- function new


select define_function_args('acs_rel__new','rel_id;null,rel_type;relationship,object_id_one,object_id_two,context_id;null,creation_user;null,creation_ip;null');

--
-- procedure acs_rel__new/7
--
CREATE OR REPLACE FUNCTION acs_rel__new(
   new__rel_id integer,   -- default null
   new__rel_type varchar, -- default 'relationship'
   new__object_id_one integer,
   new__object_id_two integer,
   context_id integer,    -- default null
   creation_user integer, -- default null
   creation_ip varchar    -- default null

) RETURNS integer AS $$
DECLARE
  v_rel_id               acs_rels.rel_id%TYPE;
BEGIN
    v_rel_id := acs_object__new (
      new__rel_id,
      new__rel_type,
      now(),
      creation_user,
      creation_ip,
      context_id,
      't',
      new__rel_type || ': ' || new__object_id_one || ' - ' || new__object_id_two,
      null
    );

    insert into acs_rels
     (rel_id, rel_type, object_id_one, object_id_two)
    values
     (v_rel_id, new__rel_type, new__object_id_one, new__object_id_two);

    return v_rel_id;
   
END;
$$ LANGUAGE plpgsql;


-- procedure delete
select define_function_args('acs_rel__delete','rel_id');


--
-- procedure acs_rel__delete/1
--
CREATE OR REPLACE FUNCTION acs_rel__delete(
   rel_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    PERFORM acs_object__delete(rel_id);

    return 0; 
END;
$$ LANGUAGE plpgsql;

-----------
-- VIEWS --
-----------

-- These views are handy for metadata driven UI

-- View: rel_types_valid_obj_one_types
--
-- Question: Given rel_type :rel_type,
--
--           What are all the valid object_types for object_id_one of 
--           a relation of type :rel_type
--
-- Answer:   select object_type
--           from rel_types_valid_obj__one_types
--           where rel_type = :rel_type
--
create view rel_types_valid_obj_one_types as
select rt.rel_type, th.object_type
from acs_rel_types rt,
     (select object_type, ancestor_type
      from acs_object_type_supertype_map
      UNION ALL
      select object_type, object_type as ancestor_type 
      from acs_object_types) th
where rt.object_type_one = th.ancestor_type;

-- View: rel_types_valid_obj_two_types
--
-- Question: Given rel_type :rel_type,
--
--           What are all the valid object_types for object_id_two of 
--           a relation of type :rel_type
--
-- Answer:   select object_type
--           from rel_types_valid_obj_two_types
--           where rel_type = :rel_type
--
create view rel_types_valid_obj_two_types as
select rt.rel_type, th.object_type
from acs_rel_types rt,
     (select object_type, ancestor_type
      from acs_object_type_supertype_map
      UNION ALL
      select object_type, object_type as ancestor_type 
      from acs_object_types) th
where rt.object_type_two = th.ancestor_type;
