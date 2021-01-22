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
--

-- ******************************************************************
-- * KNOWLEDGE LEVEL
-- ******************************************************************

------------------
-- OBJECT TYPES --
------------------

create table acs_object_types (
	object_type	varchar2(1000) not null
			constraint acs_object_types_pk primary key,
	supertype	constraint acs_object_types_supertype_fk
			references acs_object_types (object_type),
	abstract_p	char(1) default 'f' 
			constraint acs_object_types_abstract_p_nn not null
			constraint acs_object_types_abstract_p_ck
			check (abstract_p in ('t', 'f')),
	pretty_name	varchar2(1000) not null
			constraint acs_obj_types_pretty_name_un
			unique,
	pretty_plural	varchar2(1000) not null
			constraint acs_obj_types_pretty_plural_un
			unique,
	table_name	varchar2(30)
                        constraint acs_object_types_table_name_un unique,
	id_column	varchar2(30),
	package_name	varchar2(30) not null
			constraint acs_object_types_pkg_name_un unique,
	name_method	varchar2(100),
	type_extension_table varchar2(30),
        dynamic_p       char(1) default 'f' 
                        constraint acs_object_types_dynamic_p_ck
                        check (dynamic_p in ('t', 'f')),
	check ((table_name is null and id_column is null) or
               (table_name is not null and id_column is not null))
);

-- create bitmap index acs_obj_types_supertype_idx on acs_object_types (supertype);
create index acs_obj_types_supertype_idx on acs_object_types (supertype);

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
   - the "user" object_type has "email" and "password" attributes
   - the "content_item" object_type has "title" and "body" attributes
 * Relationship types (stored in the acs_rel_types table)
   Examples:
   - "a team has one team leader who is a user" (in other words,
     instances of the "team" object_type must have one "team leader"
     relationship to an instance of the "user" object_type)
   - "a content item may have zero or authors who are people or
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
 by the associated object_type.  For example, a row in the user_group_types
 table stores a default approval policy for every user group of that type.
 In this example, the user_group_types table has a primary key named
 group_type that references acs_object_types.  If a subtype of user_groups
 for example, lab_courses, has its own type-specific data, it could be
 maintained in a table called lab_course_types, with a primary key named
 lab_course_type that references user_group_types.  This provides the same
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

create or replace view acs_object_type_supertype_map
as select ot.object_type, ota.object_type as ancestor_type
   from acs_object_types ot, acs_object_types ota
   where ota.object_type in (select object_type
                             from acs_object_types
                             start with object_type = ot.supertype
                             connect by object_type = prior supertype);


create table acs_object_type_tables (
	object_type	not null constraint acs_obj_type_tbls_obj_type_fk
			references acs_object_types (object_type),
	table_name	varchar2(30) not null,
	id_column	varchar2(30),
	constraint acs_object_type_tables_pk
	primary key (object_type, table_name)
);

-- create bitmap index acs_objtype_tbls_objtype_idx on acs_object_type_tables (object_type);
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
	datatype	varchar2(50) 
			constraint acs_datatypes_datatype_nn not null
			constraint acs_datatypes_datatype_pk primary key,
	max_n_values	integer default 1
			constraint acs_datatypes_max_n_values_ck
			check (max_n_values > 0),
 database_type varchar(100),
 column_size varchar(100),
 column_check_expr varchar(250),
 column_output_function varchar(100)
);

comment on table acs_datatypes is '
 Defines the set of available datatypes for acs_attributes. These
 datatypes are abstract, not implementation-specific, i.e., they
 are not Oracle datatypes. The set of pre-defined datatypes is
 inspired by XForms (http://www.w3.org/TR/xforms-datamodel/).
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
begin
 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('string', null, 'varchar', '4000');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size, column_check_expr)
 values
  ('boolean', 1, 'char', 1, 'in (''t'', ''f''))');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('number', null, 'number', '10,2');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('integer', 1, 'integer', null);

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_size)
 values
  ('currency', null, 'number', '10,2');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_output_function)
 values
  ('date', null, 'date', 'acs_datatype.date_output_function');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_output_function)
 values
  ('timestamp', null, 'timestamp', 'acs_datatype.timestamp_output_function');

 insert into acs_datatypes
  (datatype, max_n_values, database_type, column_output_function)
 values
  ('time_of_day', null, 'timestamp', 'acs_datatype.timestamp_output_function');

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
 ('text', null, 'clob', null);

