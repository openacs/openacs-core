--
-- acs-kernel/sql/acs-metadata-create.sql
--
-- A generic metadata system that allows table inheritance. This is
-- based in many ways on Problem Set 4 by Philip Greenspun
-- (philg@mit.edu), and the user-groups data model by Tracy Adams
-- (teadams@mit.edu).
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @author Rafael Schloming (rhs@mit.edu)
-- @author Jon Salz (jsalz@mit.edu)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$

-- ******************************************************************
-- * KNOWLEDGE LEVEL
-- ******************************************************************

------------------
-- OBJECT TYPES --
------------------

-- DRB: null table name change
create table acs_object_types (
	object_type	varchar(1000) not null
			constraint acs_object_types_pk primary key,
	supertype	varchar(1000) constraint acs_object_types_supertype_fk
			references acs_object_types (object_type),
	abstract_p	boolean default 'f' not null,
	pretty_name	varchar(1000) not null
			constraint acs_obj_types_pretty_name_un
			unique,
	pretty_plural	varchar(1000) not null
			constraint acs_obj_types_pretty_plural_un
			unique,
	table_name	varchar(30)
                        constraint acs_object_types_table_name_un unique,
	id_column	varchar(30),
	package_name	varchar(30) not null
			constraint acs_object_types_pkg_name_un unique,
	name_method	varchar(100),
	type_extension_table varchar(30),
        dynamic_p       boolean default 'f',
        tree_sortkey    varbit,
	constraint acs_object_types_table_id_name_ck
	check ((table_name is null and id_column is null) or
               (table_name is not null and id_column is not null))
);

create index acs_obj_types_supertype_idx on acs_object_types (supertype);
create index acs_obj_types_tree_skey_idx on acs_object_types (tree_sortkey);

-- support for tree queries on acs_object_types



-- added
select define_function_args('acs_object_type_get_tree_sortkey','object_type');

--
-- procedure acs_object_type_get_tree_sortkey/1
--
CREATE OR REPLACE FUNCTION acs_object_type_get_tree_sortkey(
   p_object_type varchar
) RETURNS varbit AS $$
DECLARE
BEGIN
  return tree_sortkey from acs_object_types where object_type = p_object_type;
END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_object_type_insert_tr/0
--
CREATE OR REPLACE FUNCTION acs_object_type_insert_tr(

) RETURNS trigger AS $$
DECLARE
        v_parent_sk     varbit default null;
        v_max_value     integer;
BEGIN
        select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value 
          from acs_object_types 
         where supertype = new.supertype;

        select tree_sortkey into v_parent_sk 
          from acs_object_types 
         where object_type = new.supertype;

        new.tree_sortkey := tree_next_key(v_parent_sk ,v_max_value);

        return new;

END;
$$ LANGUAGE plpgsql stable strict;

create trigger acs_object_type_insert_tr before insert 
on acs_object_types for each row 
execute procedure acs_object_type_insert_tr ();



--
-- procedure acs_object_type_update_tr/0
--
CREATE OR REPLACE FUNCTION acs_object_type_update_tr(

) RETURNS trigger AS $$
DECLARE
        v_parent_sk     varbit default null;
        v_max_value     integer;
        v_rec           record;
        clr_keys_p      boolean default 't';
BEGIN
        if new.object_type = old.object_type and 
           ((new.supertype = old.supertype) or 
            (new.supertype is null and old.supertype is null)) then

           return new;

        end if;

        for v_rec in select object_type, supertype
                       from acs_object_types 
                      where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey)
                   order by tree_sortkey
        LOOP
            if clr_keys_p then
               update acs_object_types set tree_sortkey = null
               where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);
               clr_keys_p := 'f';
            end if;
            
            select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
              from acs_object_types 
              where supertype = v_rec.supertype;

            select tree_sortkey into v_parent_sk 
              from acs_object_types 
             where object_type = v_rec.supertype;

            update acs_object_types 
               set tree_sortkey = tree_next_key(v_parent_sk, v_max_value)
             where object_type = v_rec.object_type;

        end LOOP;

        return new;

END;
$$ LANGUAGE plpgsql;

create trigger acs_object_type_update_tr after update 
on acs_object_types
for each row 
execute procedure acs_object_type_update_tr ();

