--
-- acs-kernel/sql/acs-objects-create.sql
--
-- A base object type that provides auditing columns, permissioning,
-- attributes, and relationships to any subtypes.
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @author Rafael Schloming (rhs@mit.edu)
-- @author Jon Salz (jsalz@mit.edu)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

-----------------------------
-- PREDEFINED OBJECT TYPES --
-----------------------------



--
-- procedure inline_0/0
--
CREATE OR REPLACE FUNCTION inline_0(

) RETURNS integer AS $$
DECLARE
 attr_id acs_attributes.attribute_id%TYPE;
BEGIN
 --
 -- The ultimate supertype: object
 --
 PERFORM acs_object_type__create_type (
   'acs_object',
   'Object',
   'Objects',
   null,
   'acs_objects',
   'object_id',
   'acs_object',
   'f',
   null,
   'acs_object.default_name'
   );

 attr_id := acs_attribute__create_attribute (
   'acs_object',
   'object_type',
   'string',
   'Object Type',
   'Object Types',
   null,
   null,
   null,   
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'acs_object',
   'creation_date',
   'date',
   'Created Date',
   null,
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'acs_object',
   'creation_ip',
   'string',
   'Creation IP Address',
   null,
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'acs_object',
   'last_modified',
   'date',
   'Last Modified On',
   null,
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'acs_object',
   'modifying_ip',
   'string',
   'Modifying IP Address',
   null,
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
   'acs_object',
   'modifying_user',
   'integer',
   'Modifying User',
   null,
   null,
   null,
   null,
   1,
   1,
   null,
   'type_specific',
   'f'
   );

 attr_id := acs_attribute__create_attribute (
	'acs_object',
	'creation_user',
	'integer',
	'Creation user',
	'Creation users',
	null,
	null,
	null,
	0,
	1,
	null,
	'type_specific',
	'f'
	);

 attr_id := acs_attribute__create_attribute (
	'acs_object',
	'context_id',
	'integer',
	'Context ID',
	'Context IDs',
	null,
	null,
	null,
	0,
	1,
	null,
	'type_specific',
	'f'
	);

 attr_id := acs_attribute__create_attribute (
	'acs_object',
	'package_id',
	'integer',
	'Package ID',
	'Package IDs',
	null,
	null,
	null,
	0,
	1,
	null,
	'type_specific',
	'f'
	);

 attr_id := acs_attribute__create_attribute (
	'acs_object',
	'title',
	'string',
	'Title',
	'Titles',
	null,
	null,
	null,
	0,
	1,
	null,
	'type_specific',
	'f'
	);

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_0 ();

drop function inline_0 ();


-- show errors

-- ******************************************************************
-- * OPERATIONAL LEVEL
-- ******************************************************************

-------------
-- OBJECTS --
-------------

create sequence t_acs_object_id_seq;
create view acs_object_id_seq as
select nextval('t_acs_object_id_seq') as nextval;

create table acs_objects (
	object_id		integer not null
				constraint acs_objects_object_id_pk primary key,
	object_type		varchar(1000) not null
				constraint acs_objects_object_type_fk
				references acs_object_types (object_type),
        title			varchar(1000) default null,
        package_id		integer default null,
        context_id		integer
				CONSTRAINT acs_objects_context_id_fk
				REFERENCES acs_objects(object_id) ON DELETE CASCADE,
	security_inherit_p	boolean default 't' not null,
	creation_user		integer,
	creation_date		timestamptz default current_timestamp not null,
	creation_ip		varchar(50),
	last_modified		timestamptz default current_timestamp not null,
	modifying_user		integer,
	modifying_ip		varchar(50),
        constraint acs_objects_context_object_un
	unique (context_id, object_id)
);

-- The unique constraint above will force create of this index...
-- create index acs_objects_context_object_idx onacs_objects (context_id, object_id);

create index acs_objects_creation_user_idx on acs_objects (creation_user);
create index acs_objects_modify_user_idx on acs_objects (modifying_user);

create index acs_objects_package_idx on acs_objects (package_id);
create index acs_objects_title_idx on acs_objects(title);

create index acs_objects_object_type_idx on acs_objects (object_type);

CREATE OR REPLACE FUNCTION acs_objects_mod_ip_insert_tr () RETURNS trigger AS $$
BEGIN
  new.modifying_ip := new.creation_ip;

  return new;

END;
$$ LANGUAGE plpgsql;

create trigger acs_objects_mod_ip_insert_tr before insert on acs_objects
for each row execute procedure acs_objects_mod_ip_insert_tr ();

-- show errors

CREATE OR REPLACE FUNCTION acs_objects_last_mod_update_tr () RETURNS trigger AS $$
BEGIN
  if new.last_modified is null then
     new.last_modified := old.last_modified;
  elsif new.last_modified = old.last_modified then
     new.last_modified := now();
  end if;
  return new;
END;
$$ LANGUAGE plpgsql;

create trigger acs_objects_last_mod_update_tr before update on acs_objects
for each row execute procedure acs_objects_last_mod_update_tr ();

-- show errors

comment on table acs_objects is '
The root table for the acs object hierarchy.  It all starts here folks.
';

comment on column acs_objects.context_id is $$
 The context_id column points to an object that provides a context for
 this object. Often this will reflect an observed hierarchy in a site,
 for example a bboard message would probably list a bboard topic as
 it's context, and a bboard topic might list a sub-site as it's
 context. Whenever we ask a question of the form "can user X perform
 action Y on object Z", the acs security model will defer to an
 object's context if there is no information about user X's
 permission to perform action Y on object Z.
$$;

comment on column acs_objects.creation_user is '
 Who created the object; may be null since objects can be created by
 automated processes
';

comment on column acs_objects.modifying_user is '
 Who last modified the object
';

comment on column acs_objects.package_id is '
 Which package instance this object belongs to.
 Please note that in mid-term this column will replace all
 package_ids of package specific tables.
