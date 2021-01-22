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

declare
 attr_id acs_attributes.attribute_id%TYPE;
begin
 --
 -- The ultimate supertype: object
 --
 acs_object_type.create_type (
   supertype => null,
   object_type => 'acs_object',
   pretty_name => 'Object',
   pretty_plural => 'Objects',
   table_name => 'acs_objects',
   id_column => 'object_id',
   package_name => 'acs_object',
   name_method => 'acs_object.default_name'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'acs_object',
   attribute_name => 'object_type',
   datatype => 'string',
   pretty_name => 'Object Type',
   pretty_plural => 'Object Types'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'acs_object',
   attribute_name => 'creation_date',
   datatype => 'date',
   pretty_name => 'Created Date'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'acs_object',
   attribute_name => 'creation_ip',
   datatype => 'string',
   pretty_name => 'Creation IP Address'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'acs_object',
   attribute_name => 'last_modified',
   datatype => 'date',
   pretty_name => 'Last Modified On'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'acs_object',
   attribute_name => 'modifying_ip',
   datatype => 'string',
   pretty_name => 'Modifying IP Address'
 );

 attr_id := acs_attribute.create_attribute (
   object_type => 'acs_object',
   attribute_name => 'modifying_user',
   datatype => 'integer',
   pretty_name => 'Modifying User'
 );

 attr_id := acs_attribute.create_attribute (
        object_type => 'acs_object',
        attribute_name => 'creation_user',
        datatype => 'integer',
        pretty_name => 'Creation user',
        pretty_plural => 'Creation users',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'acs_object',
        attribute_name => 'context_id',
        datatype => 'integer',
        pretty_name => 'Context ID',
        pretty_plural => 'Context IDs',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'acs_object',
        attribute_name => 'package_id',
        datatype => 'integer',
        pretty_name => 'Package ID',
        pretty_plural => 'Package IDs',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'acs_object',
        attribute_name => 'title',
        datatype => 'string',
        pretty_name => 'Title',
        pretty_plural => 'Titles',
	min_n_values => 0,
	max_n_values => 1
      );

 commit;
end;
/
show errors

-- ******************************************************************
-- * OPERATIONAL LEVEL
-- ******************************************************************

-------------
-- OBJECTS --
-------------

create sequence acs_object_id_seq cache 1000;

create table acs_objects (
	object_id		integer 
				constraint acs_objects_object_id_nn not null
				constraint acs_objects_object_id_pk primary key,
	object_type		constraint acs_objects_object_type_nn not null
				constraint acs_objects_object_type_fk
				references acs_object_types (object_type),
        title			varchar2(1000) default null,
        package_id		integer default null,
        context_id		constraint acs_objects_context_id_fk
				references acs_objects(object_id),
	security_inherit_p	char(1) default 't' not null,
				constraint acs_objects_sec_inherit_p_ck
				check (security_inherit_p in ('t', 'f')),
	creation_user		integer,
	creation_date		date default sysdate 
				constraint acs_objects_creation_date_nn not null,
	creation_ip		varchar2(50),
	last_modified		date default sysdate 
				constraint acs_objects_last_modified_nn not null,
	modifying_user		integer,
	modifying_ip		varchar2(50),
        constraint acs_objects_context_object_un
	unique (context_id, object_id) disable
);

create index acs_objects_context_object_idx on acs_objects (context_id, object_id);

alter table acs_objects modify constraint acs_objects_context_object_un enable;

create index acs_objects_creation_user_idx on acs_objects (creation_user);
create index acs_objects_modify_user_idx on acs_objects (modifying_user);

create index acs_objects_package_idx on acs_objects (package_id);
create index acs_objects_title_idx on acs_objects(title);

-- create bitmap index acs_objects_object_type_idx on acs_objects (object_type);
create index acs_objects_object_type_idx on acs_objects (object_type);

create or replace trigger acs_objects_mod_ip_insert_tr
before insert on acs_objects
for each row
begin
 :new.modifying_ip := :new.creation_ip;
