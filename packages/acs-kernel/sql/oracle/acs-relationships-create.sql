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
	role		varchar2(100) 
			constraint acs_rel_roles_role_nn not null
			constraint acs_rel_roles_role_pk primary key,
        pretty_name	varchar2(100) 
			constraint acs_rel_roles_pretty_name_nn not null,
        pretty_plural	varchar2(100) 
			constraint acs_rel_roles_pretty_plural_nn not null
);

create table acs_rel_types (
	rel_type	varchar2(100) 
			constraint acs_rel_types_rel_type_nn not null
			constraint acs_rel_types_rel_type_pk primary key
			constraint acs_rel_types_rel_type_fk
			references acs_object_types(object_type),
	object_type_one	not null
			constraint acs_rel_types_obj_type_1_fk
			references acs_object_types (object_type),
	role_one	constraint acs_rel_types_role_one_fk
			references acs_rel_roles (role),
	min_n_rels_one	integer default 0 not null
			constraint acs_rel_types_min_n_1_ck
			check (min_n_rels_one >= 0),
	max_n_rels_one	integer
			constraint acs_rel_types_max_n_1_ck
			check (max_n_rels_one >= 0),
	object_type_two	not null
			constraint acs_rel_types_obj_type_2_fk
			references acs_object_types (object_type),
	role_two	constraint acs_rel_types_role_two_fk
			references acs_rel_roles (role),
	min_n_rels_two	integer default 0 not null
			constraint acs_rel_types_min_n_2_ck
			check (min_n_rels_two >= 0),
	max_n_rels_two	integer
			constraint acs_rel_types_max_n_2_ck
			check (max_n_rels_two >= 0),
    composable_p boolean default 't' not null,
	constraint acs_rel_types_n_rels_one_ck
	check (min_n_rels_one <= max_n_rels_one),
	constraint acs_rel_types_n_rels_two_ck
	check (min_n_rels_two <= max_n_rels_two)
);

-- create bitmap index acs_rel_types_objtypeone_idx on acs_rel_types (object_type_one);
create index acs_rel_types_objtypeone_idx on acs_rel_types (object_type_one);
-- create bitmap index acs_rel_types_role_one_idx on acs_rel_types (role_one);
create index acs_rel_types_role_one_idx on acs_rel_types (role_one);
-- create bitmap index acs_rel_types_objtypetwo_idx on acs_rel_types (object_type_two);
create index acs_rel_types_objtypetwo_idx on acs_rel_types (object_type_two);
-- create bitmap index acs_rel_types_role_two_idx on acs_rel_types (role_two);
create index acs_rel_types_role_two_idx on acs_rel_types (role_two);

comment on table acs_rel_types is '
 Each row in <code>acs_rel_types</code> represents a type of
 relationship between objects. For example, the following DML
 statement:
 <blockquote><pre>
 insert into acs_rel_types
  (rel_type,
   object_type_one, role_one, min_n_rels_one, max_n_rels_one,
   object_type_two, role_two, min_n_rels_two, max_n_rels_two)
 values
  (''employment'',
   ''person'', ''employee'', 0, null,
   ''company'', ''employer'', 0, null)
 </pre></blockquote>
 defines an "employment" relationship type that can be expressed in
 in natural language as:
 <blockquote>
 A person may be the employee of zero or more companies, and a company
 may be the employer of zero or more people.
 </blockquote>
';

create or replace package acs_rel_type
as

  procedure create_role (
    role	  in acs_rel_roles.role%TYPE,
    pretty_name   in acs_rel_roles.pretty_name%TYPE default null,
    pretty_plural in acs_rel_roles.pretty_plural%TYPE default null
  );

  procedure drop_role (
    role	in acs_rel_roles.role%TYPE
  );

  function role_pretty_name (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_name%TYPE;

  function role_pretty_plural (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_plural%TYPE;

  procedure create_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'relationship',
    table_name		in acs_object_types.table_name%TYPE,
    id_column		in acs_object_types.id_column%TYPE,
    package_name	in acs_object_types.package_name%TYPE,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null,
    object_type_one	in acs_rel_types.object_type_one%TYPE,
    role_one		in acs_rel_types.role_one%TYPE default null,
    min_n_rels_one	in acs_rel_types.min_n_rels_one%TYPE,
    max_n_rels_one	in acs_rel_types.max_n_rels_one%TYPE,
    object_type_two	in acs_rel_types.object_type_two%TYPE,
    role_two		in acs_rel_types.role_two%TYPE default null,
    min_n_rels_two	in acs_rel_types.min_n_rels_two%TYPE,
    max_n_rels_two	in acs_rel_types.max_n_rels_two%TYPE
  );

  procedure drop_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    cascade_p		in char default 'f'
  );

end acs_rel_type;
/
show errors