';

comment on column acs_objects.title is '
 Title of the object if applicable.
 Please note that in mid-term this column will replace all
 titles or object_names of package specific tables.
';

-----------------------
-- CONTEXT HIERARCHY --
-----------------------

create table acs_object_context_index (
	object_id	integer not null
			CONSTRAINT acs_obj_context_idx_obj_id_fk
			REFERENCES acs_objects(object_id) ON DELETE CASCADE,
	ancestor_id	integer not null
			CONSTRAINT acs_obj_context_idx_anc_id_fk
			REFERENCES acs_objects(object_id) ON DELETE CASCADE,
	n_generations	integer not null
			constraint acs_obj_context_idx_n_gen_ck
			check (n_generations >= 0),
        constraint acs_object_context_index_pk
	primary key (object_id, ancestor_id)
);

create index acs_obj_ctx_idx_ancestor_idx on acs_object_context_index (ancestor_id);
create index acs_obj_ctx_idx_object_id_idx on acs_object_context_index (object_id);

create view acs_object_paths
as select object_id, ancestor_id, n_generations
   from acs_object_context_index;

create view acs_object_contexts
as select object_id, ancestor_id, n_generations
   from acs_object_context_index
   where object_id != ancestor_id;



--
-- procedure acs_objects_context_id_in_tr/0
--
CREATE OR REPLACE FUNCTION acs_objects_context_id_in_tr(

) RETURNS trigger AS $$
DECLARE
        security_context_root integer;
BEGIN
  insert into acs_object_context_index
   (object_id, ancestor_id, n_generations)
  values
   (new.object_id, new.object_id, 0);

  if new.context_id is not null and new.security_inherit_p = 't' then
    insert into acs_object_context_index
     (object_id, ancestor_id, n_generations)
    select
     new.object_id as object_id, ancestor_id,
     n_generations + 1 as n_generations
    from acs_object_context_index
    where object_id = new.context_id;
  else
    security_context_root = acs__magic_object_id('security_context_root');
    if new.object_id != security_context_root then
      insert into acs_object_context_index
        (object_id, ancestor_id, n_generations)
      values
        (new.object_id, security_context_root, 1);
    end if;
  end if;

  return new;

END;
$$ LANGUAGE plpgsql;

create trigger acs_objects_context_id_in_tr after insert on acs_objects
for each row execute procedure acs_objects_context_id_in_tr ();



--
-- procedure acs_objects_context_id_up_tr/0
--
CREATE OR REPLACE FUNCTION acs_objects_context_id_up_tr(

) RETURNS trigger AS $$
DECLARE
        pair    record;
        outer_record record;
        inner_record record;
        security_context_root integer;
BEGIN
  if new.object_id = old.object_id
     and ((new.context_id = old.context_id)
	  or (new.context_id is null and old.context_id is null))
     and new.security_inherit_p = old.security_inherit_p then
    return new;
  end if;

  -- Remove my old ancestors from my descendants.
  for outer_record in select object_id from acs_object_context_index where 
               ancestor_id = old.object_id and object_id <> old.object_id loop
    for inner_record in select ancestor_id from acs_object_context_index where
                 object_id = old.object_id and ancestor_id <> old.object_id loop
      delete from acs_object_context_index
      where object_id = outer_record.object_id
        and ancestor_id = inner_record.ancestor_id;
    end loop;
  end loop;

  -- Kill all my old ancestors.
  delete from acs_object_context_index
  where object_id = old.object_id;

  insert into acs_object_context_index
   (object_id, ancestor_id, n_generations)
  values
   (new.object_id, new.object_id, 0);

  if new.context_id is not null and new.security_inherit_p = 't' then
     -- Now insert my new ancestors for my descendants.
    for pair in select *
		 from acs_object_context_index
		 where ancestor_id = new.object_id 
    LOOP
      insert into acs_object_context_index
       (object_id, ancestor_id, n_generations)
      select
       pair.object_id, ancestor_id,
       n_generations + pair.n_generations + 1 as n_generations
      from acs_object_context_index
      where object_id = new.context_id;
    end loop;
  else
    security_context_root = acs__magic_object_id('security_context_root');
    if new.object_id != security_context_root then
    -- We need to make sure that new.OBJECT_ID and all of its
    -- children have security_context_root as an ancestor.
    for pair in  select *
		 from acs_object_context_index
		 where ancestor_id = new.object_id 
      LOOP
        insert into acs_object_context_index
         (object_id, ancestor_id, n_generations)
        values
         (pair.object_id, security_context_root, pair.n_generations + 1);
      end loop;
    end if;
  end if;

  return new;

END;
$$ LANGUAGE plpgsql;

create trigger acs_objects_context_id_up_tr after update on acs_objects
for each row execute procedure acs_objects_context_id_up_tr ();

----------------------
-- ATTRIBUTE VALUES --
----------------------

create sequence t_acs_attribute_value_id_seq;
create view acs_attribute_value_id_seq as
select nextval('t_acs_attribute_value_id_seq') as nextval;

create table acs_attribute_values (
	object_id	integer not null
			constraint acs_attr_values_obj_id_fk
			references acs_objects (object_id) on delete cascade,
	attribute_id	integer not null
			constraint acs_attr_values_attr_id_fk
			references acs_attributes (attribute_id),
	attr_value	text,
	constraint acs_attribute_values_pk primary key
	(object_id, attribute_id)
);

create index acs_attr_values_attr_id_idx on acs_attribute_values (attribute_id);

comment on table acs_attribute_values is '
  Instead of coercing everything into a big string, we could use
  a "union", i.e, a string column, a number column, a date column,
  and a discriminator.
';