insert into acs_datatypes
 (datatype, max_n_values, database_type, column_size)
values
  ('keyword', 1, 'varchar', '100');

insert into acs_datatypes
 (datatype, max_n_values, database_type, column_size)
values
 ('richtext', null, 'clob', null);

insert into acs_datatypes
 (datatype, max_n_values, database_type, column_size)
values
 ('filename', null, 'varchar', '100');

insert into acs_datatypes
 (datatype, max_n_values, database_type, column_size)
values
 ('float', null, 'float', null);

insert into acs_datatypes
 (datatype, max_n_values, database_type, column_size)
values
 ('naturalnum', null, 'integer', null);

 commit;
end;
/
show errors

--create table acs_input_types (
--);

create sequence acs_attribute_id_seq;

create table acs_attributes (
	attribute_id	integer 
			constraint acs_attributes_attribute_id_nn not null
			constraint acs_attributes_attribute_id_pk
			primary key,
	object_type	constraint acs_attributes_object_type_nn not null
			constraint acs_attributes_object_type_fk
			references acs_object_types (object_type),
	table_name	varchar2(30),
	constraint acs_attrs_obj_type_tbl_name_fk
	foreign key (object_type, table_name) references acs_object_type_tables,
	attribute_name	varchar2(100) 
			constraint aa_attribute_name_nn not null,
	pretty_name	varchar2(100) 
			constraint acs_attributes_pretty_name_nn not null,
	pretty_plural	varchar2(100),
	sort_order	integer 
			constraint acs_attributes_sort_order_nn not null,
	datatype	constraint acs_attributes_datatype_nn not null
			constraint acs_attributes_datatype_fk
			references acs_datatypes (datatype),
	default_value	varchar2(4000),
	min_n_values	integer default 1 
			constraint acs_attributes_min_n_values_nn not null
			constraint acs_attributes_min_n_values_ck
			check (min_n_values >= 0),
	max_n_values	integer default 1 
			constraint acs_attributes_max_n_values_nn not null
			constraint acs_attributes_max_n_values_ck
			check (max_n_values >= 0),
	storage 	varchar2(13) default 'type_specific'
			constraint acs_attributes_storage_ck
			check (storage in ('type_specific',
					   'generic')),
        static_p        varchar2(1) default 'f'
                        constraint acs_attributes_static_p_ck
			check (static_p in ('t', 'f')),
	column_name	varchar2(30),
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

-- create bitmap index acs_attrs_obj_type_idx on acs_attributes (object_type);
create index acs_attrs_obj_type_idx on acs_attributes (object_type);
create index acs_attrs_tbl_name_idx on acs_attributes (table_name);
-- create bitmap index acs_attrs_datatype_idx on acs_attributes (datatype);
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
	attribute_id	not null
			constraint asc_enum_values_attr_id_fk
			references acs_attributes (attribute_id),
	enum_value	varchar2(1000),
	pretty_name	varchar2(100) 
			constraint acs_enum_values_pretty_name_nn not null,
	sort_order	integer 
			constraint acs_enum_values_sort_order_nn not null,
	constraint acs_enum_values_pk
	primary key (attribute_id, enum_value),
	constraint acs_enum_values_pretty_name_un
	unique (attribute_id, pretty_name),
	constraint acs_enum_values_sort_order_un
	unique (attribute_id, sort_order)
);