comment on table acs_object_types is '
 Each row in the acs_object_types table represents a distinct class
 of objects. For each instance of any acs_object_type, there is a
 corresponding row in the acs_objects table. Essentially,
 acs_objects.object_id supersedes the on_which_table/on_what_id pair
 that ACS 3.x used as the system-wide identifier for heterogeneous
 objects. The value of having a system-wide identifier for
 heterogeneous objects is that it helps us provide general solutions
 for common problems like access control, workflow, categorppization,
 and search. (Note that this framework is not overly restrictive,
 because it doesn''t force every type of object to be represented in
 the acs_object_types table.) Each acs_object_type has:
 * Attributes (stored in the acs_attributes table)
   Examples:
   * the "user" object_type has "email" and "password" attributes
   * the "content_item" object_type has "title" and "body" attributes
 * Relationship types (stored in the acs_rel_types table)
   Examples:
   * "a team has one team leader who is a user" (in other words,
     instances of the "team" object_type must have one "team leader"
     relationship to an instance of the "user" object_type)
   * "a content item may have zero or authors who are people or
     organizations, i.e., parties" (in other words, instances of
     the "content_item" object_type may have zero or more "author"
     relationships to instances of the "party" object_type)
 Possible extensions include automatic versioning, logical deletion,
 and auditing.
';

comment on column acs_object_types.supertype is '
 The object_type of which this object_type is a specialization (if
 any). For example, the supertype of the "user" object_type is
 "person". An object_type inherits the attributes and relationship
 rules of its supertype, though it can add constraints to the
 attributes and/or it can override the relationship rules. For
 instance, the "person" object_type has an optional "email" attribute,
 while its "user" subtype makes "email" mandatory.
';

comment on column acs_object_types.abstract_p is '
 ...
 If the object_type is not abstract, then all of its attributes must
 have a non-null storage specified.
';

comment on column acs_object_types.table_name is '
 The name of the type-specific table in which the values of attributes
 specific to this object_type are stored, if any.
';

comment on column acs_object_types.id_column is '
 The name of the primary key column in the table identified by
 table_name.
';

comment on column acs_object_types.name_method is '
 The name of a stored function that takes an object_id as an argument
 and returns a varchar2: the corresponding object name. This column is
 required to implement the polymorphic behavior of the acs.object_name()
 function.
';

comment on column acs_object_types.type_extension_table is '
 Object types (and their subtypes) that require more type-specific
 data than the fields already existing in acs_object_types may name
 a table in which that data is stored.  The table should be keyed
 by the associated object_type.  For example, a row in the group_types
 table stores a default approval policy for every user group of that type.
 In this example, the group_types table has a primary key named
 group_type that references acs_object_types.  If a subtype of groups
 for example, lab_courses, has its own type-specific data, it could be
 maintained in a table called lab_course_types, with a primary key named
 lab_course_type that references group_types.  This provides the same
 functionality as static class fields in an object-oriented programming language.
';


comment on column acs_object_types.dynamic_p is '
  This flag is used to identify object types created dynamically
  (e.g. through a web interface). Dynamically created object types can
  be administered differently. For example, the group type admin pages
  only allow users to add attributes or otherwise modify dynamic
  object types. This column is still experimental and may not be supported in the
  future. That is the reason it is not yet part of the API.
';

-- create view acs_object_type_supertype_map
-- as select ot.object_type, ota.object_type as ancestor_type
--   from acs_object_types ot, acs_object_types ota
--   where ota.object_type in (select object_type
--                             from acs_object_types
--                             start with object_type = ot.supertype
--                             connect by object_type = prior supertype);

create view acs_object_type_supertype_map
as select ot1.object_type, ot2.object_type as ancestor_type
     from acs_object_types ot1,
	  acs_object_types ot2
    where ot1.object_type <> ot2.object_type
      and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey);

create table acs_object_type_tables (
	object_type	varchar(1000) not null 
                        constraint acs_obj_type_tbls_obj_type_fk
			references acs_object_types (object_type),
	table_name	varchar(30) not null,
	id_column	varchar(30),
	constraint acs_object_type_tables_pk
	primary key (object_type, table_name)
);

create index acs_objtype_tbls_objtype_idx on acs_object_type_tables (object_type);

comment on table acs_object_type_tables is '
 This table is used for objects that want to vertically partition
 their data storage, for example user_demographics stores a set of
 optional columns that belong to a user object.
';

comment on column acs_object_type_tables.id_column is '
 If this is null then the id column is assumed to have the same name
 as the primary table.
';

------------------------------------
-- DATATYPES AND ATTRIBUTES --
------------------------------------

create table acs_datatypes (
	datatype	varchar(50) not null
			constraint acs_datatypes_datatype_pk primary key,
	max_n_values	integer default 1
			constraint acs_datatypes_max_n_values_ck
			check (max_n_values > 0),
        database_type   text,
        column_size     text,
        column_check_expr text,
        column_output_function text
);