create or replace package body acs_rel_type
as

  procedure create_role (
    role	  in acs_rel_roles.role%TYPE,
    pretty_name   in acs_rel_roles.pretty_name%TYPE default null,
    pretty_plural in acs_rel_roles.pretty_plural%TYPE default null
  )
  is
  begin
    insert into acs_rel_roles
     (role, pretty_name, pretty_plural)
    values
     (create_role.role, nvl(create_role.pretty_name,create_role.role), nvl(create_role.pretty_plural,create_role.role));
  end;

  procedure drop_role (
    role	in acs_rel_roles.role%TYPE
  )
  is
  begin
    delete from acs_rel_roles
    where role = drop_role.role;
  end;

  function role_pretty_name (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_name%TYPE
  is
    v_pretty_name acs_rel_roles.pretty_name%TYPE;
  begin
    select r.pretty_name into v_pretty_name
      from acs_rel_roles r
     where r.role = role_pretty_name.role;

    return v_pretty_name;
  end role_pretty_name;


  function role_pretty_plural (
    role	in acs_rel_roles.role%TYPE
  ) return acs_rel_roles.pretty_plural%TYPE
  is
    v_pretty_plural acs_rel_roles.pretty_plural%TYPE;
  begin
    select r.pretty_plural into v_pretty_plural
      from acs_rel_roles r
     where r.role = role_pretty_plural.role;

    return v_pretty_plural;
  end role_pretty_plural;

  procedure create_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    supertype		in acs_object_types.supertype%TYPE
			   default 'relationship',
    table_name		in acs_object_types.table_name%TYPE,
    id_column		in acs_object_types.id_column%TYPE,
    package_name	in acs_object_types.package_name%TYPE,
    abstract_p		in acs_object_types.abstract_p%TYPE default 'f',
    type_extension_table in acs_object_types.type_extension_table%TYPE
			    default null,
    name_method		in acs_object_types.name_method%TYPE default null,
    object_type_one	in acs_rel_types.object_type_one%TYPE,
    role_one		in acs_rel_types.role_one%TYPE default null,
    min_n_rels_one	in acs_rel_types.min_n_rels_one%TYPE,
    max_n_rels_one	in acs_rel_types.max_n_rels_one%TYPE,
    object_type_two	in acs_rel_types.object_type_two%TYPE,
    role_two		in acs_rel_types.role_two%TYPE default null,
    min_n_rels_two	in acs_rel_types.min_n_rels_two%TYPE,
    max_n_rels_two	in acs_rel_types.max_n_rels_two%TYPE
  )
  is
  begin
    acs_object_type.create_type(
      object_type => rel_type,
      pretty_name => pretty_name,
      pretty_plural => pretty_plural,
      supertype => supertype,
      table_name => table_name,
      id_column => id_column,
      package_name => package_name,
      abstract_p => abstract_p,
      type_extension_table => type_extension_table,
      name_method => name_method
    );

    insert into acs_rel_types
     (rel_type,
      object_type_one, role_one,
      min_n_rels_one, max_n_rels_one,
      object_type_two, role_two,
      min_n_rels_two, max_n_rels_two)
    values
     (create_type.rel_type,
      create_type.object_type_one, create_type.role_one,
      create_type.min_n_rels_one, create_type.max_n_rels_one,
      create_type.object_type_two, create_type.role_two,
      create_type.min_n_rels_two, create_type.max_n_rels_two);
  end;

  procedure drop_type (
    rel_type		in acs_rel_types.rel_type%TYPE,
    cascade_p		in char default 'f'
  )
  is
  begin
    -- XXX do cascade_p
    delete from acs_rel_types
    where acs_rel_types.rel_type = acs_rel_type.drop_type.rel_type;

    acs_object_type.drop_type(acs_rel_type.drop_type.rel_type, acs_rel_type.drop_type.cascade_p);
  end;

end acs_rel_type;
/
show errors

begin
 acs_rel_type.create_type (
   rel_type => 'relationship',
   pretty_name => 'Relationship',
   pretty_plural => 'Relationships',
   supertype => 'acs_object',
   table_name => 'acs_rels',
   id_column => 'rel_id',
   package_name => 'acs_rel',
   type_extension_table => 'acs_rel_types',
   object_type_one => 'acs_object',
   min_n_rels_one => 0,
   max_n_rels_one => null,
   object_type_two => 'acs_object',
   min_n_rels_two => 0,
   max_n_rels_two => null
 );

 commit;
end;
/
show errors

--------------------------------------
-- OPERATIONAL LEVEL: RELATIONSHIPS --
--------------------------------------

create sequence acs_rel_id_seq;