end acs_objects_mod_ip_insert_tr;
/
show errors

create or replace trigger acs_objects_last_mod_update_tr
before update on acs_objects
for each row
begin
  if :new.last_modified is null then
     :new.last_modified := :old.last_modified;
  elsif :new.last_modified = :old.last_modified then
     :new.last_modified := sysdate;
  end if;
end acs_objects_last_mod_update_tr;
/
show errors


comment on table acs_objects is '
';

comment on column acs_objects.context_id is '
 The context_id column points to an object that provides a context for
 this object. Often this will reflect an observed hierarchy in a site,
 for example a bboard message would probably list a bboard topic as
 it''s context, and a bboard topic might list a sub-site as it''s
 context. Whenever we ask a question of the form "can user X perform
 action Y on object Z", the acs security model will defer to an
 object''s context if there is no information about user X''s
 permission to perform action Y on object Z.
';

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
	object_id	not null
                        constraint acs_obj_context_idx_obj_id_fk
			references acs_objects(object_id),
	ancestor_id	not null
                        constraint acs_obj_context_idx_anc_id_fk
			references acs_objects(object_id),
	n_generations	integer not null
			constraint acs_obj_context_idx_n_gen_ck
			check (n_generations >= 0),
        constraint acs_object_context_index_pk
	primary key (object_id, ancestor_id)
) organization index;

create index acs_obj_ctx_idx_ancestor_idx on acs_object_context_index (ancestor_id);
create index acs_obj_ctx_idx_object_id_idx on acs_object_context_index (object_id);

create or replace view acs_object_paths
as select object_id, ancestor_id, n_generations
   from acs_object_context_index;

create or replace view acs_object_contexts
as select object_id, ancestor_id, n_generations
   from acs_object_context_index
   where object_id != ancestor_id;

create or replace trigger acs_objects_context_id_in_tr
after insert on acs_objects
for each row
declare
  security_context_root acs_objects.object_id%TYPE;
begin

  -- Hate the hardwiring but magic objects aren't defined yet (PG doesn't
  -- mind because function bodies aren't compiled until first called)

  security_context_root := -4;

  insert into acs_object_context_index
   (object_id, ancestor_id, n_generations)
  values
   (:new.object_id, :new.object_id, 0);

  if :new.context_id is not null and :new.security_inherit_p = 't' then
    insert into acs_object_context_index
     (object_id, ancestor_id,
      n_generations)
    select
     :new.object_id as object_id, ancestor_id,
     n_generations + 1 as n_generations
    from acs_object_context_index
    where object_id = :new.context_id;
  else
    if :new.object_id != security_context_root then
      insert into acs_object_context_index
        (object_id, ancestor_id, n_generations)
      values
        (:new.object_id, security_context_root, 1);
    end if;
  end if;
end;
/
show errors

create or replace trigger acs_objects_context_id_up_tr
after update on acs_objects
for each row
declare
  security_context_root acs_objects.object_id%TYPE;
begin
  if :new.object_id = :old.object_id
     and (:new.context_id = :old.context_id
	  or (:new.context_id is null and :old.context_id is null))
     and :new.security_inherit_p = :old.security_inherit_p then
    return;
  end if;

  -- Hate the hardwiring but magic objects aren't defined yet (PG doesn't
  -- mind because function bodies aren't compiled until first called)

  security_context_root := -4;

  -- Remove my old ancestors from my descendants.
  for pair in ( select object_id from acs_object_contexts where
                ancestor_id = :old.object_id) loop
    delete from acs_object_context_index
    where object_id = pair.object_id
      and ancestor_id in ( select ancestor_id from acs_object_contexts
                           where object_id = :old.object_id );
  end loop;

  -- Kill all my old ancestors.
  delete from acs_object_context_index
  where object_id = :old.object_id;

  insert into acs_object_context_index
   (object_id, ancestor_id, n_generations)
  values
   (:new.object_id, :new.object_id, 0);

  if :new.context_id is not null and :new.security_inherit_p = 't' then
     -- Now insert my new ancestors for my descendants.
    for pair in (select *
		 from acs_object_context_index
		 where ancestor_id = :new.object_id) loop
      insert into acs_object_context_index
       (object_id, ancestor_id, n_generations)
      select
       pair.object_id, ancestor_id,
       n_generations + pair.n_generations + 1 as n_generations
      from acs_object_context_index
      where object_id = :new.context_id;
    end loop;
  else
    if :new.object_id != 0 then
      -- We need to make sure that :NEW.OBJECT_ID and all of its
      -- children have security_context_root as an ancestor.
      for pair in (select *
		   from acs_object_context_index
		   where ancestor_id = :new.object_id)
      loop
        insert into acs_object_context_index
          (object_id, ancestor_id, n_generations)
        values
          (pair.object_id, security_context_root, pair.n_generations + 1);
      end loop;
    end if;
  end if;