comment on table acs_datatypes is '
 Defines the set of available abstract datatypes for acs_attributes, along with
 an optional default mapping to a database type, size, and constraint to use if the
 attribute is created with create_attribute''s storage_type param set to "type_specific"
 and the create_storage_p param is set to true.  These defaults can be overwritten by
 the caller.

 The set of pre-defined datatypes is inspired by XForms
 (http://www.w3.org/TR/xforms-datamodel/).
';

comment on column acs_datatypes.max_n_values is '
 The maximum number of values that any attribute with this datatype
 can have. Of the predefined attribute types, only "boolean" specifies
 a non-null max_n_values, because it doesn''t make sense to have a
 boolean attribute with more than one value. There is no
 corresponding min_n_values column, because each attribute may be
 optional, i.e., min_n_values would always be zero.
';

comment on column acs_datatypes.database_type is '
  The base database type corresponding to the abstract datatype.  For example "varchar" or
  "integer".
';

comment on column acs_datatypes.column_size is '
  Optional default column size specification to append to the base database type.  For
  example "1000" for the "string" abstract datatype, or "10,2" for "number".
';

comment on column acs_datatypes.column_check_expr is '
  Optional check constraint expression to declare for the type_specific database column.  In
  Oracle, for instance, the abstract "boolean" type is declared "text", with a column
  check expression to restrict the values to "f" and "t".
';

comment on column acs_datatypes.column_output_function is '
  Function to call for this datatype when building a select view.  If not null, it will
  be called with an attribute name and is expected to return an expression on that
  attribute.  Example: date attributes will be transformed to calls to "to_char()".
';


-- Load pre-defined datatypes.
--
begin;
 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('string', null, 'varchar', '4000');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('boolean', 1, 'bool', null);

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('number', null, 'numeric', '10,2');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('integer', 1, 'integer', null);

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('currency', null, 'money', null);

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_output_function)
 values
  ('date', null, 'timestamp', 'acs_datatype__date_output_function');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_output_function)
 values
  ('timestamp', null, 'timestamp', 'acs_datatype__timestamp_output_function');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_output_function)
 values
  ('time_of_day', null, 'timestamp', 'acs_datatype__timestamp_output_function');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('enumeration', null, 'varchar', '100');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('url', null, 'varchar', '250');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('email', null, 'varchar', '200');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('file', 1, 'varchar', '100');

insert into acs_datatypes
 (datatype, max_n_values, database_type, column_size)
values
 ('text', null, 'text', null);

insert into acs_datatypes
  (datatype, max_n_values, database_type)
values
  ('keyword', 1, 'text');

insert into acs_datatypes
 (datatype, max_n_values, database_type, column_size)
values
 ('richtext', null, 'text', null);

insert into acs_datatypes
 (datatype, max_n_values, database_type, column_size)
values
 ('filename', null, 'varchar', '100');

insert into acs_datatypes
 (datatype, max_n_values, database_type, column_size)
values
 ('float', null, 'float8', null);

-- PG 8.x has no unsigned integer datatype
insert into acs_datatypes
 (datatype, max_n_values, database_type, column_size)
values
 ('naturalnum', null, 'integer', null);

end;

--create table acs_input_types (
--);

create sequence t_acs_attribute_id_seq;
create view acs_attribute_id_seq as
select nextval('t_acs_attribute_id_seq') as nextval;

create table acs_attributes (
	attribute_id	integer not null
			constraint acs_attributes_attribute_id_pk
			primary key,
	object_type	varchar(1000) not null
			constraint acs_attributes_object_type_fk
			references acs_object_types (object_type),
	table_name	varchar(30),
	constraint acs_attrs_obj_type_tbl_name_fk
	foreign key (object_type, table_name) 
        references acs_object_type_tables,
	attribute_name	varchar(100) not null,
	pretty_name	varchar(100) not null,
	pretty_plural	varchar(100),
	sort_order	integer not null,
	datatype	varchar(50) not null
			constraint acs_attributes_datatype_fk
			references acs_datatypes (datatype) on update cascade,
	default_value	text,
	min_n_values	integer default 1 not null
			constraint acs_attributes_min_n_values_ck
			check (min_n_values >= 0),
	max_n_values	integer default 1 not null
			constraint acs_attributes_max_n_values_ck
			check (max_n_values >= 0),
	storage 	varchar(13) default 'type_specific'
			constraint acs_attributes_storage_ck
			check (storage in ('type_specific',
					   'generic')),
        static_p        boolean default 'f',
	column_name	varchar(30),
	constraint acs_attributes_attr_name_un
	unique (attribute_name, object_type),
	constraint acs_attributes_pretty_name_un
	unique (pretty_name, object_type),
	constraint acs_attributes_sort_order_un
	unique (attribute_id, sort_order),
	constraint acs_attributes_n_values_ck
	check (min_n_values <= max_n_values)
);
-- constraint acs_attrs_pretty_plural_un
-- unique (pretty_plural, object_type),