create table acs_static_attr_values (
	object_type	varchar(1000) not null
			constraint acs_static_a_v_obj_id_fk
			references acs_object_types (object_type) on delete cascade,
	attribute_id	integer not null
			constraint acs_static_a_v_attr_id_fk
			references acs_attributes (attribute_id),
	attr_value	text,
	constraint acs_static_a_v_pk primary key
	(object_type, attribute_id)
);

create index acs_stat_attrs_attr_id_idx on acs_static_attr_values (attribute_id);

comment on table acs_static_attr_values is '
  Stores static values for the object attributes. One row per object
  type.
';

------------------------
-- ACS_OBJECT PACKAGE --
------------------------

select define_function_args('acs_object__initialize_attributes','object_id');



--
-- procedure acs_object__initialize_attributes/1
--
CREATE OR REPLACE FUNCTION acs_object__initialize_attributes(
   initialize_attributes__object_id integer
) RETURNS integer AS $$
DECLARE
  v_object_type                                 acs_objects.object_type%TYPE;
BEGIN
   if  initialize_attributes__object_id is null then 
	raise exception 'acs_object__initialize_attributes called with null object_id';
   end if;

   -- Initialize dynamic attributes
   insert into acs_attribute_values
    (object_id, attribute_id, attr_value)
   select
    initialize_attributes__object_id, a.attribute_id, a.default_value
   from acs_attributes a, acs_objects o
   where a.object_type = o.object_type
   and o.object_id = initialize_attributes__object_id
   and a.storage = 'generic'
   and a.static_p = 'f';

   -- Retrieve type for static attributes
   select object_type into v_object_type from acs_objects
     where object_id = initialize_attributes__object_id;

   -- Initialize static attributes
   -- begin
     insert into acs_static_attr_values
      (object_type, attribute_id, attr_value)
     select
      v_object_type, a.attribute_id, a.default_value
     from acs_attributes a, acs_objects o
     where a.object_type = o.object_type
       and o.object_id = initialize_attributes__object_id
       and a.storage = 'generic'
       and a.static_p = 't'
       and not exists (select 1 from acs_static_attr_values
                       where object_type = a.object_type);
   -- exception when no_data_found then null;

   return 0; 
END;
$$ LANGUAGE plpgsql;

-- function new


-- old define_function_args('acs_object__new','object_id,object_type;acs_object,creation_date,creation_user,creation_ip,context_id,security_inherit_p;t,title,package_id')
-- new
select define_function_args('acs_object__new','object_id;null,object_type;acs_object,creation_date;now(),creation_user;null,creation_ip;null,context_id;null,security_inherit_p;t,title;null,package_id;null');




--
-- procedure acs_object__new/9
--
CREATE OR REPLACE FUNCTION acs_object__new(
   new__object_id integer,          -- default null
   new__object_type varchar,        -- default 'acs_object'
   new__creation_date timestamptz,  -- default now()
   new__creation_user integer,      -- default null
   new__creation_ip varchar,        -- default null
   new__context_id integer,         -- default null
   new__security_inherit_p boolean, -- default 't'
   new__title varchar,              -- default null
   new__package_id integer          -- default null

) RETURNS integer AS $$
DECLARE
  v_object_id                 acs_objects.object_id%TYPE;
  v_creation_date	      timestamptz;
  v_title                     acs_objects.title%TYPE;
  v_object_type_pretty_name   acs_object_types.pretty_name%TYPE;
BEGIN
  if new__object_id is null then
    select nextval('t_acs_object_id_seq') into v_object_id;
  else
    v_object_id := new__object_id;
  end if;

  if new__title is null then
   select pretty_name
   into v_object_type_pretty_name
   from acs_object_types
   where object_type = new__object_type;

    v_title := v_object_type_pretty_name || ' ' || v_object_id;
  else
    v_title := new__title;
  end if;

  if new__creation_date is null then
   v_creation_date:= now();
  else
   v_creation_date := new__creation_date;
  end if;

  insert into acs_objects
   (object_id, object_type, title, package_id, context_id,
    creation_date, creation_user, creation_ip, security_inherit_p)
  values
   (v_object_id, new__object_type, v_title, new__package_id, new__context_id,
    v_creation_date, new__creation_user, new__creation_ip, 
    new__security_inherit_p);

  PERFORM acs_object__initialize_attributes(v_object_id);

  return v_object_id;
  
END;
$$ LANGUAGE plpgsql;

-- function new



--
-- procedure acs_object__new/6
--
CREATE OR REPLACE FUNCTION acs_object__new(
   new__object_id integer,         -- default null
   new__object_type varchar,       -- default 'acs_object'
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__context_id integer         -- default null

) RETURNS integer AS $$
--
-- acs_object__new/6 maybe obsolete, when we define proper defaults for /9
--
DECLARE
  v_object_id                 acs_objects.object_id%TYPE;
  v_creation_date	      timestamptz;
BEGIN
  return acs_object__new(new__object_id, new__object_type, new__creation_date,
                         new__creation_user, new__creation_ip, new__context_id,
                         't', null, null);
END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_object__new/7
--
CREATE OR REPLACE FUNCTION acs_object__new(
   new__object_id integer,         -- default null
   new__object_type varchar,       -- default 'acs_object'
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__context_id integer,        -- default null
   new__security_inherit_p boolean -- default 't'

) RETURNS integer AS $$
--
-- acs_object__new/7 maybe obsolete, when we define proper defaults for /9
--
DECLARE
BEGIN
  return acs_object__new(new__object_id, new__object_type, new__creation_date,
                         new__creation_user, new__creation_ip, new__context_id,
                         new__security_inherit_p, null, null);