end;
/
show errors

create or replace trigger acs_objects_context_id_del_tr
before delete on acs_objects
for each row
begin
  delete from acs_object_context_index
  where object_id = :old.object_id;
end;
/
show errors

----------------------
-- ATTRIBUTE VALUES --
----------------------

create sequence acs_attribute_value_id_seq;

create table acs_attribute_values (
	object_id	not null
			constraint acs_attr_values_obj_id_fk
			references acs_objects (object_id) on delete cascade,
	attribute_id	not null
			constraint acs_attr_values_attr_id_fk
			references acs_attributes (attribute_id),
	attr_value	varchar2(4000),
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
	object_type	not null
			constraint acs_static_a_v_obj_id_fk
			references acs_object_types (object_type) on delete cascade,
	attribute_id	not null
			constraint acs_static_a_v_attr_id_fk
			references acs_attributes (attribute_id),
	attr_value	varchar2(4000),
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

create or replace package acs_object
as

 function new (
  object_id	in acs_objects.object_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
			   default 'acs_object',
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  context_id    in acs_objects.context_id%TYPE default null,
  security_inherit_p in acs_objects.security_inherit_p%TYPE default 't',
  title		in acs_objects.title%TYPE default null,
  package_id    in acs_objects.package_id%TYPE default null
 ) return acs_objects.object_id%TYPE;

 procedure del (
  object_id	in acs_objects.object_id%TYPE
 );

 function name (
  object_id	in acs_objects.object_id%TYPE
 ) return varchar2;

 -- The acs_object_types.name_method for "acs_object"
 --
 function default_name (
  object_id	in acs_objects.object_id%TYPE
 ) return varchar2;

 function package_id (
  object_id	in acs_objects.object_id%TYPE
 ) return acs_objects.package_id%TYPE;

 -- Determine where the attribute is stored and what sql needs to be
 -- in the where clause to retrieve it
 -- Used in get_attribute and set_attribute
 procedure get_attribute_storage ( 
   object_id_in      in  acs_objects.object_id%TYPE,
   attribute_name_in in  acs_attributes.attribute_name%TYPE,
   v_column          out varchar2,
   v_table_name      out varchar2,
   v_key_sql         out varchar2
 );

 -- Get/set the value of an object attribute, as long as
 -- the type can be cast to varchar2
 function get_attribute (
   object_id_in      in  acs_objects.object_id%TYPE,
   attribute_name_in in  acs_attributes.attribute_name%TYPE
 ) return varchar2;

 procedure set_attribute (
   object_id_in      in  acs_objects.object_id%TYPE,
   attribute_name_in in  acs_attributes.attribute_name%TYPE,
   value_in          in  varchar2
 );

 function check_representation (
   object_id		in acs_objects.object_id%TYPE
 ) return char;

    procedure update_last_modified (
        object_id in acs_objects.object_id%TYPE,
        modifying_user in acs_objects.modifying_user%TYPE,
        modifying_ip in acs_objects.modifying_ip%TYPE,
        last_modified in acs_objects.last_modified%TYPE default sysdate
    );

end acs_object;
/
show errors

create or replace package body acs_object
as

 procedure initialize_attributes (
   object_id	in acs_objects.object_id%TYPE
 )
 is
   v_object_type acs_objects.object_type%TYPE; 
 begin
   -- XXX This should be fixed to initialize supertypes properly.

   -- Initialize dynamic attributes
   insert into acs_attribute_values
    (object_id, attribute_id, attr_value)
   select
    initialize_attributes.object_id, a.attribute_id, a.default_value
   from acs_attributes a, acs_objects o
   where a.object_type = o.object_type
   and o.object_id = initialize_attributes.object_id
   and a.storage = 'generic'
   and a.static_p = 'f';

   -- Retrieve type for static attributes
   select object_type into v_object_type from acs_objects
     where object_id = initialize_attributes.object_id;

   -- Initialize static attributes
   begin
     insert into acs_static_attr_values
      (object_type, attribute_id, attr_value)
     select
      v_object_type, a.attribute_id, a.default_value
     from acs_attributes a, acs_objects o
     where a.object_type = o.object_type
       and o.object_id = initialize_attributes.object_id
       and a.storage = 'generic'
       and a.static_p = 't'
       and not exists (select 1 from acs_static_attr_values
                       where object_type = a.object_type);
   exception when no_data_found then null;
   end;
 
 end initialize_attributes;

 function new (
  object_id	in acs_objects.object_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'acs_object',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  context_id    in acs_objects.context_id%TYPE default null,
  security_inherit_p in acs_objects.security_inherit_p%TYPE default 't',
  title		in acs_objects.title%TYPE default null,
  package_id    in acs_objects.package_id%TYPE default null
 )
 return acs_objects.object_id%TYPE
 is
  v_object_id acs_objects.object_id%TYPE;
  v_title acs_objects.title%TYPE;
  v_object_type_pretty_name acs_object_types.pretty_name%TYPE;
  v_creation_date acs_objects.creation_date%TYPE;
 begin
  if object_id is null then
   select acs_object_id_seq.nextval
   into v_object_id
   from dual;
  else
    v_object_id := object_id;
  end if;

  if title is null then
   select pretty_name
   into v_object_type_pretty_name
   from acs_object_types
   where object_type = new.object_type;

   v_title := v_object_type_pretty_name || ' ' || v_object_id;
  else
    v_title := title;
  end if;

  if creation_date is null then
    select sysdate into v_creation_date from dual;
  else
    v_creation_date := creation_date;
  end if;

  insert into acs_objects
   (object_id, object_type, context_id, creation_date,
    creation_user, creation_ip, security_inherit_p, title, package_id)
  values
   (v_object_id, object_type, context_id, v_creation_date,
    creation_user, creation_ip, security_inherit_p, v_title, package_id);

  acs_object.initialize_attributes(v_object_id);

  return v_object_id;
 end new;

 procedure del (
  object_id	in acs_objects.object_id%TYPE
 )
 is
   v_exists_p char;
 begin
  
  -- Delete dynamic/generic attributes
  delete from acs_attribute_values where object_id = acs_object.del.object_id;

  -- Delete directly assigned permissions
  --
  -- JCD: We do this as an execute rather than just a direct query since 
  -- the acs_permissions table is not created when this file is
  -- sourced. We need to clean up the creates and once that is done
  -- we can turn this into a simple delete statement.
  --
  execute immediate 'delete from acs_permissions where object_id = :object_id'
  using in object_id;

  execute immediate 'delete from acs_permissions where grantee_id = :object_id'
  using in object_id;

  for object_type
  in (select table_name, id_column
      from acs_object_types
      start with object_type = (select object_type
                                from acs_objects o
                                where o.object_id = acs_object.del.object_id)
      connect by object_type = prior supertype)
  loop
    -- Delete from the table if it exists.
    select decode(count(*),0,'f','t') into v_exists_p
    from user_tables
    where table_name = upper(object_type.table_name);

    if v_exists_p = 't' then
      execute immediate 'delete from ' || object_type.table_name ||
        ' where ' || object_type.id_column || ' = :object_id'
      using in object_id;
    end if;

  end loop;

 end del;

 function name (
  object_id	in acs_objects.object_id%TYPE
 )
 return varchar2
 is
  object_name acs_objects.title%TYPE;
  v_object_id integer := object_id;
 begin
  -- Find the name function for this object, which is stored in the
  -- name_method column of acs_object_types. Starting with this
  -- object's actual type, traverse the type hierarchy upwards until
  -- a non-null name_method value is found.
  --
  select title into object_name
  from acs_objects
  where object_id = name.object_id;

  if (object_name is not null) then
    return object_name;
  end if;

  for object_type
  in (select name_method
      from acs_object_types
      start with object_type = (select object_type
                                from acs_objects o
                                where o.object_id = name.object_id)
      connect by object_type = prior supertype)
  loop
   if object_type.name_method is not null then

    -- Execute the first name_method we find (since we're traversing
    -- up the type hierarchy from the object's exact type) using
    -- Native Dynamic SQL, to ascertain the name of this object.
    --
    --execute immediate 'select ' || object_type.name_method || '(:1) from dual'
    execute immediate 'begin :1 := ' || object_type.name_method || '(:2); end;'
    using out object_name, in object_id;
    --into object_name

    exit;
   end if;
  end loop;

  return object_name;
 end name;

 function default_name (
  object_id in acs_objects.object_id%TYPE
 ) return varchar2
 is
  object_type_pretty_name acs_object_types.pretty_name%TYPE;
 begin
  select ot.pretty_name
  into object_type_pretty_name
  from acs_objects o, acs_object_types ot
  where o.object_id = default_name.object_id
  and o.object_type = ot.object_type;

  return object_type_pretty_name || ' ' || object_id;
 end default_name;

 function package_id (
  object_id	in acs_objects.object_id%TYPE
 ) return acs_objects.package_id%TYPE
 is
  v_package_id acs_objects.package_id%TYPE;
 begin
  if object_id is null then
    return null;
  end if;

  select package_id into v_package_id
  from acs_objects
  where object_id = package_id.object_id;

  return v_package_id;
 end package_id;

 procedure get_attribute_storage ( 
   object_id_in      in  acs_objects.object_id%TYPE,
   attribute_name_in in  acs_attributes.attribute_name%TYPE,
   v_column          out varchar2,
   v_table_name      out varchar2,
   v_key_sql         out varchar2
 )
 is
   v_object_type	acs_attributes.object_type%TYPE;
   v_static		acs_attributes.static_p%TYPE := null;
   v_attr_id		acs_attributes.attribute_id%TYPE := null;
   v_storage		acs_attributes.storage%TYPE := null;
   v_attr_name		acs_attributes.attribute_name%TYPE := null;
   v_id_column		varchar2(200) := null;
   v_sql		varchar2(4000) := null;
   v_return		varchar2(4000) := null;

   -- Fetch the most inherited attribute
   cursor c_attribute is
   select
     a.attribute_id, a.static_p, a.storage, a.table_name, a.attribute_name,
     a.object_type, a.column_name, t.id_column
   from 
     acs_attributes a,
     (select 
        object_type, id_column
      from
        acs_object_types
      connect by
        object_type = prior supertype
      start with
        object_type = (select object_type from acs_objects 
                       where object_id = object_id_in)
     ) t
   where   
     a.attribute_name = attribute_name_in
   and
     a.object_type = t.object_type;                          

 begin
 
   -- Determine the attribute parameters
   open c_attribute;
   fetch c_attribute into
     v_attr_id, v_static, v_storage, v_table_name, v_attr_name, 
     v_object_type, v_column, v_id_column;
   if c_attribute%NOTFOUND then
     close c_attribute; 
     raise_application_error (-20000, 
          'No such attribute ' || v_object_type || '::' || attribute_name_in || 
          ' in acs_object.get_attribute_storage.');
   end if;
   close c_attribute;    

   -- This should really be done in a trigger on acs_attributes,
   -- instead of generating it each time in this function

   -- If there is no specific table name for this attribute,
   -- figure it out based on the object type
   if v_table_name is null then

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
       else
         raise_application_error(-20000, 
          'No table name specified for storage specific static attribute ' || 
          v_object_type || '::' || attribute_name_in || 
          ' in acs_object.get_attribute_storage.');
       end if;
  
     end if;
   else 
     -- There is a custom table name for this attribute.
     -- Get the id column out of the acs_object_tables
     -- Raise an error if not found
     select id_column into v_id_column from acs_object_type_tables
       where object_type = v_object_type 
       and table_name = v_table_name;

   end if;

   if v_column is null then

     if v_storage = 'generic' then
       v_column := 'attr_value';
     else
       v_column := v_attr_name;
     end if;

   end if;

   if v_key_sql is null then
     if v_static = 'f' then   
       v_key_sql := v_id_column || ' = ' || object_id_in ; 
     else
       v_key_sql := v_id_column || ' = ''' || v_object_type || '''';
     end if;
   end if;

 exception when no_data_found then
   if c_attribute%ISOPEN then
      close c_attribute;
   end if;
   raise_application_error(-20000, 'No data found for attribute ' || 
     v_object_type || '::' || attribute_name_in || 
     ' in acs_object.get_attribute_storage');

 end get_attribute_storage;   

 -- Get/set the value of an object attribute, as long as
 -- the type can be cast to varchar2
 function get_attribute (
   object_id_in      in  acs_objects.object_id%TYPE,
   attribute_name_in in  acs_attributes.attribute_name%TYPE
 ) return varchar2
 is
   v_table_name varchar2(200);
   v_column     varchar2(200);
   v_key_sql    varchar2(4000);
   v_return     varchar2(4000);
 begin

   get_attribute_storage(object_id_in, attribute_name_in,
                         v_column, v_table_name, v_key_sql);

   begin
     execute immediate 'select ' 
      || v_column || ' from ' || v_table_name || ' where ' || v_key_sql 
     into
       v_return; 
   exception when no_data_found then
     return null;
   end;

   return v_return;
 end get_attribute;

 procedure set_attribute (
   object_id_in      in  acs_objects.object_id%TYPE,
   attribute_name_in in  acs_attributes.attribute_name%TYPE,
   value_in          in  varchar2
 )
 is
   v_table_name varchar2(200);
   v_column     varchar2(200);
   v_key_sql    varchar2(4000);
   v_return     varchar2(4000);
   v_dummy      integer;
 begin

   get_attribute_storage(object_id_in, attribute_name_in,
                         v_column, v_table_name, v_key_sql);

   execute immediate 'update '  
    || v_table_name || ' set ' || v_column || ' = :value where ' || v_key_sql 
   using value_in;

 end set_attribute;

 function check_context_index (
   object_id		in acs_objects.object_id%TYPE,
   ancestor_id		in acs_objects.object_id%TYPE,
   n_generations	in integer
 ) return char
 is
   n_rows integer;
   n_gens integer;
 begin
   -- Verify that this row exists in the index.
   select decode(count(*),0,0,1) into n_rows
   from acs_object_context_index
   where object_id = check_context_index.object_id
   and ancestor_id = check_context_index.ancestor_id;

   if n_rows = 1 then
     -- Verify that the count is correct.
     select n_generations into n_gens
     from acs_object_context_index
     where object_id = check_context_index.object_id
     and ancestor_id = check_context_index.ancestor_id;

     if n_gens != n_generations then
       acs_log.error('acs_object.check_representation', 'Ancestor ' ||
                     ancestor_id || ' of object ' || object_id ||
		     ' reports being generation ' || n_gens ||
		     ' when it is actually generation ' || n_generations ||
		     '.');
       return 'f';
     else
       return 't';
     end if;
   else
     acs_log.error('acs_object.check_representation', 'Ancestor ' ||
                   ancestor_id || ' of object ' || object_id ||
		   ' is missing an entry in acs_object_context_index.');
     return 'f';
   end if;
 end;

 function check_object_ancestors (
   object_id		in acs_objects.object_id%TYPE,
   ancestor_id		in acs_objects.object_id%TYPE,
   n_generations	in integer
 ) return char
 is
   context_id acs_objects.context_id%TYPE;
   security_inherit_p acs_objects.security_inherit_p%TYPE;
   n_rows integer;
   n_gens integer;
   result char(1);
 begin
   -- OBJECT_ID is the object we are verifying
   -- ANCESTOR_ID is the current ancestor we are tracking
   -- N_GENERATIONS is how far ancestor_id is from object_id

   -- Note that this function is only supposed to verify that the
   -- index contains each ancestor for OBJECT_ID. It doesn''t
   -- guarantee that there aren''t extraneous rows or that
   -- OBJECT_ID''s children are contained in the index. That is
   -- verified by separate functions.

   result := 't';

   -- Grab the context and security_inherit_p flag of the current
   -- ancestor''s parent.
   select context_id, security_inherit_p into context_id, security_inherit_p
   from acs_objects
   where object_id = check_object_ancestors.ancestor_id;

   if ancestor_id = 0 then
     if context_id is null then
       result := 't';
     else
       -- This can be a constraint, can''t it?
       acs_log.error('acs_object.check_representation',
                     'Object 0 doesn''t have a null context_id');
       result := 'f';
     end if;
   else
     if context_id is null or security_inherit_p = 'f' then
       context_id := 0;
     end if;

     if check_context_index(object_id, ancestor_id, n_generations) = 'f' then
       result := 'f';
     end if;

     if check_object_ancestors(object_id, context_id,
	                      n_generations + 1) = 'f' then
       result := 'f';
     end if;
   end if;

   return result;
 end;

 function check_object_descendants (
   object_id		in acs_objects.object_id%TYPE,
   descendant_id	in acs_objects.object_id%TYPE,
   n_generations	in integer
 ) return char
 is
   result char(1);
 begin
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
   if check_context_index(descendant_id, object_id, n_generations) = 'f' then
     result := 'f';
   end if;

   -- For every child that reports inheriting from OBJECT_ID we need to call
   -- ourselves recursively.
   for obj in (select *
	       from acs_objects
	       where context_id = descendant_id
	       and security_inherit_p = 't') loop
     if check_object_descendants(object_id, obj.object_id,
       n_generations + 1) = 'f' then
       result := 'f';
     end if;
   end loop;

   return result;
 end;

 function check_path (
   object_id		in acs_objects.object_id%TYPE,
   ancestor_id		in acs_objects.object_id%TYPE
 ) return char
 is
   context_id acs_objects.context_id%TYPE;
   security_inherit_p acs_objects.security_inherit_p%TYPE;
 begin
   if object_id = ancestor_id then
     return 't';
   end if;

   select context_id, security_inherit_p into context_id, security_inherit_p
   from acs_objects
   where object_id = check_path.object_id;

   if context_id is null or security_inherit_p = 'f' then
     context_id := 0;
   end if;

   return check_path(context_id, ancestor_id);
 end;

 function check_representation (
   object_id		in acs_objects.object_id%TYPE
 ) return char
 is
   result char(1);
   object_type acs_objects.object_type%TYPE;
   n_rows integer;
 begin
   result := 't';
   acs_log.notice('acs_object.check_representation',
                  'Running acs_object.check_representation on object_id = ' ||
		  object_id || '.');

   -- If this fails then there isn''t even an object associated with
   -- this id. I'm going to let that error propagate as an exception.
   select object_type into object_type
   from acs_objects
   where object_id = check_representation.object_id;

   acs_log.notice('acs_object.check_representation',
                  'OBJECT STORAGE INTEGRITY TEST');

   -- Let's look through every primary storage table associated with
   -- this object type and all of its supertypes and make sure there
   -- is a row with OBJECT_ID as theh primary key.
   for t in (select t.object_type, t.table_name, t.id_column
             from acs_object_type_supertype_map m, acs_object_types t
	     where m.ancestor_type = t.object_type
	     and m.object_type = check_representation.object_type
	     union
	     select object_type, table_name, id_column
	     from acs_object_types
	     where object_type = check_representation.object_type) loop
     execute immediate 'select decode(count(*),0,0,1) from ' || t.table_name ||
                       ' where ' || t.id_column || ' = ' || object_id
     into n_rows;

     if n_rows = 0 then
       result := 'f';
       acs_log.error('acs_object.check_representation',
		     'Table ' || t.table_name || ' (primary storage for ' ||
		     t.object_type || ') doesn''t have a row for object ' ||
		     object_id || ' of type ' || object_type || '.');
     end if;
   end loop;

   acs_log.notice('acs_object.check_representation',
                  'OBJECT CONTEXT INTEGRITY TEST');

   -- Do a bunch of dirt simple sanity checks.

   -- First let's check that all of our ancestors appear in
   -- acs_object_context_index with the correct generation listed.
   if check_object_ancestors(object_id, object_id, 0) = 'f' then
     result := 'f';
   end if;

   -- Now let's check that all of our descendants appear in
   -- acs_object_context_index with the correct generation listed.
   if check_object_descendants(object_id, object_id, 0) = 'f' then
     result := 'f';
   end if;

   -- Ok, we know that the index contains every entry that it is
   -- supposed to have. Now let's make sure it doesn't contain any
   -- extraneous entries.
   for row in (select *
	       from acs_object_context_index
	       where object_id = check_representation.object_id
	       or ancestor_id = check_representation.object_id) loop
     if check_path(row.object_id, row.ancestor_id) = 'f' then
       acs_log.error('acs_object.check_representation',
		     'acs_object_context_index contains an extraneous row: ' ||
		     'object_id = ' || row.object_id || ', ancestor_id = ' ||
		     row.ancestor_id || ', n_generations = ' ||
		     row.n_generations || '.');
       result := 'f';
     end if;
   end loop;

   acs_log.notice('acs_object.check_representation',
		  'Done running acs_object.check_representation ' || 
		  'on object_id = ' || object_id || '.');
   return result;
 end check_representation;

    procedure update_last_modified (
        object_id in acs_objects.object_id%TYPE,
        modifying_user in acs_objects.modifying_user%TYPE,
        modifying_ip in acs_objects.modifying_ip%TYPE,
        last_modified in acs_objects.last_modified%TYPE default sysdate
    )
    is
        v_parent_id acs_objects.context_id%TYPE;
    begin
        update acs_objects
        set acs_objects.last_modified = acs_object.update_last_modified.last_modified, acs_objects.modifying_user = acs_object.update_last_modified.modifying_user, acs_objects.modifying_ip = acs_object.update_last_modified.modifying_ip
        where acs_objects.object_id in (select ao.object_id
                                        from acs_objects ao
                                        connect by prior ao.context_id = ao.object_id
                                        start with ao.object_id = acs_object.update_last_modified.object_id)
        and acs_objects.context_id is not null
        and acs_objects.object_id != 0;
    end update_last_modified;

end acs_object;
/
show errors

-------------------
-- MISCELLANEOUS --
-------------------

create table general_objects (
	object_id		constraint general_objects_object_id_nn not null
				constraint general_objects_object_id_fk
				references acs_objects (object_id)
				constraint general_objects_object_id_pk
				primary key,
	on_which_table		varchar2(30) 
				constraint go_on_which_table_nn not null,
	on_what_id		integer 
				constraint general_objects_on_what_id_nn not null,
	constraint general_objects_un
		unique (on_which_table, on_what_id)
);

comment on table general_objects is '
 This table can be used to treat non-acs_objects as acs_objects for
 purposes of access control, categorization, etc.
';