create index acs_attrs_obj_type_idx on acs_attributes (object_type);
create index acs_attrs_tbl_name_idx on acs_attributes (table_name);
create index acs_attrs_datatype_idx on acs_attributes (datatype);

comment on table acs_attributes is '
 Each row in the <code>acs_attributes</code> table defines an
 attribute of the specified object type. Each object of this type
 must have a minimum of min_n_values values and a maximum of
 max_n_values for this attribute.
';

comment on column acs_attributes.table_name is '
 If the data storage for the object type is arranged in a vertically
 partitioned manner, then this column should indicate in which table
 the attribute is stored.
';

comment on column acs_attributes.storage is '
 Indicates how values of this attribute are stored: either
 "type_specific" (i.e., in the table identified by
 object_type.table_name) or "generic" (i.e., in the
 acs_attribute_values table). (Or we could just have a column_name and,
 if it''s null, then assume that we''re using acs_attribute_values.)
';

comment on column acs_attributes.static_p is '
 Determines whether this attribute is static. If so, only one copy of
 the attribute''s value exists for all objects of the same type. This
 value is stored in acs_static_attr_values table if storage_type is
 "generic". Otherwise, each object of this type can have its own
 distinct value for the attribute.
';

comment on column acs_attributes.column_name is '
 If storage is "type_specific", column_name identifies the column in
 the table identified by object_type.table_name that holds the values
 of this attribute. If column_name is null, then we assume that
 attribute_name identifies a column in the table identified by
 object_type.table_name.
';

create table acs_enum_values (
	attribute_id	integer not null
			constraint asc_enum_values_attr_id_fk
			references acs_attributes (attribute_id),
	enum_value	varchar(1000),
	pretty_name	varchar(100) not null,
	sort_order	integer not null,
	constraint acs_enum_values_pk
	primary key (attribute_id, enum_value),
	constraint acs_enum_values_pretty_name_un
	unique (attribute_id, pretty_name),
	constraint acs_enum_values_sort_order_un
	unique (attribute_id, sort_order)
);

create index acs_enum_values_attr_id_idx on acs_enum_values (attribute_id);

create table acs_attribute_descriptions (
	object_type	varchar(1000) not null constraint acs_attr_descs_obj_type_fk
			references acs_object_types (object_type),
	attribute_name  varchar(100) not null,
	constraint acs_attr_descs_ob_tp_at_na_fk
	foreign key (object_type, attribute_name)
	references acs_attributes (object_type, attribute_name),
	description_key varchar(100),
	constraint acs_attribute_descriptions_pk
	primary key (object_type, attribute_name, description_key),
	description	text not null
);

create index acs_attr_desc_obj_type_idx on acs_attribute_descriptions (object_type);
create index acs_attr_desc_attr_name_idx on acs_attribute_descriptions (attribute_name);


-- Create a view to show us all the attributes for one object,
-- including attributes for each of its supertypes

-- Note that the internal union is required to get attributes for the
-- object type we specify. Without this union, we would get attributes
-- for all supertypes, but not for the specific type in question

-- Note also that we cannot select attr.* in the view because the
-- object_type in the attributes table refers to one attribute (kind
-- of like the owner of the attribute). That object_type is really the
-- ancestor type... that is, the ancestor of the user-specified object
-- type for which the attribute should be specified.

create view acs_object_type_attributes as 
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

-----------------------
-- METADATA PACKAGES --
-----------------------


select define_function_args('acs_object_type__create_type','object_type,pretty_name,pretty_plural,supertype,table_name;null,id_column;null,package_name;null,abstract_p;f,type_extension_table;null,name_method;null,create_table_p;f,dynamic_p;f');

--
-- procedure acs_object_type__create_type/12
--
CREATE OR REPLACE FUNCTION acs_object_type__create_type(
   p_object_type varchar,
   p_pretty_name varchar,
   p_pretty_plural varchar,
   p_supertype varchar,
   p_table_name varchar,           -- default null
   p_id_column varchar,            -- default null
   p_package_name varchar,         -- default null
   p_abstract_p boolean,           -- default 'f'
   p_type_extension_table varchar, -- default null
   p_name_method varchar,          -- default null
   p_create_table_p boolean,       -- default 'f'
   p_dynamic_p boolean             -- default 'f'

) RETURNS integer AS $$
DECLARE
  v_package_name                      acs_object_types.package_name%TYPE;
  v_supertype                         acs_object_types.supertype%TYPE;
  v_name_method                       varchar;
  v_idx                               integer;
  v_temp_p                            boolean;
  v_supertype_table                   acs_object_types.table_name%TYPE;
  v_id_column                         acs_object_types.id_column%TYPE;
  v_table_name                        acs_object_types.table_name%TYPE;