END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_object__new/8
--
CREATE OR REPLACE FUNCTION acs_object__new(
   new__object_id integer,          -- default null
   new__object_type varchar,        -- default 'acs_object'
   new__creation_date timestamptz,  -- default now()
   new__creation_user integer,      -- default null
   new__creation_ip varchar,        -- default null
   new__context_id integer,         -- default null
   new__security_inherit_p boolean, -- default 't'
   new__title varchar               -- default null

) RETURNS integer AS $$
--
-- acs_object__new/8 maybe obsolete, when we define proper defaults for /9
--
DECLARE
BEGIN
  return acs_object__new(new__object_id, new__object_type, new__creation_date,
                         new__creation_user, new__creation_ip, new__context_id,
                         new__security_inherit_p, new__title, null);
END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_object__new/8
--
CREATE OR REPLACE FUNCTION acs_object__new(
   new__object_id integer,         -- default null
   new__object_type varchar,       -- default 'acs_object'
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__context_id integer,        -- default null
   new__title varchar,             -- default null
   new__package_id integer         -- default null

) RETURNS integer AS $$
--
-- acs_object__new/8 maybe obsolete, when we define proper defaults for /9
--
DECLARE
BEGIN
  return acs_object__new(new__object_id, new__object_type, new__creation_date,
                         new__creation_user, new__creation_ip, new__context_id,
                         't', new__title, new__package_id);
END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_object__new/7
--
CREATE OR REPLACE FUNCTION acs_object__new(
   new__object_id integer,         -- default null
   new__object_type varchar,       -- default 'acs_object'
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__context_id integer,        -- default null
   new__title varchar              -- default null

) RETURNS integer AS $$
--
-- acs_object__new/7 maybe obsolete, when we define proper defaults for /9
--
DECLARE
BEGIN
  return acs_object__new(new__object_id, new__object_type, new__creation_date,
                         new__creation_user, new__creation_ip, new__context_id,
                         't', new__title, null);
END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_object__new/2
--
CREATE OR REPLACE FUNCTION acs_object__new(
   object_id integer,  -- default null
   object_type varchar -- default 'acs_object'

) RETURNS integer AS $$
--
-- acs_object__new/2 maybe obsolete, when we define proper defaults for /9
--
DECLARE
BEGIN
        return acs_object__new(object_id,object_type,now(),null,null,null);
END;
$$ LANGUAGE plpgsql;


-- procedure delete

select define_function_args('acs_object__delete','object_id');

--
-- procedure acs_object__delete/1
--
CREATE OR REPLACE FUNCTION acs_object__delete(
   delete__object_id integer
) RETURNS integer AS $$
DECLARE
  obj_type record;
BEGIN
  
  -- GN: the following deletion operation iterates over the id_columns
  -- of the acs_object_types of the type tree for the obejct and
  -- performs manual deletions in these tables by trying to delete the
  -- delete__object_id from the id_column.  This deletion includes as
  -- well the deletion in acs_objects.
  --
  -- In the best of all possible worlds, this would not
  -- be necessary, when the objects would have specified "on delete
  -- cascade" for the id_columns.

  for obj_type
  in select ot2.table_name, ot2.id_column
       from acs_object_types ot1, acs_object_types ot2
       where ot1.object_type = (select object_type
                               from acs_objects o
                               where o.object_id = delete__object_id)
         and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
    order by ot2.tree_sortkey desc
  loop
    -- Delete from the table.

    -- DRB: I removed the quote_ident calls that DanW originally included
    -- because the table names appear to be stored in upper case.  Quoting
    -- causes them to not match the actual lower or potentially mixed-case
    -- table names.  We will just forbid squirrely names that include quotes.
    
    -- daveB
    -- ETP is creating a new object, but not a table, although it does specify a
    -- table name, so we need to check if the table exists. Wp-slim does this too

    if table_exists(obj_type.table_name) then
      execute 'delete from ' || obj_type.table_name ||
          ' where ' || obj_type.id_column || ' =  ' || delete__object_id;
    end if;
  end loop;

  return 0; 
END;
$$ LANGUAGE plpgsql;


-- function name
select define_function_args('acs_object__name','object_id');



--
-- procedure acs_object__name/1
--
CREATE OR REPLACE FUNCTION acs_object__name(
   name__object_id integer
) RETURNS varchar AS $$
DECLARE
  object_name            varchar;  
  v_object_id            integer;
  obj_type               record;  
  obj                    record;      