create index acs_enum_values_attr_id_idx on acs_enum_values (attribute_id);

create table acs_attribute_descriptions (
	object_type	not null constraint acs_attr_descs_obj_type_fk
			references acs_object_types (object_type),
	attribute_name  varchar2(100) not null,
	constraint acs_attr_descs_ob_tp_at_na_fk
	foreign key (object_type, attribute_name)
	references acs_attributes (object_type, attribute_name),
	description_key varchar2(100),
	constraint acs_attribute_descriptions_pk
	primary key (object_type, attribute_name, description_key),
	description	clob not null
);

-- create bitmap index acs_attr_desc_obj_type_idx on acs_attribute_descriptions (object_type);
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

-----------------------
-- METADATA PACKAGES --
-----------------------

create or replace package acs_datatype
is
  function date_output_function(attribute_name in varchar2)
  return acs_datatypes.column_output_function%TYPE;
  function timestamp_output_function(attribute_name in varchar2)
  return acs_datatypes.column_output_function%TYPE;
end acs_datatype;
/
show errors

create or replace package acs_object_type
is
  -- define an object type
  procedure create_type (
    object_type		in acs_object_types.object_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'acs_object',
    table_name		in acs_object_types.table_name%TYPE default null,
    id_column		in acs_object_types.id_column%TYPE default null,
    package_name	in acs_object_types.package_name%TYPE default null,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null,
    create_table_p in varchar2 default 'f',
    dynamic_p in varchar2 default 'f'
  );

  -- delete an object type definition
  procedure drop_type (
    object_type		in acs_object_types.object_type%TYPE,
    drop_children_p in varchar2 default 'f',
    drop_table_p in varchar2 default 'f'
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

create or replace package acs_attribute
is

  -- define an object attribute
  function create_attribute (
    object_type		in acs_attributes.object_type%TYPE,
    attribute_name	in acs_attributes.attribute_name%TYPE,
    datatype		in acs_attributes.datatype%TYPE,
    pretty_name		in acs_attributes.pretty_name%TYPE,
    pretty_plural	in acs_attributes.pretty_plural%TYPE default null,
    table_name		in acs_attributes.table_name%TYPE default null,
    column_name		in acs_attributes.column_name%TYPE default null,
    default_value	in acs_attributes.default_value%TYPE default null,
    min_n_values	in acs_attributes.min_n_values%TYPE default 1,
    max_n_values	in acs_attributes.max_n_values%TYPE default 1,
    sort_order		in acs_attributes.sort_order%TYPE default null,
    storage		in acs_attributes.storage%TYPE default 'type_specific',
    static_p		in acs_attributes.static_p%TYPE default 'f',
    create_column_p in varchar2 default 'f',
    database_type in acs_datatypes.database_type%TYPE default null,
    column_size in acs_datatypes.column_size%TYPE default null,
    null_p in varchar2 default 't',
    references in varchar2 default null,
    check_expr in acs_datatypes.column_check_expr%TYPE default null,
    column_spec in varchar2 default null
  ) return acs_attributes.attribute_id%TYPE;

  procedure drop_attribute (
    object_type in varchar2,
    attribute_name in varchar2,
    drop_column_p in varchar2 default 'f'
  );

  procedure add_description (
    object_type		in acs_attribute_descriptions.object_type%TYPE,
    attribute_name	in acs_attribute_descriptions.attribute_name%TYPE,
    description_key	in acs_attribute_descriptions.description_key%TYPE,
    description		in acs_attribute_descriptions.description%TYPE
  );

  procedure drop_description (
    object_type		in acs_attribute_descriptions.object_type%TYPE,
    attribute_name	in acs_attribute_descriptions.attribute_name%TYPE,
    description_key	in acs_attribute_descriptions.description_key%TYPE
  );

end acs_attribute;
/
show errors

create or replace package body acs_datatype
is
  function date_output_function(attribute_name in varchar2)
  return acs_datatypes.column_output_function%TYPE
  is
  begin
    return 'to_char(' || attribute_name || ', ''YYYY-MM-DD'')';
  end date_output_function;

  function timestamp_output_function(attribute_name in varchar2)
  return acs_datatypes.column_output_function%TYPE
  is
  begin
    return 'to_char(' || attribute_name || ', ''YYYY-MM-DD HH24:MI::SS'')';
  end timestamp_output_function;

end acs_datatype;
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
    table_name		in acs_object_types.table_name%TYPE default null,
    id_column		in acs_object_types.id_column%TYPE default null,
    package_name	in acs_object_types.package_name%TYPE default null,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null,
    create_table_p in varchar2 default 'f',
    dynamic_p in varchar2 default 'f'
  )
  is
    v_package_name acs_object_types.package_name%TYPE;
    v_table_name	acs_object_types.table_name%TYPE;
    v_id_column	acs_object_types.id_column%TYPE;
    v_supertype	acs_object_types.supertype%TYPE;
    v_supertype_table	acs_object_types.table_name%TYPE;
    v_table_exists integer;
  begin

    if (create_table_p = 't') and (table_name is null or table_name = '') then
      v_table_name := object_type || '_t';
    else
      v_table_name := table_name;
    end if;

    if (create_table_p = 't') and (id_column is null or id_column = '') then
      v_id_column := object_type || '_id';
    else
      v_id_column := id_column;
    end if;

    if package_name is null then
      v_package_name := object_type;
    else
      v_package_name := package_name;
    end if;

    if object_type <> 'acs_object' and (supertype is null or supertype = '') then
      v_supertype := 'acs_object';
    else
      v_supertype := supertype;
    end if;

    insert into acs_object_types
      (object_type, pretty_name, pretty_plural, supertype, table_name,
       id_column, abstract_p, type_extension_table, package_name,
       name_method)
    values
      (object_type, pretty_name, pretty_plural, v_supertype, v_table_name,
       v_id_column, abstract_p, type_extension_table, v_package_name,
       name_method);

    if (create_table_p = 't') then

      select decode(count(*),0,0,1) into v_table_exists from user_tables
        where table_name = upper(v_table_name);

      if v_table_exists = 1 then
        raise_application_error(-20000, 'Table ' || v_table_name || ' already exists.');
      end if;

      loop
        select table_name,object_type into v_supertype_table,v_supertype
        from acs_object_types
        where object_type = v_supertype;
        exit when v_supertype_table is not null;
      end loop;

      execute immediate 'create table ' || v_table_name || ' (' ||
        v_id_column  || ' integer primary key references ' ||
        v_supertype_table || ')';

    end if;

  end create_type;

  procedure drop_type (
    object_type		in acs_object_types.object_type%TYPE,
    drop_children_p in varchar2 default 'f',
    drop_table_p in varchar2 default 'f'
  )
  is
    cursor c_attributes (object_type IN varchar) is
      select attribute_name from acs_attributes where object_type = c_attributes.object_type;
    cursor c_subtypes (object_type IN varchar) is
      select object_type from acs_object_types where supertype = c_subtypes.object_type;
    v_table_name acs_object_types.table_name%TYPE;
  begin

    -- drop children recursively
    if drop_children_p = 't' then
      for row in c_subtypes (drop_type.object_type) loop
         drop_type(row.object_type, 't', drop_table_p);
      end loop;
    end if;

    -- drop all the attributes associated with this type
    for row in c_attributes (drop_type.object_type) loop
       acs_attribute.drop_attribute ( drop_type.object_type, row.attribute_name );
    end loop;

    if drop_table_p = 't' then
      select table_name into v_table_name
      from acs_object_types
      where object_type = drop_type.object_type;

      execute immediate 'drop table ' || v_table_name || ' cascade';
    end if;

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