BEGIN
    v_idx := position('.' in p_name_method);
    if v_idx <> 0 then
         v_name_method := substr(p_name_method,1,v_idx - 1) || 
                       '__' || substr(p_name_method, v_idx + 1);
    else 
         v_name_method := p_name_method;
    end if;

    -- If we are asked to create the table, provide reasonable default values for the
    -- table name and id column.  Traditionally OpenACS uses the plural form of the type
    -- name.  This code appends "_t" (for "table") because the use of english plural rules
    -- does not work well for all languages.

    if p_create_table_p and (p_table_name is null or p_table_name = '') then
      v_table_name := p_object_type || '_t';
    else
      v_table_name := p_table_name;
    end if;

    if p_create_table_p and (p_id_column is null or p_id_column = '') then
      v_id_column := p_object_type || '_id';
    else
      v_id_column := p_id_column;
    end if;

    if p_package_name is null or p_package_name = '' then
      v_package_name := p_object_type;
    else
      v_package_name := p_package_name;
    end if;

    if p_object_type <> 'acs_object' then
      if p_supertype is null or p_supertype = '' then
        v_supertype := 'acs_object';
      else
        v_supertype := p_supertype;
        if not acs_object_type__is_subtype_p('acs_object', p_supertype) then
          raise exception '%s is not a valid type', p_supertype;
        end if;
      end if;
    end if;

    insert into acs_object_types
      (object_type, pretty_name, pretty_plural, supertype, table_name,
       id_column, abstract_p, type_extension_table, package_name,
       name_method, dynamic_p)
    values
      (p_object_type, p_pretty_name, 
       p_pretty_plural, v_supertype, 
       v_table_name, v_id_column, 
       p_abstract_p, p_type_extension_table, 
       v_package_name, v_name_method, p_dynamic_p);

    if p_create_table_p then

      if exists (select 1
                 from pg_class
                 where relname = lower(v_table_name)) then
        raise exception 'Table "%" already exists', v_table_name;
      end if;

      loop
        select table_name,object_type into v_supertype_table,v_supertype
        from acs_object_types
        where object_type = v_supertype;
        exit when v_supertype_table is not null;
      end loop;
  
      execute 'create table ' || v_table_name || ' (' ||
        v_id_column || ' integer constraint ' || v_table_name ||
        '_pk primary key ' || ' constraint ' || v_table_name ||
        '_fk references ' || v_supertype_table || ' on delete cascade)';
    end if;

    return 0; 
END;
$$ LANGUAGE plpgsql;

-- DRB: backwards compatibility version, don't allow for table creation.



--
-- procedure acs_object_type__create_type/10
--
CREATE OR REPLACE FUNCTION acs_object_type__create_type(
   p_object_type varchar,
   p_pretty_name varchar,
   p_pretty_plural varchar,
   p_supertype varchar,
   p_table_name varchar,           -- default null
   p_id_column varchar,            -- default null
   p_package_name varchar,         -- default null
   p_abstract_p boolean,           -- default 'f'
   p_type_extension_table varchar, -- default null
   p_name_method varchar           -- default null

) RETURNS integer AS $$
--
-- acs_object_type__create_type/10 maybe obsolete, when we define proper defaults for /12
--
DECLARE
BEGIN
    return acs_object_type__create_type(p_object_type, p_pretty_name,
      p_pretty_plural, p_supertype, p_table_name,
      p_id_column, p_package_name, p_abstract_p,
      p_type_extension_table, p_name_method,'f','f');
END;
$$ LANGUAGE plpgsql;


-- old define_function_args('acs_object_type__drop_type','object_type,drop_table_p;f,drop_children_p;f')
-- new
select define_function_args('acs_object_type__drop_type','object_type,drop_children_p;f,drop_table_p;f');


-- procedure drop_type


--
-- procedure acs_object_type__drop_type/3
--
CREATE OR REPLACE FUNCTION acs_object_type__drop_type(
   p_object_type varchar,
   p_drop_children_p boolean, -- default 'f'
   p_drop_table_p boolean     -- default 'f'

) RETURNS integer AS $$
DECLARE
  row                               record;
  object_row                        record;
  v_table_name                      acs_object_types.table_name%TYPE;