BEGIN
  -- Find the name function for this object, which is stored in the
  -- name_method column of acs_object_types. Starting with this
  -- object's actual type, traverse the type hierarchy upwards until
  -- a non-null name_method value is found.
  --
  -- select name_method
  --  from acs_object_types
  -- start with object_type = (select object_type
  --                             from acs_objects o
  --                            where o.object_id = name__object_id)
  -- connect by object_type = prior supertype

  select title into object_name
  from acs_objects
  where object_id = name__object_id;

  if (object_name is not null) then
    return object_name;
  end if;

  for obj_type
  in select ot2.name_method
        from acs_object_types ot1, acs_object_types ot2
       where ot1.object_type = (select object_type
                                 from acs_objects o
                                where o.object_id = name__object_id)
         and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
    order by ot2.tree_sortkey desc
  loop
   if obj_type.name_method != '' and obj_type.name_method is NOT null then

    -- Execute the first name_method we find (since we're traversing
    -- up the type hierarchy from the object's exact type) using
    -- Native Dynamic SQL, to ascertain the name of this object.
    --
    --execute 'select ' || object_type.name_method || '(:1) from dual'

    for obj in execute 'select ' || obj_type.name_method || '(' || name__object_id || ')::varchar as object_name' loop
        object_name := obj.object_name;
        exit;
    end loop;

    exit;
   end if;
  end loop;

  return object_name;
  
END;
$$ LANGUAGE plpgsql stable strict;


-- function default_name

select define_function_args('acs_object__default_name','object_id');



--
-- procedure acs_object__default_name/1
--
CREATE OR REPLACE FUNCTION acs_object__default_name(
   default_name__object_id integer
) RETURNS varchar AS $$
DECLARE
  object_type_pretty_name   acs_object_types.pretty_name%TYPE;
BEGIN
  select ot.pretty_name
  into object_type_pretty_name
  from acs_objects o, acs_object_types ot
  where o.object_id = default_name__object_id
  and o.object_type = ot.object_type;

  return object_type_pretty_name || ' ' || default_name__object_id;

END;
$$ LANGUAGE plpgsql stable strict;


-- function package_id

select define_function_args('acs_object__package_id','object_id');

--
-- procedure acs_object__package_id/1
--
CREATE OR REPLACE FUNCTION acs_object__package_id(
   p_object_id integer
) RETURNS integer AS $$
DECLARE
  v_package_id acs_objects.package_id%TYPE;
BEGIN
  if p_object_id is null then
    return null;
  end if;

  select package_id into v_package_id
  from acs_objects
  where object_id = p_object_id;

  return v_package_id;
END;
$$ LANGUAGE plpgsql stable strict;


-- procedure get_attribute_storage

select define_function_args('acs_object__get_attribute_storage','object_id_in,attribute_name_in');



--
-- procedure acs_object__get_attribute_storage/2
--
CREATE OR REPLACE FUNCTION acs_object__get_attribute_storage(
   object_id_in integer,
   attribute_name_in varchar
) RETURNS text AS $$
DECLARE

--  these three are the out variables
  v_column               varchar;  
  v_table_name           varchar;  
  v_key_sql              text;
  
  v_object_type          acs_attributes.object_type%TYPE;
  v_static               acs_attributes.static_p%TYPE;
  v_attr_id              acs_attributes.attribute_id%TYPE;
  v_storage              acs_attributes.storage%TYPE;
  v_attr_name            acs_attributes.attribute_name%TYPE;
  v_id_column            varchar(200);   
  v_sql                  text;  
  v_return               text;  
  v_rec                  record;
BEGIN
   --   select 
   --     object_type, id_column
   --   from
   --     acs_object_types
   --   connect by
   --     object_type = prior supertype
   --   start with
   --     object_type = (select object_type from acs_objects 
   --                    where object_id = object_id_in)

   -- Determine the attribute parameters
   select
     a.attribute_id, a.static_p, a.storage, a.table_name, a.attribute_name,
     a.object_type, a.column_name, t.id_column 
   into 
     v_attr_id, v_static, v_storage, v_table_name, v_attr_name, 
     v_object_type, v_column, v_id_column
   from 
     acs_attributes a,
     (select ot2.object_type, ot2.id_column
       from acs_object_types ot1, acs_object_types ot2
      where ot1.object_type = (select object_type
                                from acs_objects o
                               where o.object_id = object_id_in)
        and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
     ) t
   where   
     a.attribute_name = attribute_name_in
   and
     a.object_type = t.object_type;

   if NOT FOUND then 
      raise EXCEPTION '-20000: No such attribute % for object % in acs_object.get_attribute_storage.', attribute_name_in, object_id_in;
   end if;

   -- This should really be done in a trigger on acs_attributes,
   -- instead of generating it each time in this function

   -- If there is no specific table name for this attribute,
   -- figure it out based on the object type
   if v_table_name is null or v_table_name = '' then

     -- Determine the appropriate table name
     if v_storage = 'generic' then
       -- Generic attribute: table name/column are hardcoded

       v_column := 'attr_value';

       if v_static = 'f' then
         v_table_name := 'acs_attribute_values';
         v_key_sql := '(object_id = ' || object_id_in || ' and ' ||
                      'attribute_id = ' || v_attr_id || ')';
       else
         v_table_name := 'acs_static_attr_values';
         v_key_sql := '(object_type = ''' || v_object_type || ''' and ' ||
                      'attribute_id = ' || v_attr_id || ')';
       end if;

     else
       -- Specific attribute: table name/column need to be retrieved
 
       if v_static = 'f' then
         select 
           table_name, id_column 
         into 
           v_table_name, v_id_column
         from 
           acs_object_types 
         where 
           object_type = v_object_type;
         if NOT FOUND then 
            raise EXCEPTION '-20000: No data found for attribute %::% object_id % in acs_object.get_attribute_storage', v_object_type, attribute_name_in, object_id_in;
         end if;
       else
         raise EXCEPTION '-20000: No table name specified for storage specific static attribute %::% object_id % in acs_object.get_attribute_storage.',v_object_type, attribute_name_in, object_id_in;
       end if;
  
     end if;
   else 
     -- There is a custom table name for this attribute.
     -- Get the id column out of the acs_object_tables
     -- Raise an error if not found
     select id_column into v_id_column from acs_object_type_tables
       where object_type = v_object_type 
       and table_name = v_table_name;
       if NOT FOUND then 
          raise EXCEPTION '-20000: No data found for attribute %::% object_id % in acs_object.get_attribute_storage', v_object_type, attribute_name_in, object_id_in;
       end if;
   end if;

   if v_column is null or v_column = '' then

     if v_storage = 'generic' then
       v_column := 'attr_value';
     else
       v_column := v_attr_name;
     end if;

   end if;

   if v_key_sql is null or v_key_sql = '' then
     if v_static = 'f' then   
       v_key_sql := v_id_column || ' = ' || object_id_in ; 
     else
       v_key_sql := v_id_column || ' = ''' || v_object_type || '''';
     end if;
   end if;

   return v_column || ',' || v_table_name || ',' || v_key_sql; 

END;
$$ LANGUAGE plpgsql stable;


select define_function_args('acs_object__get_attr_storage_column','v_vals');



--
-- procedure acs_object__get_attr_storage_column/1
--
CREATE OR REPLACE FUNCTION acs_object__get_attr_storage_column(
   v_vals text
) RETURNS text AS $$
DECLARE
        v_idx   integer;
BEGIN
        v_idx := strpos(v_vals,',');
        if v_idx = 0 or v_vals is null then 
           raise exception 'invalid storage format: acs_object.get_attr_storage_column %',v_vals;
        end if;

        return substr(v_vals,1,v_idx - 1);

END;
$$ LANGUAGE plpgsql immutable;

select define_function_args('acs_object__get_attr_storage_table','v_vals');



--
-- procedure acs_object__get_attr_storage_table/1
--
CREATE OR REPLACE FUNCTION acs_object__get_attr_storage_table(
   v_vals text
) RETURNS text AS $$
DECLARE
        v_idx   integer;
        v_tmp   varchar;
BEGIN
        v_idx := strpos(v_vals,',');

        if v_idx = 0 or v_vals is null then 
           raise exception 'invalid storage format: acs_object.get_attr_storage_table %',v_vals;
        end if;

        v_tmp := substr(v_vals,v_idx + 1);
        v_idx := strpos(v_tmp,',');
        if v_idx = 0 then 
           raise exception 'invalid storage format: acs_object.get_attr_storage_table %',v_vals;
        end if;

        return substr(v_tmp,1,v_idx - 1);

END;
$$ LANGUAGE plpgsql immutable;

select define_function_args('acs_object__get_attr_storage_sql','v_vals');



--
-- procedure acs_object__get_attr_storage_sql/1
--
CREATE OR REPLACE FUNCTION acs_object__get_attr_storage_sql(
   v_vals text
) RETURNS text AS $$
DECLARE
        v_idx   integer;
        v_tmp   varchar;
BEGIN
        v_idx := strpos(v_vals, ',');

        if v_idx = 0 or v_vals is null then 
           raise exception 'invalid storage format: acs_object.get_attr_storage_sql %',v_vals;
        end if;

        v_tmp := substr(v_vals, v_idx + 1);
        v_idx := strpos(v_tmp, ',');
        if v_idx = 0 then 
           raise exception 'invalid storage format: acs_object.get_attr_storage_sql %',v_vals;
        end if;

        return substr(v_tmp, v_idx + 1);

END;
$$ LANGUAGE plpgsql immutable;

-- function get_attribute

select define_function_args('acs_object__get_attribute','object_id_in,attribute_name_in');



--
-- procedure acs_object__get_attribute/2
--
CREATE OR REPLACE FUNCTION acs_object__get_attribute(
   object_id_in integer,
   attribute_name_in varchar
) RETURNS text AS $$
DECLARE
  v_table_name           varchar(200);  
  v_column               varchar(200);  
  v_key_sql              text; 
  v_return               text; 
  v_storage              text;
  v_rec                  record;
BEGIN

   v_storage := acs_object__get_attribute_storage(object_id_in, attribute_name_in);

   v_column     := acs_object__get_attr_storage_column(v_storage);
   v_table_name := acs_object__get_attr_storage_table(v_storage);
   v_key_sql    := acs_object__get_attr_storage_sql(v_storage);

   for v_rec in execute 'select ' || quote_ident(v_column) || '::text as column_return from ' || quote_ident(v_table_name) || ' where ' || v_key_sql
      LOOP
        v_return := v_rec.column_return;
        exit;
   end loop;
   if not FOUND then 
       return null;
   end if;

   return v_return;

END;
$$ LANGUAGE plpgsql stable;


-- procedure set_attribute

select define_function_args('acs_object__set_attribute','object_id_in,attribute_name_in,value_in');



--
-- procedure acs_object__set_attribute/3
--
CREATE OR REPLACE FUNCTION acs_object__set_attribute(
   object_id_in integer,
   attribute_name_in varchar,
   value_in varchar
) RETURNS integer AS $$
DECLARE
  v_table_name           varchar;  
  v_column               varchar;  
  v_key_sql              text; 
  v_return               text; 
  v_storage              text;
BEGIN
   if value_in is null then 
	-- this will fail more cryptically in the execute so catch now. 
	raise exception 'acs_object__set_attribute: attempt to set % to null for object_id %',attribute_name_in, object_id_in;
   end if;

   v_storage := acs_object__get_attribute_storage(object_id_in, attribute_name_in);

   v_column     := acs_object__get_attr_storage_column(v_storage);
   v_table_name := acs_object__get_attr_storage_table(v_storage);
   v_key_sql    := acs_object__get_attr_storage_sql(v_storage);

   execute 'update ' || v_table_name || ' set ' || quote_ident(v_column) || ' = ' || quote_literal(value_in) || ' where ' || v_key_sql;

   return 0; 
END;
$$ LANGUAGE plpgsql;


-- function check_context_index

select define_function_args('acs_object__check_context_index','object_id,ancestor_id,n_generations');



--
-- procedure acs_object__check_context_index/3
--
CREATE OR REPLACE FUNCTION acs_object__check_context_index(
   check_context_index__object_id integer,
   check_context_index__ancestor_id integer,
   check_context_index__n_generations integer
) RETURNS boolean AS $$
DECLARE
  n_rows                                      integer;       
  n_gens                                      integer;       
BEGIN
   -- Verify that this row exists in the index.
   if check_context_index__object_id is null or check_context_index__ancestor_id is null then
	raise exception 'object_id or ancestor_id is null in acs_object__check_context_index';
   end if;	
   select case when count(*) = 0 then 0 else 1 end into n_rows
   from acs_object_context_index
   where object_id = check_context_index__object_id
   and ancestor_id = check_context_index__ancestor_id;

   if n_rows = 1 then
     -- Verify that the count is correct.
     select n_generations into n_gens
     from acs_object_context_index
     where object_id = check_context_index__object_id
     and ancestor_id = check_context_index__ancestor_id;

     if n_gens != check_context_index__n_generations then
       PERFORM acs_log__error('acs_object.check_representation', 
                              'Ancestor ' ||
                     check_context_index__ancestor_id || ' of object ' || 
                     check_context_index__object_id ||
		     ' reports being generation ' || n_gens ||
		     ' when it is actually generation ' || 
                     check_context_index__n_generations ||
		     '.');
       return 'f';
     else
       return 't';
     end if;
   else
     PERFORM acs_log__error('acs_object.check_representation', 
                            'Ancestor ' ||
                            check_context_index__ancestor_id || 
                            ' of object ' || check_context_index__object_id 
                            || ' is missing an entry in acs_object_context_index.');
     return 'f';
   end if;
  
END;
$$ LANGUAGE plpgsql;


-- function check_object_ancestors


-- added
select define_function_args('acs_object__check_object_ancestors','object_id,ancestor_id,n_generations');

--
-- procedure acs_object__check_object_ancestors/3
--
CREATE OR REPLACE FUNCTION acs_object__check_object_ancestors(
   check_object_ancestors__object_id integer,
   check_object_ancestors__ancestor_id integer,
   check_object_ancestors__n_generations integer
) RETURNS boolean AS $$
DECLARE
  check_object_ancestors__context_id             acs_objects.context_id%TYPE;
  check_object_ancestors__security_inherit_p     acs_objects.security_inherit_p%TYPE;
  n_rows                                         integer;       
  n_gens                                         integer;       
  result                                         boolean;       
BEGIN
   -- OBJECT_ID is the object we are verifying
   -- ANCESTOR_ID is the current ancestor we are tracking
   -- N_GENERATIONS is how far ancestor_id is from object_id

   -- Note that this function is only supposed to verify that the
   -- index contains each ancestor for OBJECT_ID. It doesn't
   -- guarantee that there aren''t extraneous rows or that
   -- OBJECT_ID's children are contained in the index. That is
   -- verified by separate functions.

   result := 't';

   -- Grab the context and security_inherit_p flag of the current
   -- ancestor's parent.
   select context_id, security_inherit_p 
   into check_object_ancestors__context_id, 
        check_object_ancestors__security_inherit_p
   from acs_objects
   where object_id = check_object_ancestors__ancestor_id;

   if check_object_ancestors__ancestor_id = 0 then
     if check_object_ancestors__context_id is null then
       result := 't';
     else
       -- This can be a constraint, can't it?
       PERFORM acs_log__error('acs_object.check_representation',
                     'Object 0 doesn''t have a null context_id');
       result := 'f';
     end if;
   else
     if check_object_ancestors__context_id is null or 
        check_object_ancestors__security_inherit_p = 'f' 
     THEN
       check_object_ancestors__context_id := 0;
     end if;

     if acs_object__check_context_index(check_object_ancestors__object_id, 
                                        check_object_ancestors__ancestor_id, 
                                        check_object_ancestors__n_generations) = 'f' then
       result := 'f';
     end if;

     if acs_object__check_object_ancestors(check_object_ancestors__object_id, 
                                           check_object_ancestors__context_id,
	                      check_object_ancestors__n_generations + 1) = 'f' then
       result := 'f';
     end if;
   end if;

   return result;
  
END;
$$ LANGUAGE plpgsql;


-- function check_object_descendants


-- added
select define_function_args('acs_object__check_object_descendants','object_id,descendant_id,n_generations');

--
-- procedure acs_object__check_object_descendants/3
--
CREATE OR REPLACE FUNCTION acs_object__check_object_descendants(
   object_id integer,
   descendant_id integer,
   n_generations integer
) RETURNS boolean AS $$
DECLARE
  result                 boolean;     
  obj                    record;  
BEGIN
   -- OBJECT_ID is the object we are verifying.
   -- DESCENDANT_ID is the current descendant we are tracking.
   -- N_GENERATIONS is how far the current DESCENDANT_ID is from
   -- OBJECT_ID.

   -- This function will verfy that each actually descendant of
   -- OBJECT_ID has a row in the index table. It does not check that
   -- there aren't extraneous rows or that the ancestors of OBJECT_ID
   -- are maintained correctly.

   result := 't';

   -- First verify that OBJECT_ID and DESCENDANT_ID are actually in
   -- the index.
   if acs_object__check_context_index(descendant_id, object_id, n_generations) = 'f' then
     result := 'f';
   end if;

   -- For every child that reports inheriting from OBJECT_ID we need to call
   -- ourselves recursively.
   for obj in  select *
	       from acs_objects
	       where context_id = descendant_id
	       and security_inherit_p = 't' loop
     if acs_object__check_object_descendants(object_id, obj.object_id,
       n_generations + 1) = 'f' then
       result := 'f';
     end if;
   end loop;

   return result;
  
END;
$$ LANGUAGE plpgsql;


-- function check_path
select define_function_args('acs_object__check_path','object_id,ancestor_id');



--
-- procedure acs_object__check_path/2
--
CREATE OR REPLACE FUNCTION acs_object__check_path(
   check_path__object_id integer,
   check_path__ancestor_id integer
) RETURNS boolean AS $$
DECLARE
  check_path__context_id             acs_objects.context_id%TYPE;
  check_path__security_inherit_p     acs_objects.security_inherit_p%TYPE;
BEGIN
   if check_path__object_id is null or check_path__ancestor_id then
	raise exception 'acs_object__check_path called with null object_id or ancestor_id';
   end if;

   if check_path__object_id = check_path__ancestor_id then
     return 't';
   end if;

   select context_id, security_inherit_p 
   into check_path__context_id, check_path__security_inherit_p
   from acs_objects
   where object_id = check_path__object_id;

   -- we should be able to handle the case where check_path fails 
   -- should we not?

   if check_path__object_id = 0 and check_path__context_id is null then 
      return 'f';
   end if;

   if check_path__context_id is null or check_path__security_inherit_p = 'f' 
   then
     check_path__context_id := 0;
   end if;

   return acs_object__check_path(check_path__context_id, 
                                 check_path__ancestor_id);
  
END;
$$ LANGUAGE plpgsql stable;


-- function check_representation

select define_function_args('acs_object__check_representation','object_id');



--
-- procedure acs_object__check_representation/1
--
CREATE OR REPLACE FUNCTION acs_object__check_representation(
   check_representation__object_id integer
) RETURNS boolean AS $$
DECLARE
  result                                       boolean;       
  check_representation__object_type            acs_objects.object_type%TYPE;
  n_rows                                       integer;    
  v_rec                                        record;  
  row                                          record; 
BEGIN
   if check_representation__object_id is null then 
	raise exception 'acs_object__check_representation called for null object_id';
   end if;

   result := 't';
   PERFORM acs_log__notice('acs_object.check_representation',
                  'Running acs_object.check_representation on object_id = ' 
                  || check_representation__object_id || '.');

   select object_type into check_representation__object_type
   from acs_objects
   where object_id = check_representation__object_id;

   PERFORM acs_log__notice('acs_object.check_representation',
                  'OBJECT STORAGE INTEGRITY TEST');

   for v_rec in  select t.object_type, t.table_name, t.id_column
             from acs_object_type_supertype_map m, acs_object_types t
	     where m.ancestor_type = t.object_type
	     and m.object_type = check_representation__object_type
	     union
	     select object_type, table_name, id_column
	     from acs_object_types
	     where object_type = check_representation__object_type 
     LOOP

        for row in execute 'select case when count(*) = 0 then 0 else 1 end as n_rows from ' || quote_ident(v_rec.table_name) || ' where ' || quote_ident(v_rec.id_column) || ' = ' || check_representation__object_id
        LOOP
            n_rows := row.n_rows;
            exit;
        end LOOP;

        if n_rows = 0 then
           result := 'f';
           PERFORM acs_log__error('acs_object.check_representation',
                     'Table ' || v_rec.table_name || 
                     ' (primary storage for ' ||
		     v_rec.object_type || 
                     ') doesn''t have a row for object ' ||
		     check_representation__object_id || ' of type ' || 
                     check_representation__object_type || '.');
        end if;

   end loop;

   PERFORM acs_log__notice('acs_object.check_representation',
                  'OBJECT CONTEXT INTEGRITY TEST');

   if acs_object__check_object_ancestors(check_representation__object_id, 
                                         check_representation__object_id, 0) = 'f' then
     result := 'f';
   end if;

   if acs_object__check_object_descendants(check_representation__object_id, 
                                           check_representation__object_id, 0) = 'f' then
     result := 'f';
   end if;
   for row in  select object_id, ancestor_id, n_generations
	       from acs_object_context_index
	       where object_id = check_representation__object_id
	       or ancestor_id = check_representation__object_id 
   LOOP
     if acs_object__check_path(row.object_id, row.ancestor_id) = 'f' then
       PERFORM acs_log__error('acs_object.check_representation',
		     'acs_object_context_index contains an extraneous row: '
                     || 'object_id = ' || row.object_id || 
                     ', ancestor_id = ' || row.ancestor_id || 
                     ', n_generations = ' || row.n_generations || '.');
       result := 'f';
     end if;
   end loop;

   PERFORM acs_log__notice('acs_object.check_representation',
		  'Done running acs_object.check_representation ' || 
		  'on object_id = ' || check_representation__object_id || '.');

   return result;
  
END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_object__update_last_modified/3
--
CREATE OR REPLACE FUNCTION acs_object__update_last_modified(
   acs_object__update_last_modified__object_id integer,
   acs_object__update_last_modified__modifying_user integer,
   acs_object__update_last_modified__modifying_ip varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    return acs_object__update_last_modified(acs_object__update_last_modified__object_id, acs_object__update_last_modified__modifying_user, acs_object__update_last_modified__modifying_ip, now());
END;
$$ LANGUAGE plpgsql;



select define_function_args('acs_object__update_last_modified','object_id,modifying_user,modifying_ip,last_modified;now()');

--
-- procedure acs_object__update_last_modified/4
--
CREATE OR REPLACE FUNCTION acs_object__update_last_modified(
   acs_object__update_last_modified__object_id integer,
   acs_object__update_last_modified__modifying_user integer,
   acs_object__update_last_modified__modifying_ip varchar,
   acs_object__update_last_modified__last_modified timestamptz -- default now()

) RETURNS integer AS $$
DECLARE
    v_parent_id                                          integer;
    v_last_modified                                      timestamptz;
BEGIN
    if acs_object__update_last_modified__last_modified is null then
        v_last_modified := now();
    else
        v_last_modified := acs_object__update_last_modified__last_modified;
    end if;

    update acs_objects
    set last_modified = v_last_modified,
        modifying_user = acs_object__update_last_modified__modifying_user,
        modifying_ip = acs_object__update_last_modified__modifying_ip
    where object_id = acs_object__update_last_modified__object_id;

    select context_id
    into v_parent_id
    from acs_objects
    where object_id = acs_object__update_last_modified__object_id;

    if v_parent_id is not null and v_parent_id != 0 then
        perform acs_object__update_last_modified(v_parent_id, acs_object__update_last_modified__modifying_user, acs_object__update_last_modified__modifying_ip, v_last_modified);
    end if;

    return acs_object__update_last_modified__object_id;
END;
$$ LANGUAGE plpgsql;

-- show errors

-------------------
-- MISCELLANEOUS --
-------------------

create table general_objects (
	object_id		integer not null
				constraint general_objects_object_id_fk
				references acs_objects (object_id)
				constraint general_objects_object_id_pk
				primary key,
	on_which_table		varchar(30) not null,
	on_what_id		integer not null,
	constraint general_objects_un
		unique (on_which_table, on_what_id)
);

comment on table general_objects is '
 This table can be used to treat non-acs_objects as acs_objects for
 purposes of access control, categorization, etc.
';