create or replace package body acs_attribute
is

  function create_attribute (
    object_type		in acs_attributes.object_type%TYPE,
    attribute_name	in acs_attributes.attribute_name%TYPE,
    datatype		in acs_attributes.datatype%TYPE,
    pretty_name		in acs_attributes.pretty_name%TYPE,
    pretty_plural	in acs_attributes.pretty_plural%TYPE default null,
    table_name		in acs_attributes.table_name%TYPE default null,
    column_name		in acs_attributes.column_name%TYPE default null,
    default_value	in acs_attributes.default_value%TYPE default null,
    min_n_values	in acs_attributes.min_n_values%TYPE default 1,
    max_n_values	in acs_attributes.max_n_values%TYPE default 1,
    sort_order		in acs_attributes.sort_order%TYPE default null,
    storage		in acs_attributes.storage%TYPE default 'type_specific',
    static_p		in acs_attributes.static_p%TYPE default 'f',
    create_column_p in varchar2 default 'f',
    database_type in acs_datatypes.database_type%TYPE default null,
    column_size in acs_datatypes.column_size%TYPE default null,
    null_p in varchar2 default 't',
    references in varchar2 default null,
    check_expr in acs_datatypes.column_check_expr%TYPE default null,
    column_spec in varchar2 default null
  ) return acs_attributes.attribute_id%TYPE
  is
    type datatype_type is record (
        database_type acs_datatypes.database_type%TYPE,
        column_size acs_datatypes.column_size%TYPE,
        column_check_expr acs_datatypes.column_check_expr%TYPE);
    v_sort_order acs_attributes.sort_order%TYPE;
    v_attribute_id    acs_attributes.attribute_id%TYPE;
    v_column_spec varchar2(4000);
    v_table_name acs_attributes.table_name%TYPE;
    v_constraint_stub varchar2(4000);
    v_column_name acs_attributes.column_name%TYPE;
    v_type_exists integer;
    v_table_exists integer;
    v_column_exists integer;
    v_datatype datatype_type;
  begin

    select decode(count(*),0,0,1) into v_type_exists
    from acs_object_types
    where object_type = create_attribute.object_type;
    if v_type_exists = 0 then
      raise_application_error(-20000, object_type || ' does not exist');
    end if;

    if sort_order is null then
      select nvl(max(sort_order), 1) into v_sort_order
      from acs_attributes
      where object_type = create_attribute.object_type
      and attribute_name = create_attribute.attribute_name;
    else
      v_sort_order := sort_order;
    end if;

    select acs_attribute_id_seq.nextval into v_attribute_id from dual;

    insert into acs_attributes
      (attribute_id, object_type, table_name, column_name, attribute_name,
       pretty_name, pretty_plural, sort_order, datatype, default_value,
       min_n_values, max_n_values, storage, static_p)
    values
      (v_attribute_id, object_type, table_name, column_name, attribute_name,
       pretty_name, pretty_plural, v_sort_order, datatype, default_value,
       min_n_values, max_n_values, storage, static_p);

    if create_column_p = 't' then

      select table_name into v_table_name
      from acs_object_types
      where object_type = create_attribute.object_type;

      select decode(count(*),0,0,1) into v_table_exists
      from user_tables
      where table_name = upper(v_table_name);

      if v_table_exists = 0 then
        raise_application_error(-20000, 'Table ' || v_table_name || ' does not exists.');
      end if;

      -- Add the appropriate column to the table

      -- We can only create the table column if
      -- 1. the attribute is declared type_specific (generic storage uses an auxiliary table)
      -- 2. the attribute is not declared static
      -- 3. it does not already exist in the table

      if storage <> 'type_specific' then
        raise_application_error(-20000, 'Attribute ' || attribute_name || ' for object type ' || object_type || ' must be declared with type_specific storage');
      end if;

      if static_p = 't' then
        raise_application_error(-20000, 'Attribute ' || attribute_name || ' for object type ' || object_type || ' can not be declared static');
      end if;

      if table_name is not null then
        raise_application_error(-20000, 'Attribute ' || attribute_name || ' for object type ' || object_type || ' can not specify a table for storage');
      end if;

      select decode(count(*),0,0,1) into v_column_exists
      from user_tab_columns
      where table_name = upper(v_table_name)
        and column_name = upper(attribute_name);

      if v_column_exists = 1 then
        raise_application_error(-20000, 'Column ' || attribute_name || ' for object type ' || object_type || ' already exists');
      end if;

      -- all conditions for creating this column have been met, now let''s see if the type
      -- spec is OK

      if column_spec is not null then
        if database_type is not null
          or column_size is not null
          or null_p is not null
          or references is not null
          or check_expr is not null then
        raise_application_error(-20000, 'Attribute ' || attribute_name || ' for object type ' || object_type || ' is being created with an explicit column_spec, but not all of the type modification fields are null');
        end if;
        v_column_spec := column_spec;
      else
        select coalesce(create_attribute.database_type, database_type) as database_type,
          coalesce(create_attribute.column_size, column_size) as column_size,
          coalesce(check_expr, column_check_expr) as column_check_expr
        into v_datatype
        from acs_datatypes
        where datatype = create_attribute.datatype;

        v_column_spec := v_datatype.database_type;

        if v_datatype.column_size is not null then
          v_column_spec := v_column_spec || '(' || v_datatype.column_size || ')';
        end if;

        v_constraint_stub := ' constraint ' || object_type || '_' ||
          attribute_name || '_';

        if v_datatype.column_check_expr is not null then
          v_column_spec := v_column_spec || v_constraint_stub || 'ck check(' ||
          attribute_name || v_datatype.column_check_expr || ')';
        end if;

        if null_p = 'f' then
          v_column_spec := v_column_spec || v_constraint_stub || 'nn not null';
        end if;

        if references is not null then
          v_column_spec := v_column_spec || v_constraint_stub || 'fk references ' ||
          references || ' on delete';
          if null_p = 't' then
            v_column_spec := v_column_spec || ' set null';
          else
            v_column_spec := v_column_spec || ' cascade';
          end if;
        end if;

      end if;

      execute immediate 'alter table ' || v_table_name || ' add ' || 
        attribute_name || ' ' || v_column_spec;
    end if;

    return v_attribute_id;
  end create_attribute;

  procedure drop_attribute (
    object_type in varchar2,
    attribute_name in varchar2,
    drop_column_p in varchar2 default 'f'
  )
  is
  begin
    -- first remove possible values for the enumeration
    delete from acs_enum_values
      where attribute_id in (select a.attribute_id 
                               from acs_attributes a 
                              where a.object_type = drop_attribute.object_type
                                and a.attribute_name = drop_attribute.attribute_name);

    delete from acs_attributes
     where object_type = drop_attribute.object_type
       and attribute_name = drop_attribute.attribute_name;
  end drop_attribute;

  procedure add_description (
    object_type		in acs_attribute_descriptions.object_type%TYPE,
    attribute_name	in acs_attribute_descriptions.attribute_name%TYPE,
    description_key	in acs_attribute_descriptions.description_key%TYPE,
    description		in acs_attribute_descriptions.description%TYPE
  )
  is
  begin
    insert into acs_attribute_descriptions
     (object_type, attribute_name, description_key, description)
    values
     (add_description.object_type, add_description.attribute_name,
      add_description.description_key, add_description.description);
  end;

  procedure drop_description (
    object_type		in acs_attribute_descriptions.object_type%TYPE,
    attribute_name	in acs_attribute_descriptions.attribute_name%TYPE,
    description_key	in acs_attribute_descriptions.description_key%TYPE
  )
  is
  begin
    delete from acs_attribute_descriptions
    where object_type = drop_description.object_type
    and attribute_name = drop_description.attribute_name
    and description_key = drop_description.description_key;
  end;

end acs_attribute;
/
show errors