create table acs_rels (
	rel_id		integer 
			constraint acs_rels_rel_id_nn not null
			constraint acs_rels_rel_id_fk
			references acs_objects (object_id)
                        on delete cascade
			constraint acs_rels_rel_id_pk primary key,
	rel_type	varchar(100) 
			constraint acs_rels_rel_type_nn not null
			constraint acs_rels_rel_type_fk
			references acs_rel_types (rel_type),
	object_id_one	integer 
			constraint acs_rels_object_id_one_nn not null
			constraint acs_rels_object_id_one_fk
			references acs_objects (object_id)
                        on delete cascade,
	object_id_two	integer 
			constraint acs_rels_object_id_two_nn not null
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
	rel_id		integer 
			constraint acs_data_links_rel_id_nn not null
			constraint acs_data_links_rel_id_pk primary key,
	object_id_one	integer not null
			constraint acs_data_links_obj_one_fk
			references acs_objects (object_id)
                        on delete cascade,
	object_id_two	integer not null
			constraint acs_data_links_obj_two_fk
			references acs_objects (object_id)
                        on delete cascade,
    relation_tag    varchar2(100),
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

create or replace trigger acs_rels_in_tr
before insert or update on acs_rels
for each row
declare
  dummy integer;
  target_object_type_one acs_object_types.object_type%TYPE;
  target_object_type_two acs_object_types.object_type%TYPE;
  actual_object_type_one acs_object_types.object_type%TYPE;
  actual_object_type_two acs_object_types.object_type%TYPE;
begin

    -- validate that the relation being added is between objects of the
    -- correct object_type.  If no rows are returned by this query,
    -- then the types are wrong and we should return an error.
    select 1 into dummy
    from acs_rel_types rt,
         acs_objects o1, 
         acs_objects o2
    where exists (select 1 
                   from acs_object_types t
                  where t.object_type = o1.object_type
                connect by prior t.object_type = t.supertype
                  start with t.object_type = rt.object_type_one)
      and exists (select 1 
                   from acs_object_types t
                  where t.object_type = o2.object_type
                connect by prior t.object_type = t.supertype
                  start with t.object_type = rt.object_type_two)
      and rt.rel_type = :new.rel_type
      and o1.object_id = :new.object_id_one
      and o2.object_id = :new.object_id_two;

exception
  when NO_DATA_FOUND then

      -- At least one of the object types must have been wrong.
      -- Get all the object type information and print it out.
      select rt.object_type_one, rt.object_type_two,
             o1.object_type, o2.object_type
      into target_object_type_one, target_object_type_two,
           actual_object_type_one, actual_object_type_two
      from acs_rel_types rt, acs_objects o1, acs_objects o2
      where rt.rel_type = :new.rel_type
        and o1.object_id = :new.object_id_one
        and o2.object_id = :new.object_id_two;

      raise_application_error (-20001,
          :new.rel_type || ' violation: Invalid object types.  ' ||
          'Object ' || :new.object_id_one || 
          ' (' || actual_object_type_one || ') ' || 
          'must be of type ' || target_object_type_one || '. ' ||
          'Object ' || :new.object_id_two || 
          ' (' || actual_object_type_two || ') ' || 
          'must be of type ' || target_object_type_two || '.');
          

end;
/
show errors


create or replace package acs_rel
as

  function new (
    rel_id		in acs_rels.rel_id%TYPE default null,
    rel_type		in acs_rels.rel_type%TYPE default 'relationship',
    object_id_one	in acs_rels.object_id_one%TYPE,
    object_id_two	in acs_rels.object_id_two%TYPE,
    context_id		in acs_objects.context_id%TYPE default null,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null
  ) return acs_rels.rel_id%TYPE;

  procedure del (
    rel_id	in acs_rels.rel_id%TYPE
  );

end;
/
show errors

create or replace package body acs_rel
as

  function new (
    rel_id		in acs_rels.rel_id%TYPE default null,
    rel_type		in acs_rels.rel_type%TYPE default 'relationship',
    object_id_one	in acs_rels.object_id_one%TYPE,
    object_id_two	in acs_rels.object_id_two%TYPE,
    context_id		in acs_objects.context_id%TYPE default null,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null
  ) return acs_rels.rel_id%TYPE
  is
    v_rel_id acs_rels.rel_id%TYPE;
  begin
    -- XXX This should check that object_id_one and object_id_two are
    -- of the appropriate types.
    v_rel_id := acs_object.new (
      object_id => rel_id,
      object_type => rel_type,
      title => rel_type || ': ' || object_id_one || ' - ' || object_id_two,
      context_id => context_id,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into acs_rels
     (rel_id, rel_type, object_id_one, object_id_two)
    values
     (v_rel_id, new.rel_type, new.object_id_one, new.object_id_two);

     return v_rel_id;
  end;

  procedure del (
    rel_id	in acs_rels.rel_id%TYPE
  )
  is
  begin
    acs_object.del(rel_id);
  end;

end;
/
show errors


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
create or replace view rel_types_valid_obj_one_types as
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
create or replace view rel_types_valid_obj_two_types as
select rt.rel_type, th.object_type
from acs_rel_types rt,
     (select object_type, ancestor_type
      from acs_object_type_supertype_map
      UNION ALL
      select object_type, object_type as ancestor_type 
      from acs_object_types) th
where rt.object_type_two = th.ancestor_type;