BEGIN

  -- drop children recursively
  if p_drop_children_p then
    for row in select object_type
               from acs_object_types
               where supertype = p_object_type 
    loop
      perform acs_object_type__drop_type(row.object_type, 't', p_drop_table_p);
    end loop;
  end if;

  -- drop all the attributes associated with this type
  for row in select attribute_name 
             from acs_attributes 
             where object_type = p_object_type 
  loop
    perform acs_attribute__drop_attribute (p_object_type, row.attribute_name);
  end loop;

  -- Remove the associated table if it exists and p_drop_table_p is true

  if p_drop_table_p then

    select table_name into v_table_name 
    from acs_object_types 
    where object_type = p_object_type;

    if found then
      if not exists (select 1
                     from pg_class
                     where relname = lower(v_table_name)) then
        raise exception 'Table "%" does not exist', v_table_name;
      end if;

      execute 'drop table ' || v_table_name || ' cascade';
    end if;

  end if;

  delete from acs_object_types
  where object_type = p_object_type;

  return 0; 
END;
$$ LANGUAGE plpgsql;

-- Retained for backwards compatibility

CREATE OR REPLACE FUNCTION acs_object_type__drop_type (varchar,boolean) RETURNS integer AS $$
BEGIN
  return acs_object_type__drop_type($1,$2,'f');
END;
$$ LANGUAGE plpgsql;

-- function pretty_name


-- added
select define_function_args('acs_object_type__pretty_name','object_type');

--
-- procedure acs_object_type__pretty_name/1
--
CREATE OR REPLACE FUNCTION acs_object_type__pretty_name(
   pretty_name__object_type varchar
) RETURNS varchar AS $$
DECLARE
  v_pretty_name                       acs_object_types.pretty_name%TYPE;
BEGIN
    select t.pretty_name into v_pretty_name
      from acs_object_types t
     where t.object_type = pretty_name__object_type;

    return v_pretty_name;
   
END;
$$ LANGUAGE plpgsql stable strict;


-- function is_subtype_p


-- added
select define_function_args('acs_object_type__is_subtype_p','object_type_1,object_type_2');

--
-- procedure acs_object_type__is_subtype_p/2
--
CREATE OR REPLACE FUNCTION acs_object_type__is_subtype_p(
   is_subtype_p__object_type_1 varchar,
   is_subtype_p__object_type_2 varchar
) RETURNS boolean AS $$
DECLARE
  v_result                             integer;       
BEGIN
    select count(*) into v_result
     where exists (select 1
                     from acs_object_types t, acs_object_types t2
                    where t.object_type = is_subtype_p__object_type_2
                      and t2.object_type = is_subtype_p__object_type_1
                      and t.tree_sortkey between t2.tree_sortkey and tree_right(t2.tree_sortkey));

    if v_result > 0 then
       return 't';
    end if;

    return 'f';

END;
$$ LANGUAGE plpgsql stable;


-- old define_function_args('acs_attribute__create_attribute','object_type,attribute_name,datatype,pretty_name,pretty_plural,table_name,column_name,default_value,min_n_values;1,max_n_values;1,sort_order,storage;type_specific,static_p;f,create_column_p;f,database_type,size,null_p;t,references,check_expr,column_spec')
-- new
select define_function_args('acs_attribute__create_attribute','object_type,attribute_name,datatype,pretty_name,pretty_plural;null,table_name;null,column_name;null,default_value;null,min_n_values;1,max_n_values;1,sort_order;null,storage;type_specific,static_p;f,create_column_p;f,database_type;null,size;null,null_p;t,references;null,check_expr;null,column_spec;null');




--
-- procedure acs_attribute__create_attribute/20
--
CREATE OR REPLACE FUNCTION acs_attribute__create_attribute(
   p_object_type varchar,
   p_attribute_name varchar,
   p_datatype varchar,
   p_pretty_name varchar,
   p_pretty_plural varchar,   -- default null
   p_table_name varchar,      -- default null
   p_column_name varchar,     -- default null
   p_default_value varchar,   -- default null
   p_min_n_values integer,    -- default 1 -- default '1'
   p_max_n_values integer,    -- default 1 -- default '1'
   p_sort_order integer,      -- default null
   p_storage varchar,         -- default 'type_specific'
   p_static_p boolean,        -- default 'f'
   p_create_column_p boolean, -- default 'f'
   p_database_type varchar,   -- default null
   p_size varchar,            -- default null
   p_null_p boolean,          -- default 't'
   p_references varchar,      -- default null
   p_check_expr varchar,      -- default null
   p_column_spec varchar      -- default null

) RETURNS integer AS $$
DECLARE

  v_sort_order            acs_attributes.sort_order%TYPE;
  v_attribute_id          acs_attributes.attribute_id%TYPE;
  v_column_spec           text;
  v_table_name            text;
  v_constraint_stub       text;
  v_column_name           text;
  v_datatype              record;

BEGIN

  if not exists (select 1
                 from acs_object_types
                 where object_type = p_object_type) then
    raise exception 'Object type % does not exist', p_object_type;
  end if; 

  if p_sort_order is null then
    select coalesce(max(sort_order), 1) into v_sort_order
    from acs_attributes
    where object_type = p_object_type
    and attribute_name = p_attribute_name;
  else
    v_sort_order := p_sort_order;
  end if;

  select nextval('t_acs_attribute_id_seq') into v_attribute_id;

  insert into acs_attributes
    (attribute_id, object_type, table_name, column_name, attribute_name,
     pretty_name, pretty_plural, sort_order, datatype, default_value,
     min_n_values, max_n_values, storage, static_p)
  values
    (v_attribute_id, p_object_type, 
     p_table_name, p_column_name, 
     p_attribute_name, p_pretty_name,
     p_pretty_plural, v_sort_order, 
     p_datatype, p_default_value,
     p_min_n_values, p_max_n_values, 
     p_storage, p_static_p);

  if p_create_column_p then

    select table_name into v_table_name from acs_object_types
    where object_type = p_object_type;

    if not exists (select 1
                   from pg_class
                   where relname = lower(v_table_name)) then
      raise exception 'Table % for object type % does not exist', v_table_name, p_object_type;
    end if;

    -- Add the appropriate column to the table

    -- We can only create the table column if
    -- 1. the attribute is declared type_specific (generic storage uses an auxiliary table)
    -- 2. the attribute is not declared static
    -- 3. it does not already exist in the table

    if p_storage <> 'type_specific' then
      raise exception 'Attribute % for object type % must be declared with type_specific storage',
        p_attribute_name, p_object_type;
    end if;

    if p_static_p then
      raise exception 'Attribute % for object type % can not be declared static',
        p_attribute_name, p_object_type;
    end if;

    if p_table_name is not null then
      raise exception 'Attribute % for object type % can not specify a table for storage', p_attribute_name, p_object_type;
    end if;

    if exists (select 1
               from pg_class c, pg_attribute a
               where c.relname::varchar = v_table_name
                 and c.oid = a.attrelid
                 and a.attname = lower(p_attribute_name)) then
      raise exception 'Column % for object type % already exists',
        p_attribute_name, p_object_type;
    end if;

    -- all conditions for creating this column have been met, now let's see if the type
    -- spec is OK

    if p_column_spec is not null then
      if p_database_type is not null
        or p_size is not null
        or p_null_p is not null
        or p_references is not null
        or p_check_expr is not null then
      raise exception 'Attribute % for object type % is being created with an explicit column_spec, but not all of the type modification fields are null',
        p_attribute_name, p_object_type;
      end if;
      v_column_spec := p_column_spec;
    else
      select coalesce(p_database_type, database_type) as database_type,
        coalesce(p_size, column_size) as column_size,
        coalesce(p_check_expr, column_check_expr) as check_expr
      into v_datatype
      from acs_datatypes
      where datatype = p_datatype;
  
      v_column_spec := v_datatype.database_type;

      if v_datatype.column_size is not null then
        v_column_spec := v_column_spec || '(' || v_datatype.column_size || ')';
      end if;

      v_constraint_stub := ' constraint ' || p_object_type || '_' ||
        p_attribute_name || '_';

      if v_datatype.check_expr is not null then
        v_column_spec := v_column_spec || v_constraint_stub || 'ck check(' ||
          p_attribute_name || v_datatype.check_expr || ')';
      end if;

      if not p_null_p then
        v_column_spec := v_column_spec || v_constraint_stub || 'nn not null';
      end if;

      if p_references is not null then
        v_column_spec := v_column_spec || v_constraint_stub || 'fk references ' ||
          p_references || ' on delete';
        if p_null_p then
          v_column_spec := v_column_spec || ' set null';
        else
          v_column_spec := v_column_spec || ' cascade';
        end if;
      end if;

    end if;
        
    execute 'alter table ' || v_table_name || ' add ' || p_attribute_name || ' ' ||
            v_column_spec;

  end if;

  return v_attribute_id;

END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_attribute__create_attribute/13
--
CREATE OR REPLACE FUNCTION acs_attribute__create_attribute(
   p_object_type varchar,
   p_attribute_name varchar,
   p_datatype varchar,
   p_pretty_name varchar,
   p_pretty_plural varchar, -- default null
   p_table_name varchar,    -- default null
   p_column_name varchar,   -- default null
   p_default_value varchar, -- default null
   p_min_n_values integer,  -- default 1
   p_max_n_values integer,  -- default 1
   p_sort_order integer,    -- default null
   p_storage varchar,       -- default 'type_specific'
   p_static_p boolean       -- default 'f'

) RETURNS integer AS $$
--
-- acs_attribute__create_attribute/13 maybe obsolete, when we define proper defaults for /20
--
DECLARE
BEGIN
  return acs_attribute__create_attribute(p_object_type,
    p_attribute_name, p_datatype, p_pretty_name,
    p_pretty_plural, p_table_name, p_column_name,
    p_default_value, p_min_n_values,
    p_max_n_values, p_sort_order, p_storage,
    p_static_p, 'f', null, null, null, null, null, null);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION acs_attribute__create_attribute (varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer,integer,integer,varchar,boolean) RETURNS integer AS $$
BEGIN
    return acs_attribute__create_attribute ($1, $2, $3, $4, $5, $6, $7, cast ($8 as varchar), $9, $10, $11, $12, $13);
END;
$$ LANGUAGE plpgsql;

-- procedure drop_attribute
select define_function_args('acs_attribute__drop_attribute','object_type,attribute_name,drop_column_p;f');



--
-- procedure acs_attribute__drop_attribute/3
--
CREATE OR REPLACE FUNCTION acs_attribute__drop_attribute(
   p_object_type varchar,
   p_attribute_name varchar,
   p_drop_column_p boolean -- default 'f'

) RETURNS integer AS $$
DECLARE
  v_table_name             acs_object_types.table_name%TYPE;
BEGIN

  -- Check that attribute exists and simultaneously grab the type's table name
  select t.table_name into v_table_name
  from acs_object_types t, acs_attributes a
  where a.object_type = p_object_type
    and a.attribute_name = p_attribute_name
    and t.object_type = p_object_type;
    
  if not found then
    raise exception 'Attribute %:% does not exist', p_object_type, p_attribute_name;
  end if;

  -- first remove possible values for the enumeration
  delete from acs_enum_values
  where attribute_id in (select a.attribute_id 
                         from acs_attributes a 
                         where a.object_type = p_object_type
                         and a.attribute_name = p_attribute_name);

  -- Drop the table if one were specified for the type and we're asked to
  if p_drop_column_p and v_table_name is not null then
      execute 'alter table ' || v_table_name || ' drop column ' ||
        p_attribute_name || ' cascade';
  end if;  

  -- Finally, get rid of the attribute
  delete from acs_attributes
  where object_type = p_object_type
  and attribute_name = p_attribute_name;

  return 0; 
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION acs_attribute__drop_attribute (varchar,varchar) RETURNS integer AS $$
BEGIN
  return acs_attribute__drop_attribute($1, $2, 'f');
END;
$$ LANGUAGE plpgsql;


select define_function_args('acs_attribute__add_description','object_type,attribute_name,description_key,description');
-- procedure add_description


--
-- procedure acs_attribute__add_description/4
--
CREATE OR REPLACE FUNCTION acs_attribute__add_description(
   add_description__object_type varchar,
   add_description__attribute_name varchar,
   add_description__description_key varchar,
   add_description__description text
) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_attribute_descriptions
     (object_type, attribute_name, description_key, description)
    values
     (add_description__object_type, add_description__attribute_name,
      add_description__description_key, add_description__description);

    return 0; 
END;
$$ LANGUAGE plpgsql;

select define_function_args('acs_attribute__drop_description','object_type,attribute_name,description_key');
-- procedure drop_description


--
-- procedure acs_attribute__drop_description/3
--
CREATE OR REPLACE FUNCTION acs_attribute__drop_description(
   drop_description__object_type varchar,
   drop_description__attribute_name varchar,
   drop_description__description_key varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from acs_attribute_descriptions
    where object_type = drop_description__object_type
    and attribute_name = drop_description__attribute_name
    and description_key = drop_description__description_key;

    return 0; 
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('acs_datatype__date_output_function','attribute_name');

--
-- procedure acs_datatype__date_output_function/1
--
CREATE OR REPLACE FUNCTION acs_datatype__date_output_function(
   p_attribute_name text
) RETURNS text AS $$
DECLARE
BEGIN
  return 'to_char(' || p_attribute_name || ', ''YYYY-MM-DD'')';
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('acs_datatype__timestamp_output_function','attribute_name');

--
-- procedure acs_datatype__timestamp_output_function/1
--
CREATE OR REPLACE FUNCTION acs_datatype__timestamp_output_function(
   p_attribute_name text
) RETURNS text AS $$
DECLARE
BEGIN
  return 'to_char(' || p_attribute_name || ', ''YYYY-MM-DD HH24:MI:SS'')';
END;
$$ LANGUAGE plpgsql;

-- show errors
