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

-- Should have been added earlier, at least now we save the 4.6.3 - 5.0 upgrade
create view all_users
as
select pa.*, pe.*, u.*
from  parties pa, persons pe, users u
where  pa.party_id = pe.person_id
and pe.person_id = u.user_id;


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
  context_id    in acs_objects.context_id%TYPE default null
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
  context_id    in acs_objects.context_id%TYPE default null
 )
 return acs_objects.object_id%TYPE
 is
  v_object_id acs_objects.object_id%TYPE;
 begin
  if object_id is null then
   select acs_object_id_seq.nextval
   into v_object_id
   from dual;
  else
    v_object_id := object_id;
  end if;

  insert into acs_objects
   (object_id, object_type, context_id,
    creation_date, creation_user, creation_ip)
  values
   (v_object_id, object_type, context_id,
    creation_date, creation_user, creation_ip);

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
  object_name varchar2(500);
  v_object_id integer := object_id;
 begin
  -- Find the name function for this object, which is stored in the
  -- name_method column of acs_object_types. Starting with this
  -- object's actual type, traverse the type hierarchy upwards until
  -- a non-null name_method value is found.
  --
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



-- /packages/acs-kernel/sql/apm-create.sql
--
-- Data model for the OpenACS Package Manager (APM)
--
-- @author Bryan Quinn (bquinn@arsdigita.com)
-- @author Jon Salz (jsalz@mit.edu)
-- @creation-date 2000/04/30
-- @cvs-id $Id$



-- Public Programmer level API.
create or replace package apm
as
  procedure register_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    package_type		in apm_package_types.package_type%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  );

  function update_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE
    	    	    	    	default null,
    pretty_plural		in apm_package_types.pretty_plural%TYPE
    	    	    	    	default null,
    package_uri			in apm_package_types.package_uri%TYPE
    	    	    	    	default null,
    package_type		in apm_package_types.package_type%TYPE
    	    	    	    	default null,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
    	    	    	    	default null,    
    singleton_p			in apm_package_types.singleton_p%TYPE 
    	    	    	    	default null,    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
    	    	    	    	default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) return apm_package_types.package_type%TYPE;   
   
  procedure unregister_package (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 't'
  );

  function register_p (
    package_key		in apm_package_types.package_key%TYPE
  ) return integer;

  -- Informs the APM that this application is available for use.
  procedure register_application (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  );

  -- Remove the application from the system. 
  procedure unregister_application (
    package_key		in apm_package_types.package_key%TYPE,
    -- Delete all objects associated with this application.	
    cascade_p		in char default 'f'
  ); 

  procedure register_service (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  );

  -- Remove the service from the system. 
  procedure unregister_service (
    package_key		in apm_package_types.package_key%TYPE,
    -- Delete all objects associated with this service.	
    cascade_p		in char default 'f'
  ); 

  -- Indicate to APM that a parameter is available to the system.
  function register_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null,
    package_key			in apm_parameters.package_key%TYPE,				
    parameter_name		in apm_parameters.parameter_name%TYPE,
    description			in apm_parameters.description%TYPE
				default null,
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_id%TYPE;

  function update_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
    	    	    	    	default null,
    description			in apm_parameters.description%TYPE
				default null,
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_name%TYPE;

  function parameter_p(
    package_key                 in apm_package_types.package_key%TYPE,
    parameter_name              in apm_parameters.parameter_name%TYPE
  ) return integer;

  -- Remove any uses of this parameter.
  procedure unregister_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null
  );

  -- Return the value of this parameter for a specific package and parameter.
  function get_value (
    parameter_id		in apm_parameter_values.parameter_id%TYPE,
    package_id			in apm_packages.package_id%TYPE		    
  ) return apm_parameter_values.attr_value%TYPE;

  function get_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameter_values.attr_value%TYPE;

  -- Sets a value for a parameter for a package instance.
  procedure set_value (
    parameter_id		in apm_parameter_values.parameter_id%TYPE,
    package_id			in apm_packages.package_id%TYPE,	    
    attr_value			in apm_parameter_values.attr_value%TYPE
  );

  procedure set_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  );	
    		    

end apm;
/
show errors

create or replace package apm_package
as

function new (
  package_id		in apm_packages.package_id%TYPE 
			default null,
  instance_name		in apm_packages.instance_name%TYPE
			default null,
  package_key		in apm_packages.package_key%TYPE,
  object_type		in acs_objects.object_type%TYPE
			default 'apm_package', 
  creation_date		in acs_objects.creation_date%TYPE 
			default sysdate,
  creation_user		in acs_objects.creation_user%TYPE 
			default null,
  creation_ip		in acs_objects.creation_ip%TYPE 
			default null,
  context_id		in acs_objects.context_id%TYPE 
			default null
  ) return apm_packages.package_id%TYPE;

  procedure del (
   package_id		in apm_packages.package_id%TYPE
  );

  function initial_install_p (
	package_key		in apm_packages.package_key%TYPE
  ) return integer;

  function singleton_p (
	package_key		in apm_packages.package_key%TYPE
  ) return integer;

  function num_instances (
	package_key		in apm_package_types.package_key%TYPE
  ) return integer;

  function name (
    package_id		in apm_packages.package_id%TYPE
  ) return varchar2;

  function highest_version (
   package_key		in apm_package_types.package_key%TYPE
  ) return apm_package_versions.version_id%TYPE;
  
    function parent_id (
        package_id in apm_packages.package_id%TYPE
    ) return apm_packages.package_id%TYPE;

end apm_package;
/
show errors

create or replace package apm_package_version
as
  function new (
    version_id			in apm_package_versions.version_id%TYPE
					default null,
    package_key			in apm_package_versions.package_key%TYPE,
    version_name		in apm_package_versions.version_name%TYPE 
					default null,
    version_uri			in apm_package_versions.version_uri%TYPE,
    summary			in apm_package_versions.summary%TYPE,
    description_format		in apm_package_versions.description_format%TYPE,
    description			in apm_package_versions.description%TYPE,
    release_date		in apm_package_versions.release_date%TYPE,
    vendor			in apm_package_versions.vendor%TYPE,
    vendor_uri			in apm_package_versions.vendor_uri%TYPE,
    auto_mount                  in apm_package_versions.auto_mount%TYPE,
    installed_p			in apm_package_versions.installed_p%TYPE
					default 'f',
    data_model_loaded_p		in apm_package_versions.data_model_loaded_p%TYPE
				        default 'f'
  ) return apm_package_versions.version_id%TYPE;

  procedure del (
      version_id		in apm_packages.package_id%TYPE
  );

  procedure enable (
       version_id			in apm_package_versions.version_id%TYPE
  );

  procedure disable (
       version_id			in apm_package_versions.version_id%TYPE
  );

 function edit (
      new_version_id		in apm_package_versions.version_id%TYPE
				default null,
      version_id		in apm_package_versions.version_id%TYPE,
      version_name		in apm_package_versions.version_name%TYPE 
				default null,
      version_uri		in apm_package_versions.version_uri%TYPE,
      summary			in apm_package_versions.summary%TYPE,
      description_format	in apm_package_versions.description_format%TYPE,
      description		in apm_package_versions.description%TYPE,
      release_date		in apm_package_versions.release_date%TYPE,
      vendor			in apm_package_versions.vendor%TYPE,
      vendor_uri		in apm_package_versions.vendor_uri%TYPE,
      auto_mount                in apm_package_versions.auto_mount%TYPE,
      installed_p		in apm_package_versions.installed_p%TYPE
				default 'f',
      data_model_loaded_p	in apm_package_versions.data_model_loaded_p%TYPE
				default 'f'
    ) return apm_package_versions.version_id%TYPE;

  -- Add an interface provided by this version.
  function add_interface(
    interface_id		in apm_package_dependencies.dependency_id%TYPE
			        default null,
    version_id			in apm_package_versions.version_id%TYPE,
    interface_uri		in apm_package_dependencies.service_uri%TYPE,
    interface_version		in apm_package_dependencies.service_version%TYPE
  ) return apm_package_dependencies.dependency_id%TYPE;

  procedure remove_interface(
    interface_id		in apm_package_dependencies.dependency_id%TYPE
  );

  procedure remove_interface(
    interface_uri		in apm_package_dependencies.service_uri%TYPE,
    interface_version		in apm_package_dependencies.service_version%TYPE,
    version_id			in apm_package_versions.version_id%TYPE
  );

  -- Add a requirement for this version.  A requirement is some interface that this
  -- version depends on.
  function add_dependency(
    dependency_id		in apm_package_dependencies.dependency_id%TYPE
			        default null,
    version_id			in apm_package_versions.version_id%TYPE,
    dependency_uri		in apm_package_dependencies.service_uri%TYPE,
    dependency_version		in apm_package_dependencies.service_version%TYPE
  ) return apm_package_dependencies.dependency_id%TYPE;

  procedure remove_dependency(
    dependency_id		in apm_package_dependencies.dependency_id%TYPE
  );

  procedure remove_dependency(
    dependency_uri		in apm_package_dependencies.service_uri%TYPE,
    dependency_version		in apm_package_dependencies.service_version%TYPE,
    version_id			in apm_package_versions.version_id%TYPE
  );

  -- Given a version_name (e.g. 3.2a), return
  -- something that can be lexicographically sorted.
  function sortable_version_name (
    version_name		in apm_package_versions.version_name%TYPE
  ) return varchar2;

  -- Given two version names, return 1 if one > two, -1 if two > one, 0 otherwise. 
  -- Deprecate?
  function version_name_greater(
    version_name_one		in apm_package_versions.version_name%TYPE,
    version_name_two		in apm_package_versions.version_name%TYPE
  ) return integer;

  function upgrade_p(
    path			in varchar2,
    initial_version_name	in apm_package_versions.version_name%TYPE,
    final_version_name		in apm_package_versions.version_name%TYPE
   ) return integer;

  procedure upgrade(
    version_id                  in apm_package_versions.version_id%TYPE
  );

end apm_package_version;
/
show errors

create or replace package apm_package_type
as
 procedure create_type(
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in acs_object_types.pretty_name%TYPE,
    pretty_plural		in acs_object_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    package_type		in apm_package_types.package_type%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE,
    singleton_p			in apm_package_types.singleton_p%TYPE,
    spec_file_path		in apm_package_types.spec_file_path%TYPE default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE default null
  );

  function update_type (    
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in acs_object_types.pretty_name%TYPE
    	    	    	    	default null,
    pretty_plural		in acs_object_types.pretty_plural%TYPE
    	    	    	    	default null,
    package_uri			in apm_package_types.package_uri%TYPE
    	    	    	    	default null,    
    package_type		in apm_package_types.package_type%TYPE
    	    	    	    	default null,
    initial_install_p		in apm_package_types.initial_install_p%TYPE
    	    	    	    	default null,
    singleton_p			in apm_package_types.singleton_p%TYPE
    	    	    	    	default null,
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
    	    	    	    	default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE
    	    	    	    	 default null
  ) return apm_package_types.package_type%TYPE;
  
  procedure drop_type (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 'f'
  );

  function num_parameters (
    package_key         in apm_package_types.package_key%TYPE
  ) return integer;

end apm_package_type;
/
show errors



-- Private APM System API for managing parameter values.
create or replace package apm_parameter_value
as
  function new (
    value_id			in apm_parameter_values.value_id%TYPE default null,
    package_id			in apm_packages.package_id%TYPE,
    parameter_id		in apm_parameter_values.parameter_id%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  ) return apm_parameter_values.value_id%TYPE;

  procedure del (
    value_id			in apm_parameter_values.value_id%TYPE default null
  );
 end apm_parameter_value;
/
show errors

create or replace package apm_application
as

function new (
    application_id	in acs_objects.object_id%TYPE default null,
    instance_name	in apm_packages.instance_name%TYPE
			default null,
    package_key		in apm_package_types.package_key%TYPE,
    object_type		in acs_objects.object_type%TYPE
			   default 'apm_application',
    creation_date	in acs_objects.creation_date%TYPE default sysdate,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null
  ) return acs_objects.object_id%TYPE;

  procedure del (
    application_id		in acs_objects.object_id%TYPE
  );

end;
/
show errors


create or replace package apm_service
as

  function new (
    service_id		in acs_objects.object_id%TYPE default null,
    instance_name	in apm_packages.instance_name%TYPE
			default null,
    package_key		in apm_package_types.package_key%TYPE,
    object_type		in acs_objects.object_type%TYPE default 'apm_service',
    creation_date	in acs_objects.creation_date%TYPE default sysdate,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null
  ) return acs_objects.object_id%TYPE;

  procedure del (
    service_id		in acs_objects.object_id%TYPE
  );

end;
/
show errors

create or replace package body apm
as
  procedure register_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    package_type		in apm_package_types.package_type%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) 
  is
  begin
    apm_package_type.create_type(
    	package_key => register_package.package_key,
	pretty_name => register_package.pretty_name,
	pretty_plural => register_package.pretty_plural,
	package_uri => register_package.package_uri,
	package_type => register_package.package_type,
	initial_install_p => register_package.initial_install_p,
	singleton_p => register_package.singleton_p,
	spec_file_path => register_package.spec_file_path,
	spec_file_mtime => spec_file_mtime
    );
  end register_package;

  function update_package (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE
    	    	    	    	default null,
    pretty_plural		in apm_package_types.pretty_plural%TYPE
    	    	    	    	default null,
    package_uri			in apm_package_types.package_uri%TYPE
    	    	    	    	default null,
    package_type		in apm_package_types.package_type%TYPE
    	    	    	    	default null,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
    	    	    	    	default null,    
    singleton_p			in apm_package_types.singleton_p%TYPE 
    	    	    	    	default null,    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
    	    	    	    	default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) return apm_package_types.package_type%TYPE
  is
  begin
 
    return apm_package_type.update_type(
    	package_key => update_package.package_key,
	pretty_name => update_package.pretty_name,
	pretty_plural => update_package.pretty_plural,
	package_uri => update_package.package_uri,
	package_type => update_package.package_type,
	initial_install_p => update_package.initial_install_p,
	singleton_p => update_package.singleton_p,
	spec_file_path => update_package.spec_file_path,
	spec_file_mtime => update_package.spec_file_mtime
    );

  end update_package;    


 procedure unregister_package (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 't'
  )
  is
  begin
   apm_package_type.drop_type(
	package_key => unregister_package.package_key,
	cascade_p => unregister_package.cascade_p
   );
  end unregister_package;

  function register_p (
    package_key		in apm_package_types.package_key%TYPE
  ) return integer
  is
    v_register_p integer;
  begin
    select decode(count(*),0,0,1) into v_register_p from apm_package_types 
    where package_key = register_p.package_key;
    return v_register_p;
  end register_p;

  procedure register_application (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) 
  is
  begin
    apm.register_package(
	package_key => register_application.package_key,
	pretty_name => register_application.pretty_name,
	pretty_plural => register_application.pretty_plural,
	package_uri => register_application.package_uri,
	package_type => 'apm_application',
	initial_install_p => register_application.initial_install_p,
	singleton_p => register_application.singleton_p,
	spec_file_path => register_application.spec_file_path,
	spec_file_mtime => register_application.spec_file_mtime
   ); 
  end register_application;  

  procedure unregister_application (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 'f'
  )
  is
  begin
   apm.unregister_package (
	package_key => unregister_application.package_key,
	cascade_p => unregister_application.cascade_p
   );
  end unregister_application; 

  procedure register_service (
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in apm_package_types.pretty_name%TYPE,
    pretty_plural		in apm_package_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE 
				default 'f',    
    singleton_p			in apm_package_types.singleton_p%TYPE 
				default 'f',    
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
				default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE 
				default null
  ) 
  is
  begin
   apm.register_package(
	package_key => register_service.package_key,
	pretty_name => register_service.pretty_name,
	pretty_plural => register_service.pretty_plural,
	package_uri => register_service.package_uri,
	package_type => 'apm_service',
	initial_install_p => register_service.initial_install_p,
	singleton_p => register_service.singleton_p,
	spec_file_path => register_service.spec_file_path,
	spec_file_mtime => register_service.spec_file_mtime
   );   
  end register_service;

  procedure unregister_service (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 'f'
  )
  is
  begin
   apm.unregister_package (
	package_key => unregister_service.package_key,
	cascade_p => unregister_service.cascade_p
   );
  end unregister_service;

  -- Indicate to APM that a parameter is available to the system.
  function register_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null,
    package_key			in apm_parameters.package_key%TYPE,				
    parameter_name		in apm_parameters.parameter_name%TYPE,
    description			in apm_parameters.description%TYPE
				default null,
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_id%TYPE
  is
    v_parameter_id apm_parameters.parameter_id%TYPE;
    cursor all_parameters is
       select ap.package_id, p.parameter_id, p.default_value 
       from apm_parameters p, apm_parameter_values v, apm_packages ap
       where p.package_key = ap.package_key
       and p.parameter_id = v.parameter_id (+)
       and v.attr_value is null
       and p.package_key = register_parameter.package_key;       
  begin
    -- Create the new parameter.    
    v_parameter_id := acs_object.new(
       object_id => parameter_id,
       object_type => 'apm_parameter'
    );
    
    insert into apm_parameters 
    (parameter_id, parameter_name, description, package_key, datatype, 
    default_value, section_name, min_n_values, max_n_values)
    values
    (v_parameter_id, register_parameter.parameter_name, register_parameter.description,
    register_parameter.package_key, register_parameter.datatype, 
    register_parameter.default_value, register_parameter.section_name, 
	register_parameter.min_n_values, register_parameter.max_n_values);
    -- Propagate parameter to new instances.	
    for cur_val in all_parameters
      loop
      	apm.set_value(
	    package_id => cur_val.package_id,
	    parameter_id => cur_val.parameter_id, 
	    attr_value => cur_val.default_value
	    ); 	
      end loop;		
    return v_parameter_id;
  end register_parameter;

    function update_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
    	    	    	    	default null,
    description			in apm_parameters.description%TYPE
				default null,
    datatype			in apm_parameters.datatype%TYPE 
				default 'string',
    default_value		in apm_parameters.default_value%TYPE 
				default null,
    section_name		in apm_parameters.section_name%TYPE
				default null,
    min_n_values		in apm_parameters.min_n_values%TYPE 
				default 1,
    max_n_values		in apm_parameters.max_n_values%TYPE 
				default 1
  ) return apm_parameters.parameter_name%TYPE
  is
  begin
    update apm_parameters 
	set parameter_name = nvl(update_parameter.parameter_name, parameter_name),
            default_value  = nvl(update_parameter.default_value, default_value),
            datatype       = nvl(update_parameter.datatype, datatype), 
	    description	   = nvl(update_parameter.description, description),
	    section_name   = nvl(update_parameter.section_name, section_name),
            min_n_values   = nvl(update_parameter.min_n_values, min_n_values),
            max_n_values   = nvl(update_parameter.max_n_values, max_n_values)
      where parameter_id = update_parameter.parameter_id;
    return parameter_id;
  end;

  function parameter_p(
    package_key                 in apm_package_types.package_key%TYPE,
    parameter_name              in apm_parameters.parameter_name%TYPE
  ) return integer 
  is
    v_parameter_p integer;
  begin
    select decode(count(*),0,0,1) into v_parameter_p 
    from apm_parameters
    where package_key = parameter_p.package_key
    and parameter_name = parameter_p.parameter_name;
    return v_parameter_p;
  end parameter_p;

  procedure unregister_parameter (
    parameter_id		in apm_parameters.parameter_id%TYPE 
				default null
  )
  is
  begin
    delete from apm_parameter_values 
    where parameter_id = unregister_parameter.parameter_id;
    delete from apm_parameters 
    where parameter_id = unregister_parameter.parameter_id;
    acs_object.del(parameter_id);
  end unregister_parameter;

  function id_for_name (
    parameter_name		in apm_parameters.parameter_name%TYPE,
    package_key			in apm_parameters.package_key%TYPE
  ) return apm_parameters.parameter_id%TYPE
  is
    a_parameter_id apm_parameters.parameter_id%TYPE; 
  begin
    select parameter_id into a_parameter_id
    from apm_parameters p
    where p.parameter_name = id_for_name.parameter_name and
          p.package_key = id_for_name.package_key;
    return a_parameter_id;
  end id_for_name;
		
  function get_value (
    parameter_id		in apm_parameter_values.parameter_id%TYPE,
    package_id			in apm_packages.package_id%TYPE		    
  ) return apm_parameter_values.attr_value%TYPE
  is
    value apm_parameter_values.attr_value%TYPE;
  begin
    select attr_value into value from apm_parameter_values v
    where v.package_id = get_value.package_id
    and parameter_id = get_value.parameter_id;
    return value;
  end get_value;

  function get_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE
  ) return apm_parameter_values.attr_value%TYPE
  is
    v_parameter_id apm_parameter_values.parameter_id%TYPE;
  begin
    select parameter_id into v_parameter_id 
    from apm_parameters 
    where parameter_name = get_value.parameter_name
    and package_key = (select package_key  from apm_packages
			where package_id = get_value.package_id);
    return apm.get_value(
	parameter_id => v_parameter_id,
	package_id => get_value.package_id
    );	
  end get_value;	


  -- Sets a value for a parameter for a package instance.
  procedure set_value (
    parameter_id		in apm_parameter_values.parameter_id%TYPE,
    package_id			in apm_packages.package_id%TYPE,	    
    attr_value			in apm_parameter_values.attr_value%TYPE
  ) 
  is
    v_value_id apm_parameter_values.value_id%TYPE;
  begin
    -- Determine if the value exists
    select value_id into v_value_id from apm_parameter_values 
     where parameter_id = set_value.parameter_id 
     and package_id = set_value.package_id;
    update apm_parameter_values set attr_value = set_value.attr_value
     where parameter_id = set_value.parameter_id 
     and package_id = set_value.package_id;    
     exception 
       when NO_DATA_FOUND
       then
         v_value_id := apm_parameter_value.new(
            package_id => set_value.package_id,
            parameter_id => set_value.parameter_id,
            attr_value => set_value.attr_value
         );
   end set_value;

  procedure set_value (
    package_id			in apm_packages.package_id%TYPE,
    parameter_name		in apm_parameters.parameter_name%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  ) 
  is
    v_parameter_id apm_parameter_values.parameter_id%TYPE;
  begin
    select parameter_id into v_parameter_id 
    from apm_parameters 
    where parameter_name = set_value.parameter_name
    and package_key = (select package_key  from apm_packages
			where package_id = set_value.package_id);
    apm.set_value(
	parameter_id => v_parameter_id,
	package_id => set_value.package_id,
	attr_value => set_value.attr_value
    );
    exception
      when NO_DATA_FOUND
      then
      	RAISE_APPLICATION_ERROR(-20000, 'The parameter named ' || set_value.parameter_name || ' that you attempted to set does not exist AND/OR the specified package ' || set_value.package_id || ' does not exist in the system.');	
  end set_value;	
end apm;
/
show errors  

create or replace package body apm_package
as
  procedure initialize_parameters (
    package_id			in apm_packages.package_id%TYPE,
    package_key		        in apm_package_types.package_key%TYPE
  )
  is
   v_value_id apm_parameter_values.value_id%TYPE;
   cursor cur is
       select parameter_id, default_value
       from apm_parameters
       where package_key = initialize_parameters.package_key;
  begin
    -- need to initialize all params for this type
    for cur_val in cur
      loop
        v_value_id := apm_parameter_value.new(
          package_id => initialize_parameters.package_id,
          parameter_id => cur_val.parameter_id,
          attr_value => cur_val.default_value
        ); 
      end loop;   
  end initialize_parameters;

 function new (
  package_id		in apm_packages.package_id%TYPE 
			default null,
  instance_name		in apm_packages.instance_name%TYPE
			default null,
  package_key		in apm_packages.package_key%TYPE,
  object_type		in acs_objects.object_type%TYPE
			default 'apm_package', 
  creation_date		in acs_objects.creation_date%TYPE 
			default sysdate,
  creation_user		in acs_objects.creation_user%TYPE 
			default null,
  creation_ip		in acs_objects.creation_ip%TYPE 
			default null,
  context_id		in acs_objects.context_id%TYPE 
			default null
  ) return apm_packages.package_id%TYPE
  is 
   v_singleton_p integer;
   v_package_type apm_package_types.package_type%TYPE;
   v_num_instances integer;
   v_package_id apm_packages.package_id%TYPE;
   v_instance_name apm_packages.instance_name%TYPE; 
  begin
   v_singleton_p := apm_package.singleton_p(
			package_key => apm_package.new.package_key
		    );
   v_num_instances := apm_package.num_instances(
			package_key => apm_package.new.package_key
		    );
  
   if v_singleton_p = 1 and v_num_instances >= 1 then
       select package_id into v_package_id 
       from apm_packages
       where package_key = apm_package.new.package_key;
       return v_package_id;
   else
       v_package_id := acs_object.new(
          object_id => package_id,
          object_type => object_type,
          creation_date => creation_date,
          creation_user => creation_user,
	  creation_ip => creation_ip,
	  context_id => context_id
	 );
       if instance_name is null then 
	 v_instance_name := package_key || ' ' || v_package_id;
       else
	 v_instance_name := instance_name;
       end if;

       select package_type into v_package_type
       from apm_package_types
       where package_key = apm_package.new.package_key;

       insert into apm_packages
       (package_id, package_key, instance_name)
       values
       (v_package_id, package_key, v_instance_name);

       if v_package_type = 'apm_application' then
	   insert into apm_applications
	   (application_id)
	   values
	   (v_package_id);
       else
	   insert into apm_services
	   (service_id)
	   values
	   (v_package_id);
       end if;

       initialize_parameters(
	   package_id => v_package_id,
	   package_key => apm_package.new.package_key
       );
       return v_package_id;

  end if;
end new;
  
  procedure del (
   package_id		in apm_packages.package_id%TYPE
  )
  is
    cursor all_values is
    	select value_id from apm_parameter_values
	where package_id = apm_package.del.package_id;
    cursor all_site_nodes is
    	select node_id from site_nodes
	where object_id = apm_package.del.package_id;
  begin
    -- Delete all parameters.
    for cur_val in all_values loop
    	apm_parameter_value.del(value_id => cur_val.value_id);
    end loop;    
    delete from apm_applications where application_id = apm_package.del.package_id;
    delete from apm_services where service_id = apm_package.del.package_id;
    delete from apm_packages where package_id = apm_package.del.package_id;
    -- Delete the site nodes for the objects.
    for cur_val in all_site_nodes loop
    	site_node.del(cur_val.node_id);
    end loop;
    -- Delete the object.
    acs_object.del (
	object_id => package_id
    );
   end del;

    function initial_install_p (
	package_key		in apm_packages.package_key%TYPE
    ) return integer
    is
        v_initial_install_p integer;
    begin
        select 1 into v_initial_install_p
	from apm_package_types
	where package_key = initial_install_p.package_key
        and initial_install_p = 't';
	return v_initial_install_p;
	
	exception 
	    when NO_DATA_FOUND
            then
                return 0;
    end initial_install_p;

    function singleton_p (
	package_key		in apm_packages.package_key%TYPE
    ) return integer
    is
        v_singleton_p integer;
    begin
        select 1 into v_singleton_p
	from apm_package_types
	where package_key = singleton_p.package_key
        and singleton_p = 't';
	return v_singleton_p;
	
	exception 
	    when NO_DATA_FOUND
            then
                return 0;
    end singleton_p;

    function num_instances (
	package_key		in apm_package_types.package_key%TYPE
    ) return integer
    is
        v_num_instances integer;
    begin
        select count(*) into v_num_instances
	from apm_packages
	where package_key = num_instances.package_key;
        return v_num_instances;
	
	exception
	    when NO_DATA_FOUND
	    then
	        return 0;
    end num_instances;

  function name (
    package_id		in apm_packages.package_id%TYPE
  ) return varchar2
  is
    v_result apm_packages.instance_name%TYPE;
  begin
    select instance_name into v_result
    from apm_packages
    where package_id = name.package_id;

    return v_result;
  end name;

   function highest_version (
     package_key		in apm_package_types.package_key%TYPE
   ) return apm_package_versions.version_id%TYPE
   is
     v_version_id apm_package_versions.version_id%TYPE;
   begin
     select version_id into v_version_id
	from apm_package_version_info i 
	where apm_package_version.sortable_version_name(version_name) = 
             (select max(apm_package_version.sortable_version_name(v.version_name))
	             from apm_package_version_info v where v.package_key = highest_version.package_key)
	and package_key = highest_version.package_key;
     return v_version_id;
     exception
         when NO_DATA_FOUND
         then
         return 0;
   end highest_version;

    function parent_id (
        package_id in apm_packages.package_id%TYPE
    ) return apm_packages.package_id%TYPE
    is
        v_package_id apm_packages.package_id%TYPE;
    begin
        select sn1.object_id
        into v_package_id
        from site_nodes sn1
        where sn1.node_id = (select sn2.parent_id
                             from site_nodes sn2
                             where sn2.object_id = apm_package.parent_id.package_id);

        return v_package_id;

        exception when NO_DATA_FOUND then
            return -1;
    end parent_id;

end apm_package;
/
show errors


create or replace package body apm_package_version 
as
    function new (
      version_id		in apm_package_versions.version_id%TYPE
				default null,
      package_key		in apm_package_versions.package_key%TYPE,
      version_name		in apm_package_versions.version_name%TYPE 
				default null,
      version_uri		in apm_package_versions.version_uri%TYPE,
      summary			in apm_package_versions.summary%TYPE,
      description_format	in apm_package_versions.description_format%TYPE,
      description		in apm_package_versions.description%TYPE,
      release_date		in apm_package_versions.release_date%TYPE,
      vendor			in apm_package_versions.vendor%TYPE,
      vendor_uri		in apm_package_versions.vendor_uri%TYPE,
      auto_mount                in apm_package_versions.auto_mount%TYPE,
      installed_p		in apm_package_versions.installed_p%TYPE
				default 'f',
      data_model_loaded_p	in apm_package_versions.data_model_loaded_p%TYPE
				default 'f'
    ) return apm_package_versions.version_id%TYPE
    is
      v_version_id apm_package_versions.version_id%TYPE;
    begin
      if version_id is null then
         select acs_object_id_seq.nextval
	 into v_version_id
	 from dual;
      else
         v_version_id := version_id;
      end if;
	v_version_id := acs_object.new(
		object_id => v_version_id,
		object_type => 'apm_package_version'
        );
      insert into apm_package_versions
      (version_id, package_key, version_name, version_uri, summary, description_format, description,
      release_date, vendor, vendor_uri, auto_mount, installed_p, data_model_loaded_p)
      values
      (v_version_id, package_key, version_name, version_uri,
       summary, description_format, description,
       release_date, vendor, vendor_uri, auto_mount,
       installed_p, data_model_loaded_p);
      return v_version_id;		
    end new;

    procedure del (
      version_id		in apm_packages.package_id%TYPE
    )
    is
    begin
      delete from apm_package_owners 
      where version_id = apm_package_version.del.version_id; 

      delete from apm_package_dependencies
      where version_id = apm_package_version.del.version_id;

      delete from apm_package_versions 
	where version_id = apm_package_version.del.version_id;

      acs_object.del(apm_package_version.del.version_id);

    end del;

    procedure enable (
       version_id			in apm_package_versions.version_id%TYPE
    )
    is
    begin
      update apm_package_versions set enabled_p = 't'
      where version_id = enable.version_id;	
    end enable;
    
    procedure disable (
       version_id			in apm_package_versions.version_id%TYPE
    )
    is
    begin
      update apm_package_versions 
      set enabled_p = 'f'
      where version_id = disable.version_id;	
    end disable;

  function copy(
	version_id in apm_package_versions.version_id%TYPE,
	new_version_id in apm_package_versions.version_id%TYPE default null,
	new_version_name in apm_package_versions.version_name%TYPE,
	new_version_uri in apm_package_versions.version_uri%TYPE
  ) return apm_package_versions.version_id%TYPE
    is
	v_version_id integer;
    begin
	v_version_id := acs_object.new(
		object_id => new_version_id,
		object_type => 'apm_package_version'
        );    

	insert into apm_package_versions(version_id, package_key, version_name,
					version_uri, summary, description_format, description,
					release_date, vendor, vendor_uri, auto_mount)
	    select v_version_id, package_key, copy.new_version_name,
		   copy.new_version_uri, summary, description_format, description,
		   release_date, vendor, vendor_uri, auto_mount
	    from apm_package_versions
	    where version_id = copy.version_id;
    
	insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_uri, service_version)
	    select acs_object_id_seq.nextval, v_version_id, dependency_type, service_uri, service_version
	    from apm_package_dependencies
	    where version_id = copy.version_id;
    
        insert into apm_package_callbacks (version_id, type, proc)
                select v_version_id, type, proc
                from apm_package_callbacks
                where version_id = copy.version_id;
    
	insert into apm_package_owners(version_id, owner_uri, owner_name, sort_key)
	    select v_version_id, owner_uri, owner_name, sort_key
	    from apm_package_owners
	    where version_id = copy.version_id;
    
	return v_version_id;
    end copy;
    
    function edit (
      new_version_id		in apm_package_versions.version_id%TYPE
				default null,
      version_id		in apm_package_versions.version_id%TYPE,
      version_name		in apm_package_versions.version_name%TYPE 
				default null,
      version_uri		in apm_package_versions.version_uri%TYPE,
      summary			in apm_package_versions.summary%TYPE,
      description_format	in apm_package_versions.description_format%TYPE,
      description		in apm_package_versions.description%TYPE,
      release_date		in apm_package_versions.release_date%TYPE,
      vendor			in apm_package_versions.vendor%TYPE,
      vendor_uri		in apm_package_versions.vendor_uri%TYPE,
      auto_mount                in apm_package_versions.auto_mount%TYPE,
      installed_p		in apm_package_versions.installed_p%TYPE
				default 'f',
      data_model_loaded_p	in apm_package_versions.data_model_loaded_p%TYPE
				default 'f'
    ) return apm_package_versions.version_id%TYPE
    is 
      v_version_id apm_package_versions.version_id%TYPE;
      version_unchanged_p integer;
    begin
       -- Determine if version has changed.
       select decode(count(*),0,0,1) into version_unchanged_p
       from apm_package_versions
       where version_id = edit.version_id
       and version_name = edit.version_name;
       if version_unchanged_p <> 1 then
         v_version_id := copy(
			 version_id => edit.version_id,
			 new_version_id => edit.new_version_id,
			 new_version_name => edit.version_name,
			 new_version_uri => edit.version_uri
			);
         else 
	   v_version_id := edit.version_id;			
       end if;
       
       update apm_package_versions 
		set version_uri = edit.version_uri,
		summary = edit.summary,
		description_format = edit.description_format,
		description = edit.description,
		release_date = trunc(sysdate),
		vendor = edit.vendor,
		vendor_uri = edit.vendor_uri,
                auto_mount = edit.auto_mount,
		installed_p = edit.installed_p,
		data_model_loaded_p = edit.data_model_loaded_p
	    where version_id = v_version_id;
	return v_version_id;
    end edit;

-- Add an interface provided by this version.
  function add_interface(
    interface_id		in apm_package_dependencies.dependency_id%TYPE
			        default null,
    version_id			in apm_package_versions.version_id%TYPE,
    interface_uri		in apm_package_dependencies.service_uri%TYPE,
    interface_version		in apm_package_dependencies.service_version%TYPE
  ) return apm_package_dependencies.dependency_id%TYPE
  is
    v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      if add_interface.interface_id is null then
          select acs_object_id_seq.nextval into v_dep_id from dual;
      else
          v_dep_id := add_interface.interface_id;
      end if;
  
      insert into apm_package_dependencies
      (dependency_id, version_id, dependency_type, service_uri, service_version)
      values
      (v_dep_id, add_interface.version_id, 'provides', add_interface.interface_uri,
	add_interface.interface_version);
      return v_dep_id;
  end add_interface;

  procedure remove_interface(
    interface_id		in apm_package_dependencies.dependency_id%TYPE
  )
  is
  begin
    delete from apm_package_dependencies 
    where dependency_id = remove_interface.interface_id;
  end remove_interface;

  procedure remove_interface(
    interface_uri		in apm_package_dependencies.service_uri%TYPE,
    interface_version		in apm_package_dependencies.service_version%TYPE,
    version_id			in apm_package_versions.version_id%TYPE
  )
  is
      v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      select dependency_id into v_dep_id from apm_package_dependencies
      where service_uri = remove_interface.interface_uri 
      and interface_version = remove_interface.interface_version;
      remove_interface(v_dep_id);
  end remove_interface;

  -- Add a requirement for this version.  A requirement is some interface that this
  -- version depends on.
  function add_dependency(
    dependency_id		in apm_package_dependencies.dependency_id%TYPE
			        default null,
    version_id			in apm_package_versions.version_id%TYPE,
    dependency_uri		in apm_package_dependencies.service_uri%TYPE,
    dependency_version		in apm_package_dependencies.service_version%TYPE
  ) return apm_package_dependencies.dependency_id%TYPE
  is
    v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      if add_dependency.dependency_id is null then
          select acs_object_id_seq.nextval into v_dep_id from dual;
      else
          v_dep_id := add_dependency.dependency_id;
      end if;
  
      insert into apm_package_dependencies
      (dependency_id, version_id, dependency_type, service_uri, service_version)
      values
      (v_dep_id, add_dependency.version_id, 'requires', add_dependency.dependency_uri,
	add_dependency.dependency_version);
      return v_dep_id;
  end add_dependency;

  procedure remove_dependency(
    dependency_id		in apm_package_dependencies.dependency_id%TYPE
  )
  is
  begin
    delete from apm_package_dependencies 
    where dependency_id = remove_dependency.dependency_id;
  end remove_dependency;


  procedure remove_dependency(
    dependency_uri		in apm_package_dependencies.service_uri%TYPE,
    dependency_version		in apm_package_dependencies.service_version%TYPE,
    version_id			in apm_package_versions.version_id%TYPE
  )
  is
    v_dep_id apm_package_dependencies.dependency_id%TYPE;
  begin
      select dependency_id into v_dep_id from apm_package_dependencies 
      where service_uri = remove_dependency.dependency_uri 
      and service_version = remove_dependency.dependency_version;
      remove_dependency(v_dep_id);
  end remove_dependency;

   function sortable_version_name (
    version_name		in apm_package_versions.version_name%TYPE
  ) return varchar2
    is
        a_fields integer;
	a_start integer;
	a_end   integer;
	a_order varchar2(1000);
	a_char  char(1);
	a_seen_letter char(1) := 'f';
    begin
        a_fields := 0;
	a_start := 1;
	loop
	    a_end := a_start;
    
	    -- keep incrementing a_end until we run into a non-number        
	    while substr(version_name, a_end, 1) >= '0' and substr(version_name, a_end, 1) <= '9' loop
		a_end := a_end + 1;
	    end loop;
	    if a_end = a_start then
	    	return -1;
		-- raise_application_error(-20000, 'Expected number at position ' || a_start);
	    end if;
	    if a_end - a_start > 4 then
	    	return -1;
		-- raise_application_error(-20000, 'Numbers within versions can only be up to 4 digits long');
	    end if;
    
	    -- zero-pad and append the number
	    a_order := a_order || substr('0000', 1, 4 - (a_end - a_start)) ||
		substr(version_name, a_start, a_end - a_start) || '.';
            a_fields := a_fields + 1;
	    if a_end > length(version_name) then
		-- end of string - we're outta here
		if a_seen_letter = 'f' then
		    -- append the "final" suffix if there haven't been any letters
		    -- so far (i.e., not development/alpha/beta)
		    a_order := a_order || lpad(' ',(7 - a_fields)*5,'0000.') || '  3F.';
		end if;
		return a_order;
	    end if;
    
	    -- what's the next character? if a period, just skip it
	    a_char := substr(version_name, a_end, 1);
	    if a_char = '.' then
		null;
	    else
		-- if the next character was a letter, append the appropriate characters
		if a_char = 'd' then
		    a_order := a_order || lpad(' ',(7 - a_fields)*5,'0000.') || '  0D.';
		elsif a_char = 'a' then
		    a_order := a_order || lpad(' ',(7 - a_fields)*5,'0000.') || '  1A.';
		elsif a_char = 'b' then
		    a_order := a_order || lpad(' ',(7 - a_fields)*5,'0000.') || '  2B.';
		end if;
    
		-- can't have something like 3.3a1b2 - just one letter allowed!
		if a_seen_letter = 't' then
		    return -1;
		    -- raise_application_error(-20000, 'Not allowed to have two letters in version name '''
		    --	|| version_name || '''');
		end if;
		a_seen_letter := 't';
    
		-- end of string - we're done!
		if a_end = length(version_name) then
		    return a_order;
		end if;
	    end if;
	    a_start := a_end + 1;
	end loop;
    end sortable_version_name;

  function version_name_greater(
    version_name_one		in apm_package_versions.version_name%TYPE,
    version_name_two		in apm_package_versions.version_name%TYPE
  ) return integer is
	a_order_a varchar2(1000);
	a_order_b varchar2(1000);
    begin
	a_order_a := sortable_version_name(version_name_one);
	a_order_b := sortable_version_name(version_name_two);
	if a_order_a < a_order_b then
	    return -1;
	elsif a_order_a > a_order_b then
	    return 1;
	end if;
	return 0;
    end version_name_greater;

  function upgrade_p(
    path			in varchar2,
    initial_version_name	in apm_package_versions.version_name%TYPE,
    final_version_name		in apm_package_versions.version_name%TYPE
   ) return integer
    is
	v_pos1 integer;
	v_pos2 integer;
	v_path varchar2(1500);
	v_version_from apm_package_versions.version_name%TYPE;
	v_version_to apm_package_versions.version_name%TYPE;
    begin

	-- Set v_path to the tail of the path (the file name).
	v_path := substr(upgrade_p.path, instr(upgrade_p.path, '/', -1) + 1);

	-- Remove the extension, if it's .sql.
	v_pos1 := instr(v_path, '.', -1);
	if v_pos1 > 0 and substr(v_path, v_pos1) = '.sql' then
	    v_path := substr(v_path, 1, v_pos1 - 1);
	end if;

	-- Figure out the from/to version numbers for the individual file.
	v_pos1 := instr(v_path, '-', -1, 2);
	v_pos2 := instr(v_path, '-', -1);
	if v_pos1 = 0 or v_pos2 = 0 then
	    -- There aren't two hyphens in the file name. Bail.
	    return 0;
	end if;

	v_version_from := substr(v_path, v_pos1 + 1, v_pos2 - v_pos1 - 1);
	v_version_to := substr(v_path, v_pos2 + 1);

	if version_name_greater(upgrade_p.initial_version_name, v_version_from) <= 0 and
	   version_name_greater(upgrade_p.final_version_name, v_version_to) >= 0 then
	    return 1;
	end if;

	return 0;
    exception when others then
	-- Invalid version number.
	return 0;
    end upgrade_p;
    
  procedure upgrade(
    version_id                  in apm_package_versions.version_id%TYPE
  )
  is
  begin
    update apm_package_versions
    	set enabled_p = 'f',
	    installed_p = 'f'
	where package_key = (select package_key from apm_package_versions
	    	    	     where version_id = upgrade.version_id);
    update apm_package_versions
    	set enabled_p = 't',
	    installed_p = 't'
	where version_id = upgrade.version_id;			  
    
  end upgrade;

end apm_package_version;
/
show errors

create or replace package body apm_package_type
as
 procedure create_type(
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in acs_object_types.pretty_name%TYPE,
    pretty_plural		in acs_object_types.pretty_plural%TYPE,
    package_uri			in apm_package_types.package_uri%TYPE,
    package_type		in apm_package_types.package_type%TYPE,
    initial_install_p		in apm_package_types.initial_install_p%TYPE,
    singleton_p			in apm_package_types.singleton_p%TYPE,
    spec_file_path		in apm_package_types.spec_file_path%TYPE default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE default null
  ) 
  is
  begin
   insert into apm_package_types
    (package_key, pretty_name, pretty_plural, package_uri, package_type,
    spec_file_path, spec_file_mtime, initial_install_p, singleton_p)
   values
    (create_type.package_key, create_type.pretty_name, create_type.pretty_plural,
     create_type.package_uri, create_type.package_type, create_type.spec_file_path, 
     create_type.spec_file_mtime, create_type.initial_install_p, create_type.singleton_p);
  end create_type;

  function update_type(    
    package_key			in apm_package_types.package_key%TYPE,
    pretty_name			in acs_object_types.pretty_name%TYPE
    	    	    	    	default null,
    pretty_plural		in acs_object_types.pretty_plural%TYPE
    	    	    	    	default null,
    package_uri			in apm_package_types.package_uri%TYPE
    	    	    	    	default null,
    package_type		in apm_package_types.package_type%TYPE
    	    	    	        default null,
    initial_install_p		in apm_package_types.initial_install_p%TYPE
    	    	    	    	default null,
    singleton_p			in apm_package_types.singleton_p%TYPE
    	    	    	    	default null,
    spec_file_path		in apm_package_types.spec_file_path%TYPE 
    	    	    	    	default null,
    spec_file_mtime		in apm_package_types.spec_file_mtime%TYPE
    	    	    	    	 default null
  ) return apm_package_types.package_type%TYPE
  is
  begin       
      UPDATE apm_package_types SET
      	pretty_name = nvl(update_type.pretty_name, pretty_name),
    	pretty_plural = nvl(update_type.pretty_plural, pretty_plural),
    	package_uri = nvl(update_type.package_uri, package_uri),
    	package_type = nvl(update_type.package_type, package_type),
    	spec_file_path = nvl(update_type.spec_file_path, spec_file_path),
    	spec_file_mtime = nvl(update_type.spec_file_mtime, spec_file_mtime),
    	initial_install_p = nvl(update_type.initial_install_p, initial_install_p),
    	singleton_p = nvl(update_type.singleton_p, singleton_p)
      where package_key = update_type.package_key;
      return update_type.package_key;
  end update_type;
  
  procedure drop_type (
    package_key		in apm_package_types.package_key%TYPE,
    cascade_p		in char default 'f'
  )
  is
      cursor all_package_ids is
       select package_id
       from apm_packages
       where package_key = drop_type.package_key;
       
      cursor all_parameters is
       select parameter_id from apm_parameters
       where package_key = drop_type.package_key; 

      cursor all_versions is
       select version_id from apm_package_versions
       where package_key = drop_type.package_key;
  begin
    if cascade_p = 't' then
        for cur_val in all_package_ids
        loop
            apm_package.del(
	        package_id => cur_val.package_id
	    );
        end loop;
	-- Unregister all parameters.
        for cur_val in all_parameters 
	loop
	    apm.unregister_parameter(parameter_id => cur_val.parameter_id);
	end loop;
  
        -- Unregister all versions
	for cur_val in all_versions
	loop
	    apm_package_version.del(version_id => cur_val.version_id);
        end loop;
    end if;
    delete from apm_package_types
    where package_key = drop_type.package_key;
  end drop_type;

  function num_parameters (
    package_key         in apm_package_types.package_key%TYPE
  ) return integer
  is 
    v_count integer;
  begin
    select count(*) into v_count
    from apm_parameters
    where package_key = num_parameters.package_key;
    return v_count;
  end num_parameters;

end apm_package_type;


/
show errors

create or replace package body apm_parameter_value
as
   function new (
    value_id			in apm_parameter_values.value_id%TYPE default null,
    package_id			in apm_packages.package_id%TYPE,
    parameter_id		in apm_parameter_values.parameter_id%TYPE,
    attr_value			in apm_parameter_values.attr_value%TYPE
  ) return apm_parameter_values.value_id%TYPE
  is 
  v_value_id apm_parameter_values.value_id%TYPE;
  begin
   v_value_id := acs_object.new(
     object_id => value_id,
     object_type => 'apm_parameter_value'
   );
   insert into apm_parameter_values 
    (value_id, package_id, parameter_id, attr_value)
     values
    (v_value_id, apm_parameter_value.new.package_id, 
    apm_parameter_value.new.parameter_id, 
    apm_parameter_value.new.attr_value);
   return v_value_id;
  end new;

  procedure del (
    value_id			in apm_parameter_values.value_id%TYPE default null
  )
  is
  begin
    delete from apm_parameter_values 
    where value_id = apm_parameter_value.del.value_id;
    acs_object.del(value_id);
  end del;

 end apm_parameter_value;
/
show errors;

create or replace package body apm_application
as

  function new (
    application_id	in acs_objects.object_id%TYPE default null,
    instance_name	in apm_packages.instance_name%TYPE
			default null,
    package_key		in apm_package_types.package_key%TYPE,
    object_type		in acs_objects.object_type%TYPE
			   default 'apm_application',
    creation_date	in acs_objects.creation_date%TYPE default sysdate,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null
  ) return acs_objects.object_id%TYPE
  is
    v_application_id	integer;
  begin
    v_application_id := apm_package.new (
      package_id => application_id,
      instance_name => instance_name,
      package_key => package_key,
      object_type => object_type,
      creation_date => creation_date,
      creation_user => creation_user,
      creation_ip => creation_ip,
      context_id => context_id
    );
    return v_application_id;
  end new;

  procedure del (
    application_id		in acs_objects.object_id%TYPE
  )
  is
  begin
    delete from apm_applications
    where application_id = apm_application.del.application_id;
    apm_package.del(
        package_id => application_id);
  end del;

end;
/
show errors

create or replace package body apm_service
as

  function new (
    service_id		in acs_objects.object_id%TYPE default null,
    instance_name	in apm_packages.instance_name%TYPE
			default null,
    package_key		in apm_package_types.package_key%TYPE,
    object_type		in acs_objects.object_type%TYPE default 'apm_service',
    creation_date	in acs_objects.creation_date%TYPE default sysdate,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null
  ) return acs_objects.object_id%TYPE
  is
    v_service_id	integer;
  begin
    v_service_id := apm_package.new (
      package_id => service_id,
      instance_name => instance_name,
      package_key => package_key,
      object_type => object_type,
      creation_date => creation_date,
      creation_user => creation_user,
      creation_ip => creation_ip,
      context_id => context_id
    );
    return v_service_id;
  end new;

  procedure del (
    service_id		in acs_objects.object_id%TYPE
  )
  is
  begin
    delete from apm_services
    where service_id = apm_service.del.service_id;
    apm_package.del(
	package_id => service_id
    );
  end del;

end;
/
show errors

--
-- acs-kernel/sql/community-core-create.sql
--
-- Abstractions fundamental to any online community (or information
-- system, in general), derived in large part from the ACS 3.x
-- community-core data model by Philip Greenspun (philg@mit.edu), from
-- the ACS 3.x user-groups data model by Tracy Adams (teadams@mit.edu)
-- from Chapter 3 (The Enterprise and Its World) of David Hay's
-- book _Data_Model_Patterns_, and from Chapter 2 (Accountability)
-- of Martin Fowler's book _Analysis_Patterns_.
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @author Rafael Schloming (rhs@mit.edu)
-- @author Jon Salz (jsalz@mit.edu)
--
-- @creation-date 2000-05-18
--
-- @cvs-id $Id$
--

-------------------
-- PARTY PACKAGE --
-------------------

create or replace package party
as

 function new (
  party_id	in parties.party_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'party',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null
 ) return parties.party_id%TYPE;

 procedure del (
  party_id	in parties.party_id%TYPE
 );

 function name (
  party_id	in parties.party_id%TYPE
 ) return varchar2;

 function email (
  party_id	in parties.party_id%TYPE
 ) return varchar2;

end party;
/
show errors


create or replace package body party
as

 function new (
  party_id	in parties.party_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'party',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return parties.party_id%TYPE
 is
  v_party_id parties.party_id%TYPE;
 begin
  v_party_id :=
   acs_object.new(party_id, object_type,
                  creation_date, creation_user, creation_ip, context_id);

  insert into parties
   (party_id, email, url)
  values
   (v_party_id, lower(email), url);

  return v_party_id;
 end new;

 procedure del (
  party_id	in parties.party_id%TYPE
 )
 is
 begin
  acs_object.del(party_id);
 end del;

 function name (
  party_id	in parties.party_id%TYPE
 )
 return varchar2
 is
 begin
  if party_id = -1 then
   return 'The Public';
  else
   return null;
  end if;
 end name;

 function email (
  party_id	in parties.party_id%TYPE
 )
 return varchar2
 is
  v_email parties.email%TYPE;
 begin
  select email
  into v_email
  from parties
  where party_id = email.party_id;

  return v_email;

 end email;

end party;
/
show errors


--------------------
-- PERSON PACKAGE --
--------------------

create or replace package person
as

 function new (
  person_id	in persons.person_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'person',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  first_names	in persons.first_names%TYPE,
  last_name	in persons.last_name%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 ) return persons.person_id%TYPE;

 procedure del (
  person_id	in persons.person_id%TYPE
 );

 function name (
  person_id	in persons.person_id%TYPE
 ) return varchar2;

 function first_names (
  person_id	in persons.person_id%TYPE
 ) return varchar2;

 function last_name (
  person_id	in persons.person_id%TYPE
 ) return varchar2;

end person;
/
show errors

create or replace package body person
as

 function new (
  person_id	in persons.person_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'person',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  first_names	in persons.first_names%TYPE,
  last_name	in persons.last_name%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return persons.person_id%TYPE
 is
  v_person_id persons.person_id%TYPE;
 begin
  v_person_id :=
   party.new(person_id, object_type,
             creation_date, creation_user, creation_ip,
             email, url, context_id);

  insert into persons
   (person_id, first_names, last_name)
  values
   (v_person_id, first_names, last_name);

  return v_person_id;
 end new;

 procedure del (
  person_id	in persons.person_id%TYPE
 )
 is
 begin
  delete from persons
  where person_id = person.del.person_id;

  party.del(person_id);
 end del;

 function name (
  person_id	in persons.person_id%TYPE
 )
 return varchar2
 is
  person_name varchar2(200);
 begin
  select first_names || ' ' || last_name
  into person_name
  from persons
  where person_id = name.person_id;

  return person_name;
 end name;

 function first_names (
  person_id	in persons.person_id%TYPE
 )
 return varchar2
 is
  person_first_names varchar2(200);
 begin
  select first_names
  into person_first_names
  from persons
  where person_id = first_names.person_id;

  return person_first_names;
 end first_names;

function last_name (
  person_id	in persons.person_id%TYPE
 )
 return varchar2
 is
  person_last_name varchar2(200);
 begin
  select last_name
  into person_last_name
  from persons
  where person_id = last_name.person_id;

  return person_last_name;
 end last_name;

end person;
/
show errors


----------------------
-- ACS_USER PACKAGE --
----------------------

create or replace package acs_user
as

 function new (
  user_id	in users.user_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'user',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  authority_id  in auth_authorities.authority_id%TYPE default null,
  username      in users.username%TYPE,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  first_names	in persons.first_names%TYPE,
  last_name	in persons.last_name%TYPE,
  password	in users.password%TYPE,
  salt		in users.salt%TYPE,
  screen_name	in users.screen_name%TYPE default null,
  email_verified_p in users.email_verified_p%TYPE default 't',
  context_id	in acs_objects.context_id%TYPE default null
 )
 return users.user_id%TYPE;

 function receives_alerts_p (
  user_id	in users.user_id%TYPE
 )
 return char;

 procedure approve_email (
  user_id	in users.user_id%TYPE
 );

 procedure unapprove_email (
  user_id	in users.user_id%TYPE
 );

 procedure del (
  user_id	in users.user_id%TYPE
 );

end acs_user;
/
show errors

create or replace package body acs_user
as

 function new (
  user_id	in users.user_id%TYPE default null,
  object_type	in acs_objects.object_type%TYPE
		   default 'user',
  creation_date	in acs_objects.creation_date%TYPE
		   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
		   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  authority_id  in auth_authorities.authority_id%TYPE default null,
  username      in users.username%TYPE,
  email		in parties.email%TYPE,
  url		in parties.url%TYPE default null,
  first_names	in persons.first_names%TYPE,
  last_name	in persons.last_name%TYPE,
  password	in users.password%TYPE,
  salt		in users.salt%TYPE,
  screen_name	in users.screen_name%TYPE default null,
  email_verified_p in users.email_verified_p%TYPE default 't',
  context_id	in acs_objects.context_id%TYPE default null
 )
 return users.user_id%TYPE
 is
  v_authority_id auth_authorities.authority_id%TYPE;
  v_user_id users.user_id%TYPE;
 begin
  v_user_id :=
   person.new(user_id, object_type,
              creation_date, creation_user, creation_ip,
              email, url,
              first_names, last_name, context_id);

  -- default to local authority
  if authority_id is null then
    select authority_id
    into   v_authority_id
    from   auth_authorities
    where  short_name = 'local';
  else
        v_authority_id := authority_id;
  end if;

  insert into users
   (user_id, authority_id, username, password, salt, screen_name, email_verified_p)
  values
   (v_user_id, v_authority_id, username, password, salt, screen_name, email_verified_p);

  insert into user_preferences
    (user_id)
    values
    (v_user_id);

  return v_user_id;
 end new;

 function receives_alerts_p (
  user_id in users.user_id%TYPE
 )
 return char
 is
  counter	char(1);
 begin
  select decode(count(*),0,'f','t') into counter
   from users
   where no_alerts_until >= sysdate
   and user_id = acs_user.receives_alerts_p.user_id;

  return counter;

 end receives_alerts_p;

 procedure approve_email (
  user_id	in users.user_id%TYPE
 )
 is
 begin
    update users
    set email_verified_p = 't'
    where user_id = approve_email.user_id;
 end approve_email;


 procedure unapprove_email (
  user_id	in users.user_id%TYPE
 )
 is
 begin
    update users
    set email_verified_p = 'f'
    where user_id = unapprove_email.user_id;
 end unapprove_email;

 procedure del (
  user_id	in users.user_id%TYPE
 )
 is
 begin
  delete from user_preferences
  where user_id = acs_user.del.user_id;

  delete from users
  where user_id = acs_user.del.user_id;

  person.del(user_id);
 end del;

end acs_user;
/
show errors




create or replace package composition_rel
as

  function new (
    rel_id              in composition_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'composition_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return composition_rels.rel_id%TYPE;

  procedure del (
    rel_id      in composition_rels.rel_id%TYPE
  );

  function check_path_exists_p (
    component_id        in groups.group_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char;

  function check_representation (
    rel_id      in composition_rels.rel_id%TYPE
  ) return char;

end composition_rel;
/
show errors



create or replace package body composition_rel
as

  function new (
    rel_id              in composition_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'composition_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return composition_rels.rel_id%TYPE
  is
    v_rel_id integer;
  begin
    v_rel_id := acs_rel.new (
      rel_id => rel_id,
      rel_type => rel_type,
      object_id_one => object_id_one,
      object_id_two => object_id_two,
      context_id => object_id_one,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into composition_rels
     (rel_id)
    values
     (v_rel_id);

    return v_rel_id;
  end;

  procedure del (
    rel_id      in composition_rels.rel_id%TYPE
  )
  is
  begin
    acs_rel.del(rel_id);
  end;

  function check_path_exists_p (
    component_id        in groups.group_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
  begin
    if component_id = container_id then
      return 't';
    end if;

    for row in (select r.object_id_one as parent_id
                from acs_rels r, composition_rels c
                where r.rel_id = c.rel_id
                and r.object_id_two = component_id) loop
      if check_path_exists_p(row.parent_id, container_id) = 't' then
        return 't';
      end if;
    end loop;

    return 'f';
  end;

  function check_index (
    component_id        in groups.group_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
    result char(1);
    n_rows integer;
  begin
    result := 't';

    -- Loop through all the direct containers (DC) of COMPONENT_ID
    -- that are also contained by CONTAINER_ID and verify that the
    -- GROUP_COMPONENT_INDEX contains the (GROUP_ID, DC.REL_ID,
    -- CONTAINER_ID) triple.
    for dc in (select r.rel_id, r.object_id_one as container_id
               from acs_rels r, composition_rels c
               where r.rel_id = c.rel_id
               and r.object_id_two = component_id) loop

      if check_path_exists_p(dc.container_id,
                             check_index.container_id) = 't' then
        select decode(count(*),0,0,1) into n_rows
        from group_component_index
        where group_id = check_index.container_id
        and component_id = check_index.component_id
        and rel_id = dc.rel_id;

        if n_rows = 0 then
          result := 'f';
          acs_log.error('composition_rel.check_representation',
                        'Row missing from group_component_index for (' ||
                        'group_id = ' || container_id || ', ' ||
                        'component_id = ' || component_id || ', ' ||
                        'rel_id = ' || dc.rel_id || ')');
        end if;

      end if;

    end loop;

    -- Loop through all the containers of CONTAINER_ID.
    for r1 in (select r.object_id_one as container_id
               from acs_rels r, composition_rels c
               where r.rel_id = c.rel_id
               and r.object_id_two = check_index.container_id
               union
               select check_index.container_id
               from dual) loop
      -- Loop through all the components of COMPONENT_ID and make a
      -- recursive call.
      for r2 in (select r.object_id_two as component_id
                 from acs_rels r, composition_rels c
                 where r.rel_id = c.rel_id
                 and r.object_id_one = check_index.component_id
                 union
                 select check_index.component_id
                 from dual) loop
        if (r1.container_id != check_index.container_id or
            r2.component_id != check_index.component_id) and
           check_index(r2.component_id, r1.container_id) = 'f' then
          result := 'f';
        end if;
      end loop;
    end loop;

    return result;
  end;

  function check_representation (
    rel_id      in composition_rels.rel_id%TYPE
  ) return char
  is
    container_id groups.group_id%TYPE;
    component_id groups.group_id%TYPE;
    result char(1);
  begin
    result := 't';

    if acs_object.check_representation(rel_id) = 'f' then
      result := 'f';
    end if;

    select object_id_one, object_id_two
    into container_id, component_id
    from acs_rels
    where rel_id = check_representation.rel_id;

    -- First let's check that the index has all the rows it should.
    if check_index(component_id, container_id) = 'f' then
      result := 'f';
    end if;

    -- Now let's check that the index doesn't have any extraneous rows
    -- relating to this relation.
    for row in (select *
                from group_component_index
                where rel_id = check_representation.rel_id) loop
      if check_path_exists_p(row.component_id, row.group_id) = 'f' then
        result := 'f';
        acs_log.error('composition_rel.check_representation',
                      'Extraneous row in group_component_index: ' ||
                      'group_id = ' || row.group_id || ', ' ||
                      'component_id = ' || row.component_id || ', ' ||
                      'rel_id = ' || row.rel_id || ', ' ||
                      'container_id = ' || row.container_id || '.');
      end if;
    end loop;

    return result;
  end;

end composition_rel;
/
show errors



create or replace package membership_rel
as

  function new (
    rel_id              in membership_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'membership_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default 'approved',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return membership_rels.rel_id%TYPE;

  procedure ban (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure approve (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure reject (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure unapprove (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure deleted (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure del (
    rel_id      in membership_rels.rel_id%TYPE
  );

  function check_representation (
    rel_id      in membership_rels.rel_id%TYPE
  ) return char;

end membership_rel;
/
show errors



create or replace package body membership_rel
as

  function new (
    rel_id              in membership_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'membership_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default 'approved',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return membership_rels.rel_id%TYPE
  is
    v_rel_id integer;
  begin
    v_rel_id := acs_rel.new (
      rel_id => rel_id,
      rel_type => rel_type,
      object_id_one => object_id_one,
      object_id_two => object_id_two,
      context_id => object_id_one,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into membership_rels
     (rel_id, member_state)
    values
     (v_rel_id, new.member_state);

    return v_rel_id;
  end;

  procedure ban (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'banned'
    where rel_id = ban.rel_id;
  end;

  procedure approve (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'approved'
    where rel_id = approve.rel_id;
  end;

  procedure reject (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'rejected'
    where rel_id = reject.rel_id;
  end;

  procedure unapprove (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'needs approval'
    where rel_id = unapprove.rel_id;
  end;

  procedure deleted (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'deleted'
    where rel_id = deleted.rel_id;
  end;

  procedure del (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    acs_rel.del(rel_id);
  end;

  function check_index (
    group_id            in groups.group_id%TYPE,
    member_id           in parties.party_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
    result char(1);
    n_rows integer;
  begin

    select count(*) into n_rows
    from group_member_index
    where group_id = check_index.group_id
    and member_id = check_index.member_id
    and container_id = check_index.container_id;

    if n_rows = 0 then
      result := 'f';
      acs_log.error('membership_rel.check_representation',
                    'Row missing from group_member_index: ' ||
                    'group_id = ' || group_id || ', ' ||
                    'member_id = ' || member_id || ', ' ||
                    'container_id = ' || container_id || '.');
    end if;

    for row in (select r.object_id_one as container_id
                from acs_rels r, composition_rels c
                where r.rel_id = c.rel_id
                and r.object_id_two = group_id) loop
      if check_index(row.container_id, member_id, container_id) = 'f' then
        result := 'f';
      end if;
    end loop;

    return result;
  end;

  function check_representation (
    rel_id      in membership_rels.rel_id%TYPE
  ) return char
  is
    group_id  groups.group_id%TYPE;
    member_id parties.party_id%TYPE;
    result    char(1);
  begin
    result := 't';

    if acs_object.check_representation(rel_id) = 'f' then
      result := 'f';
    end if;

    select r.object_id_one, r.object_id_two
    into group_id, member_id
    from acs_rels r, membership_rels m
    where r.rel_id = m.rel_id
    and m.rel_id = check_representation.rel_id;

    if check_index(group_id, member_id, group_id) = 'f' then
      result := 'f';
    end if;

    for row in (select *
                from group_member_index
                where rel_id = check_representation.rel_id) loop
      if composition_rel.check_path_exists_p(row.container_id,
                                             row.group_id) = 'f' then
        result := 'f';
        acs_log.error('membership_rel.check_representation',
                      'Extra row in group_member_index: ' ||
                      'group_id = ' || row.group_id || ', ' ||
                      'member_id = ' || row.member_id || ', ' ||
                      'container_id = ' || row.container_id || '.');
      end if;
    end loop;

    return result;
  end;

end membership_rel;
/
show errors



create or replace package admin_rel
as

  function new (
    rel_id              in admin_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'admin_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default 'approved',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return admin_rels.rel_id%TYPE;

  procedure del (
    rel_id      in admin_rels.rel_id%TYPE
  );

end admin_rel;
/
show errors


create or replace package body admin_rel
as

  function new (
    rel_id              in admin_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'admin_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default 'approved',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return admin_rels.rel_id%TYPE
  is
    v_rel_id integer;
  begin
    v_rel_id := membership_rel.new (
      rel_id => rel_id,
      rel_type => rel_type,
      object_id_one => object_id_one,
      object_id_two => object_id_two,
      member_state => member_state,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into admin_rels
     (rel_id)
    values
     (v_rel_id);

    return v_rel_id;
  end;

  procedure del (
    rel_id      in admin_rels.rel_id%TYPE
  )
  is
  begin
    membership_rel.del(rel_id);
  end;

end admin_rel;
/
show errors



create or replace package acs_group
is
 function new (
  group_id              in groups.group_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'group',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  group_name            in groups.group_name%TYPE,
  join_policy           in groups.join_policy%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null
 ) return groups.group_id%TYPE;

 procedure del (
   group_id     in groups.group_id%TYPE
 );

 function name (
  group_id      in groups.group_id%TYPE
 ) return varchar2;

 function member_p (
  party_id      in parties.party_id%TYPE,
  group_id	in groups.group_id%TYPE,
  cascade_membership char	
 ) return char;

 function check_representation (
  group_id      in groups.group_id%TYPE
 ) return char;

end acs_group;
/
show errors

create or replace package body acs_group
is
 function new (
  group_id              in groups.group_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'group',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  group_name            in groups.group_name%TYPE,
  join_policy           in groups.join_policy%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return groups.group_id%TYPE
 is
  v_group_id groups.group_id%TYPE;
  v_group_type_exists_p integer;
  v_join_policy groups.join_policy%TYPE;
 begin
  v_group_id :=
   party.new(group_id, object_type, creation_date, creation_user,
             creation_ip, email, url, context_id);

  v_join_policy := join_policy;

  -- if join policy wasn't specified, select the default based on group type
  if v_join_policy is null then
      select count(*) into v_group_type_exists_p
      from group_types
      where group_type = object_type;

      if v_group_type_exists_p = 1 then
          select default_join_policy into v_join_policy
          from group_types
          where group_type = object_type;
      else
          v_join_policy := 'open';
      end if;
  end if;

  insert into groups
   (group_id, group_name, join_policy)
  values
   (v_group_id, group_name, v_join_policy);


  -- setup the permissible relationship types for this group
  insert into group_rels
  (group_rel_id, group_id, rel_type)
  select acs_object_id_seq.nextval, v_group_id, g.rel_type
    from group_type_rels g
   where g.group_type = new.object_type;

  return v_group_id;
 end new;


 procedure del (
    group_id     in groups.group_id%TYPE
  )
  is
  begin
 
   -- Delete all segments defined for this group
   for row in (select segment_id 
                 from rel_segments 
                where group_id = acs_group.del.group_id) loop

       rel_segment.del(row.segment_id);

   end loop;

   -- Delete all the relations of any type to this group
   for row in (select r.rel_id, t.package_name
                 from acs_rels r, acs_object_types t
                where r.rel_type = t.object_type
                  and (r.object_id_one = acs_group.del.group_id
                       or r.object_id_two = acs_group.del.group_id)) loop
      execute immediate 'begin ' ||  row.package_name || '.del(' || row.rel_id || '); end;';
   end loop;
 
   party.del(group_id);
 end del;

 function name (
  group_id      in groups.group_id%TYPE
 )
 return varchar2
 is
  group_name varchar2(200);
 begin
  select group_name
  into group_name
  from groups
  where group_id = name.group_id;

  return group_name;
 end name;

 function member_p (
  party_id      in parties.party_id%TYPE,
  group_id	in groups.group_id%TYPE,
  cascade_membership char
 )
 return char
 is
 m_result integer;
 begin

  if cascade_membership = 't' then
    select count(*)
      into m_result
      from group_member_map
      where group_id = member_p.group_id and
            member_id = member_p.party_id;

    if m_result > 0 then
      return 't';
    end if;
  else
    select count(*)
      into m_result
      from acs_rels rels, all_object_party_privilege_map perm
    where perm.object_id = rels.rel_id
           and perm.privilege = 'read'
           and rels.rel_type = 'membership_rel'
	   and rels.object_id_one = member_p.group_id
           and rels.object_id_two = member_p.party_id;

    if m_result > 0 then
      return 't';
    end if;
  end if;

  return 'f';
 end member_p;

 function check_representation (
  group_id      in groups.group_id%TYPE
 ) return char
 is
   result char(1);
 begin
   result := 't';
   acs_log.notice('acs_group.check_representation',
                  'Running check_representation on group ' || group_id);

   if acs_object.check_representation(group_id) = 'f' then
     result := 'f';
   end if;

   for c in (select c.rel_id
             from acs_rels r, composition_rels c
             where r.rel_id = c.rel_id
             and r.object_id_one = group_id) loop
     if composition_rel.check_representation(c.rel_id) = 'f' then
       result := 'f';
     end if;
   end loop;

   for m in (select m.rel_id
             from acs_rels r, membership_rels m
             where r.rel_id = m.rel_id
             and r.object_id_one = group_id) loop
     if membership_rel.check_representation(m.rel_id) = 'f' then
       result := 'f';
     end if;
   end loop;

   acs_log.notice('acs_group.check_representation',
                  'Done running check_representation on group ' || group_id);
   return result;
 end;

end acs_group;
/
show errors





-- Data model to keep a journal of all actions on objects.
-- 
--
-- @author Lars Pind (lars@pinds.com)
-- @creation-date 2000-22-18
-- @cvs-id $Id$
--
-- Copyright (C) 1999-2000 ArsDigita Corporation
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html



create or replace package journal_entry
as

    function new (
        journal_id	in journal_entries.journal_id%TYPE default null,
        object_id	in journal_entries.object_id%TYPE,
        action		in journal_entries.action%TYPE,
	action_pretty   in journal_entries.action_pretty%TYPE default null,
        creation_date	in acs_objects.creation_date%TYPE default sysdate,
        creation_user	in acs_objects.creation_user%TYPE default null,
        creation_ip	in acs_objects.creation_ip%TYPE default null,
        msg		in journal_entries.msg%TYPE default null
    ) return journal_entries.journal_id%TYPE;

    procedure del (
	journal_id	in journal_entries.journal_id%TYPE
    );

    procedure delete_for_object(
	object_id       in acs_objects.object_id%TYPE
    );

end journal_entry;
/
show errors;

create or replace package body journal_entry
as

    function new (
        journal_id	in journal_entries.journal_id%TYPE default null,
        object_id	in journal_entries.object_id%TYPE,
        action		in journal_entries.action%TYPE,
	action_pretty   in journal_entries.action_pretty%TYPE,
        creation_date	in acs_objects.creation_date%TYPE default sysdate,
        creation_user	in acs_objects.creation_user%TYPE default null,
        creation_ip	in acs_objects.creation_ip%TYPE default null,
        msg		in journal_entries.msg%TYPE default null
    ) return journal_entries.journal_id%TYPE
    is
        v_journal_id journal_entries.journal_id%TYPE;
    begin
	v_journal_id := acs_object.new (
	  object_id => journal_id,
	  object_type => 'journal_entry',
	  creation_date => creation_date,
	  creation_user => creation_user,
	  creation_ip => creation_ip,
	  context_id => object_id
	);

        insert into journal_entries (
            journal_id, object_id, action, action_pretty, msg
        ) values (
            v_journal_id, object_id, action, action_pretty, msg
        );

        return v_journal_id;
    end new;

    procedure del (
	journal_id	in journal_entries.journal_id%TYPE
    )
    is
    begin
	delete from journal_entries where journal_id = journal_entry.del.journal_id;
	acs_object.del(journal_entry.del.journal_id);
    end del;

    procedure delete_for_object(
	object_id       in acs_objects.object_id%TYPE
    )
    is
	cursor journal_cur is
	    select journal_id from journal_entries where object_id = delete_for_object.object_id;
    begin
        for journal_rec in journal_cur loop
	    journal_entry.del(journal_rec.journal_id);
	end loop;
    end delete_for_object;

end journal_entry;
/
show errors;



create or replace package rel_constraint
as

  function new (
    --/** Creates a new relational constraint
    -- 
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    -- 
    --*/
    constraint_id	in rel_constraints.constraint_id%TYPE default null,
    constraint_type     in acs_objects.object_type%TYPE default 'rel_constraint',
    constraint_name	in rel_constraints.constraint_name%TYPE,
    rel_segment		in rel_constraints.rel_segment%TYPE,
    rel_side	        in rel_constraints.rel_side%TYPE default 'two',
    required_rel_segment in rel_constraints.required_rel_segment%TYPE,
    context_id		in acs_objects.context_id%TYPE default null,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null
  ) return rel_constraints.constraint_id%TYPE;

  procedure del (
    constraint_id	in rel_constraints.constraint_id%TYPE
  );

  function get_constraint_id (
    --/** Returns the constraint_id associated with the specified
    --    rel_segment and required_rel_segment for the specified site.
    -- 
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    -- 
    --*/
    rel_segment		in rel_constraints.rel_segment%TYPE,
    rel_side	        in rel_constraints.rel_side%TYPE default 'two',
    required_rel_segment in rel_constraints.required_rel_segment%TYPE
  ) return rel_constraints.constraint_id%TYPE;

  function violation (
    --/** Checks to see if there a relational constraint is violated
    --    by the precense of the specified relation. If not, returns 
    --    null. If so, returns an appropriate error string.
    -- 
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    -- 
    --    @param rel_id  The relation for which we want to find 
    --                   any violations
    --*/
    rel_id	in acs_rels.rel_id%TYPE
  ) return varchar;


  function violation_if_removed (
    --/** Checks to see if removing the specified relation would violate
    --    a relational constraint. If not, returns null. If so, returns
    --    an appropriate error string.
    -- 
    --    @author Michael Bryzek (mbryzek@arsdigita.com)
    --    @creation-date 1/2001
    -- 
    --    @param rel_id  The relation that we are planning to remove
    --*/
    rel_id	in acs_rels.rel_id%TYPE
  ) return varchar;

end;
/
show errors



create or replace package body rel_constraint
as

  function new (
    constraint_id	in rel_constraints.constraint_id%TYPE default null,
    constraint_type     in acs_objects.object_type%TYPE default 'rel_constraint',
    constraint_name	in rel_constraints.constraint_name%TYPE,
    rel_segment		in rel_constraints.rel_segment%TYPE,
    rel_side	        in rel_constraints.rel_side%TYPE default 'two',
    required_rel_segment in rel_constraints.required_rel_segment%TYPE,
    context_id		in acs_objects.context_id%TYPE default null,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null
  ) return rel_constraints.constraint_id%TYPE
  is
    v_constraint_id rel_constraints.constraint_id%TYPE;
  begin
    v_constraint_id := acs_object.new (
      object_id => constraint_id,
      object_type => constraint_type,
      context_id => context_id,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into rel_constraints
     (constraint_id, constraint_name, 
      rel_segment, rel_side, required_rel_segment)
    values
     (v_constraint_id, new.constraint_name, 
      new.rel_segment, new.rel_side, new.required_rel_segment);

     return v_constraint_id;
  end;

  procedure del (
    constraint_id	in rel_constraints.constraint_id%TYPE
  )
  is
  begin
    acs_object.del(constraint_id);
  end;

  function get_constraint_id (
    rel_segment		in rel_constraints.rel_segment%TYPE,
    rel_side	        in rel_constraints.rel_side%TYPE default 'two',
    required_rel_segment in rel_constraints.required_rel_segment%TYPE
  ) return rel_constraints.constraint_id%TYPE
  is
    v_constraint_id	rel_constraints.constraint_id%TYPE;
  begin
    select constraint_id into v_constraint_id
    from rel_constraints
    where rel_segment = get_constraint_id.rel_segment
      and rel_side = get_constraint_id.rel_side
      and required_rel_segment = get_constraint_id.required_rel_segment;

    return v_constraint_id;

  end;  

  function violation (
    rel_id	in acs_rels.rel_id%TYPE
  ) return varchar
  is
      v_error varchar(4000);
  begin

    v_error := null;

    for constraint_violated in
      (select /*+ FIRST_ROWS*/ constraint_id, constraint_name
       from rel_constraints_violated_one
       where rel_id = rel_constraint.violation.rel_id
         and rownum = 1) loop

	  v_error := v_error || 'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

          return v_error;
    end loop;

    for constraint_violated in
      (select /*+ FIRST_ROWS*/ constraint_id, constraint_name
       from rel_constraints_violated_two
       where rel_id = rel_constraint.violation.rel_id
         and rownum = 1) loop

           v_error := v_error || 'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

          return v_error;
    end loop;

    return v_error;

  end violation;


  function violation_if_removed (
    rel_id	in acs_rels.rel_id%TYPE
  ) return varchar
  is
      v_count integer;
      v_error varchar(4000);
  begin
    v_error := null;

    select count(*) into v_count
      from dual
     where exists (select 1 from rc_violations_by_removing_rel r where r.rel_id = violation_if_removed.rel_id);

    if v_count > 0 then
      -- some other relation depends on this one. Let's build up a string
      -- of the constraints we are violating
      for constraint_violated in (select constraint_id, constraint_name
                                    from rc_violations_by_removing_rel r
                                   where r.rel_id = violation_if_removed.rel_id) loop

          v_error := v_error || 'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

      end loop;

    end if;

    return v_error;

  end;


end;
/
show errors



create or replace package rel_segment
is
 function new (
  --/** Creates a new relational segment
  -- 
  --    @author Oumi Mehrotra (oumi@arsdigita.com)
  --    @creation-date 12/2000
  -- 
  --*/
  segment_id            in rel_segments.segment_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'rel_segment',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  segment_name          in rel_segments.segment_name%TYPE,
  group_id              in rel_segments.group_id%TYPE,
  rel_type              in rel_segments.rel_type%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 ) return rel_segments.segment_id%TYPE;

 procedure del (
    --/** Deletes a relational segment
    -- 
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    -- 
    --*/
   segment_id     in rel_segments.segment_id%TYPE
 );

 function name (
  segment_id      in rel_segments.segment_id%TYPE
 ) return rel_segments.segment_name%TYPE;

 function get (
    --/** EXPERIMENTAL / UNSTABLE -- use at your own risk
    --    Get the id of a segment given a group_id and rel_type.
    --    This depends on the uniqueness of group_id,rel_type.  We
    --    might remove the unique constraint in the future, in which
    --    case we would also probably remove this function.
    --
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    --
    --*/

   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE
 ) return rel_segments.segment_id%TYPE;

 function get_or_new (
    --/** EXPERIMENTAL / UNSTABLE -- use at your own risk
    --
    --    This function simplifies the use of segments a little by letting
    --    you not have to worry about creating and initializing segments.
    --    If the segment you're interested in exists, this function
    --    returns its segment_id.
    --    If the segment you're interested in doesn't exist, this function
    --    does a pretty minimal amount of initialization for the segment
    --    and returns a new segment_id.
    --
    --    @author Oumi Mehrotra (oumi@arsdigita.com)
    --    @creation-date 12/2000
    --
    --*/
   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE,
   segment_name   in rel_segments.segment_name%TYPE
                  default null
 ) return rel_segments.segment_id%TYPE;

end rel_segment;
/
show errors



create or replace package body rel_segment
is
 function new (
  segment_id            in rel_segments.segment_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'rel_segment',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  segment_name          in rel_segments.segment_name%TYPE,
  group_id              in rel_segments.group_id%TYPE,
  rel_type              in rel_segments.rel_type%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 ) return rel_segments.segment_id%TYPE
 is
  v_segment_id rel_segments.segment_id%TYPE;
 begin
  v_segment_id :=
   party.new(segment_id, object_type, creation_date, creation_user,
             creation_ip, email, url, context_id);

  insert into rel_segments
   (segment_id, segment_name, group_id, rel_type)
  values
   (v_segment_id, new.segment_name, new.group_id, new.rel_type);

  return v_segment_id;
 end new;

 procedure del (
   segment_id     in rel_segments.segment_id%TYPE
 )
 is
 begin

   -- remove all constraints on this segment
   for row in (select constraint_id 
                 from rel_constraints 
                where rel_segment = rel_segment.del.segment_id) loop

       rel_constraint.del(row.constraint_id);

   end loop;

   party.del(segment_id);

 end del;

 -- EXPERIMENTAL / UNSTABLE -- use at your own risk
 --
 function get (
   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE
 ) return rel_segments.segment_id%TYPE
 is
   v_segment_id rel_segments.segment_id%TYPE;
 begin
   select min(segment_id) into v_segment_id
   from rel_segments
   where group_id = get.group_id
     and rel_type = get.rel_type;

   return v_segment_id;
 end get;


 -- EXPERIMENTAL / UNSTABLE -- use at your own risk
 --
 -- This function simplifies the use of segments a little by letting
 -- you not have to worry about creating and initializing segments.
 -- If the segment you're interested in exists, this function
 -- returns its segment_id.
 -- If the segment you're interested in doesn't exist, this function
 -- does a pretty minimal amount of initialization for the segment
 -- and returns a new segment_id.
 function get_or_new (
   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE,
   segment_name   in rel_segments.segment_name%TYPE
                  default null
 ) return rel_segments.segment_id%TYPE
 is
   v_segment_id rel_segments.segment_id%TYPE;
   v_segment_name rel_segments.segment_name%TYPE;
 begin

   v_segment_id := get(group_id, rel_type);

   if v_segment_id is null then

      if segment_name is not null then
         v_segment_name := segment_name;
      else
         select groups.group_name || ' - ' || acs_object_types.pretty_name ||
                  ' segment'
         into v_segment_name
         from groups, acs_object_types
         where groups.group_id = get_or_new.group_id
           and acs_object_types.object_type = get_or_new.rel_type;

      end if;

      v_segment_id := rel_segment.new (
          object_type => 'rel_segment',
          creation_user => null,
          creation_ip => null,
          email => null,
          url => null,
          segment_name => v_segment_name,
          group_id => get_or_new.group_id,
          rel_type => get_or_new.rel_type,
          context_id => get_or_new.group_id
      );

   end if;

   return v_segment_id;

 end get_or_new;

 function name (
  segment_id      in rel_segments.segment_id%TYPE
 )
 return rel_segments.segment_name%TYPE
 is
  segment_name varchar(200);
 begin
  select segment_name
  into segment_name
  from rel_segments
  where segment_id = name.segment_id;

  return segment_name;
 end name;

end rel_segment;
/
show errors




create or replace package party_approved_member is

  procedure add_one(
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE
  );

  procedure add(
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE,
    p_rel_type in acs_rels.rel_type%TYPE
  );

  procedure remove_one (
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE
  );

  procedure remove (
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE,
    p_rel_type in acs_rels.rel_type%TYPE
  );

end party_approved_member;
/
show errors;

create or replace package body party_approved_member is

  procedure add_one(
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE
  )
  is
  begin

    insert into party_approved_member_map
      (party_id, member_id, cnt)
    values
      (p_party_id, p_member_id, 1);

    exception when dup_val_on_index then
      update party_approved_member_map
      set cnt = cnt + 1
      where party_id = p_party_id
        and member_id = p_member_id;

  end add_one;

  procedure add(
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE,
    p_rel_type in acs_rels.rel_type%TYPE
  )
  is
  begin

    add_one(p_party_id, p_member_id);

    -- if the relation type is mapped to a relational segment map that too

    for v_segments in (select segment_id
                       from rel_segments
                       where group_id = p_party_id
                         and rel_type in (select object_type
                                          from acs_object_types
                                          start with object_type = p_rel_type
                                          connect by prior supertype = object_type))
    loop
      add_one(v_segments.segment_id, p_member_id);
    end loop;

  end add;

  procedure remove_one (
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE
  )
  is
  begin

    update party_approved_member_map
    set cnt = cnt - 1
    where party_id = p_party_id
      and member_id = p_member_id;

    delete from party_approved_member_map
    where party_id = p_party_id
      and member_id = p_member_id
      and cnt = 0;

  end remove_one;

  procedure remove (
    p_party_id in parties.party_id%TYPE,
    p_member_id in parties.party_id%TYPE,
    p_rel_type in acs_rels.rel_type%TYPE
  )
  is
  begin

    remove_one(p_party_id, p_member_id);

    -- if the relation type is mapped to a relational segment unmap that too

    for v_segments in (select segment_id
                       from rel_segments
                       where group_id = p_party_id
                         and rel_type in (select object_type
                                          from acs_object_types
                                          start with object_type = p_rel_type
                                          connect by prior supertype = object_type))
    loop
      remove_one(v_segments.segment_id, p_member_id);
    end loop;

  end remove;

end party_approved_member;
/
show errors;



create or replace package site_node_object_map
as

    procedure new (
        object_id in site_node_object_mappings.object_id%TYPE,
        node_id in site_node_object_mappings.node_id%TYPE
    );

    procedure del (
        object_id in site_node_object_mappings.object_id%TYPE
    );

end site_node_object_map;
/
show errors

create or replace package body site_node_object_map
as

    procedure new (
        object_id in site_node_object_mappings.object_id%TYPE,
        node_id in site_node_object_mappings.node_id%TYPE
    ) is
    begin
        del(new.object_id);

        insert
        into site_node_object_mappings
        (object_id, node_id)
        values
        (new.object_id, new.node_id);
    end new;

    procedure del (
        object_id in site_node_object_mappings.object_id%TYPE
    ) is
    begin
        delete
        from site_node_object_mappings
        where object_id = del.object_id;
    end del;

end site_node_object_map;
/
show errors

--
-- packages/acs-kernel/sql/site-nodes-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-09-05
-- @cvs-id $Id$
--


create or replace package site_node
as

  -- Create a new site node. If you set directory_p to be 'f' then you
  -- cannot create nodes that have this node as their parent.

  function new (
    node_id             in site_nodes.node_id%TYPE default null,
    parent_id           in site_nodes.node_id%TYPE default null,
    name                in site_nodes.name%TYPE,
    object_id           in site_nodes.object_id%TYPE default null,
    directory_p         in site_nodes.directory_p%TYPE,
    pattern_p           in site_nodes.pattern_p%TYPE default 'f',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return site_nodes.node_id%TYPE;

  -- Delete a site node.

  procedure del (
    node_id             in site_nodes.node_id%TYPE
  );

  -- Return the node_id of a url. If the url begins with '/' then the
  -- parent_id must be null. This will raise the no_data_found
  -- exception if there is no mathing node in the site_nodes table.
  -- This will match directories even if no trailing slash is included
  -- in the url.

  function node_id (
    url                 in varchar2,
    parent_id   in site_nodes.node_id%TYPE default null
  ) return site_nodes.node_id%TYPE;

  -- Return the url of a node_id.

  function url (
    node_id             in site_nodes.node_id%TYPE
  ) return varchar2;

end;
/
show errors

create or replace package body site_node
as

  function new (
    node_id             in site_nodes.node_id%TYPE default null,
    parent_id           in site_nodes.node_id%TYPE default null,
    name                in site_nodes.name%TYPE,
    object_id           in site_nodes.object_id%TYPE default null,
    directory_p         in site_nodes.directory_p%TYPE,
    pattern_p           in site_nodes.pattern_p%TYPE default 'f',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return site_nodes.node_id%TYPE
  is
    v_node_id           site_nodes.node_id%TYPE;
    v_directory_p       site_nodes.directory_p%TYPE;
  begin
    if parent_id is not null then
      select directory_p into v_directory_p
      from site_nodes
      where node_id = new.parent_id;

      if v_directory_p = 'f' then
        raise_application_error (
          -20000,
          'Node ' || parent_id || ' is not a directory'
        );
      end if;
    end if;

    v_node_id := acs_object.new (
      object_id => node_id,
      object_type => 'site_node',
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into site_nodes
     (node_id, parent_id, name, object_id, directory_p, pattern_p)
    values
     (v_node_id, new.parent_id, new.name, new.object_id,
      new.directory_p, new.pattern_p);

     return v_node_id;
  end;

  procedure del (
    node_id             in site_nodes.node_id%TYPE
  )
  is
  begin
    delete from site_nodes
    where node_id = site_node.del.node_id;

    acs_object.del(node_id);
  end;

  function find_pattern (
    node_id     in site_nodes.node_id%TYPE
  ) return site_nodes.node_id%TYPE
  is
    v_pattern_p site_nodes.pattern_p%TYPE;
    v_parent_id site_nodes.node_id%TYPE;
  begin
    if node_id is null then
      raise no_data_found;
    end if;

    select pattern_p, parent_id into v_pattern_p, v_parent_id
    from site_nodes
    where node_id = find_pattern.node_id;

    if v_pattern_p = 't' then
      return node_id;
    else
      return find_pattern(v_parent_id);
    end if;
  end;

  function node_id (
    url                 in varchar2,
    parent_id           in site_nodes.node_id%TYPE default null
  ) return site_nodes.node_id%TYPE
  is
    v_pos               integer;
    v_first             site_nodes.name%TYPE;
    v_rest              varchar2(4000);
    v_node_id           integer;
    v_pattern_p         site_nodes.pattern_p%TYPE;
    v_url               varchar2(4000);
    v_directory_p       site_nodes.directory_p%TYPE;
    v_trailing_slash_p  char(1);
  begin
    v_url := url;

    if substr(v_url, length(v_url), 1) = '/' then
      -- It ends with a / so it must be a directory.
      v_trailing_slash_p := 't';
      v_url := substr(v_url, 1, length(v_url) - 1);
    end if;

    v_pos := 1;

    while v_pos <= length(v_url) and substr(v_url, v_pos, 1) != '/' loop
      v_pos := v_pos + 1;
    end loop;

    if v_pos = length(v_url) then
      v_first := v_url;
      v_rest := null;
    else
      v_first := substr(v_url, 1, v_pos - 1);
      v_rest := substr(v_url, v_pos + 1);
    end if;

    begin
      -- Is there a better way to do these freaking null compares?
      select node_id, directory_p into v_node_id, v_directory_p
      from site_nodes
      where nvl(parent_id, 3.14) = nvl(site_node.node_id.parent_id, 3.14)
      and nvl(name, chr(10)) = nvl(v_first, chr(10));
    exception
      when no_data_found then
        return find_pattern(parent_id);
    end;

    if v_rest is null then
      if v_trailing_slash_p = 't' and v_directory_p = 'f' then
        return find_pattern(parent_id);
      else
        return v_node_id;
      end if;
    else
      return node_id(v_rest, v_node_id);
    end if;
  end;

  function url (
    node_id             in site_nodes.node_id%TYPE
  ) return varchar2
  is
    v_parent_id site_nodes.node_id%TYPE;
    v_name              site_nodes.name%TYPE;
    v_directory_p       site_nodes.directory_p%TYPE;
  begin
    if node_id is null then
      return '';
    end if;

    select parent_id, name, directory_p into
           v_parent_id, v_name, v_directory_p
    from site_nodes
    where node_id = url.node_id;

    if v_directory_p = 't' then
      return url(v_parent_id) || v_name || '/';
    else
      return url(v_parent_id) || v_name;
    end if;
  end;

end;
/
show errors



--
--
--
--
--
-----------
-- VIEWS --
-----------

-- View rel_constraints_violated_one
--
-- pseudo sql:
--
-- select all the side 'one' constraints
-- from the constraints and the associated relations of rel_segment
-- where the relation's container_id (i.e., object_id_one) is not in the 
-- relational segment required_rel_segment.

create or replace view rel_constraints_violated_one as 
select constrained_rels.constraint_id, constrained_rels.constraint_name,
   constrained_rels.rel_id, constrained_rels.container_id,
   constrained_rels.party_id, constrained_rels.rel_type, 
   constrained_rels.rel_segment,constrained_rels.rel_side, 
   constrained_rels.required_rel_segment
from (select rel_constraints.constraint_id, rel_constraints.constraint_name, 
             r.rel_id, r.container_id, r.party_id, r.rel_type, 
             rel_constraints.rel_segment,
             rel_constraints.rel_side, 
             rel_constraints.required_rel_segment
      from rel_constraints, rel_segment_party_map r
      where rel_constraints.rel_side = 'one'
        and rel_constraints.rel_segment = r.segment_id
     ) constrained_rels,
     rel_segment_party_map rspm
where rspm.segment_id(+) = constrained_rels.required_rel_segment
  and constrained_rels.container_id is null
  and rspm.party_id is null;

-- View rel_constraints_violated_two
--
-- pseudo sql:
--
-- select all the side 'two' constraints
-- from the constraints and the associated relations of rel_segment
-- where the relation's party_id (i.e., object_id_two) is not in the 
-- relational segment required_rel_segment.

create or replace view rel_constraints_violated_two as
select constrained_rels.constraint_id, constrained_rels.constraint_name,
   constrained_rels.rel_id, constrained_rels.container_id,
   constrained_rels.party_id, constrained_rels.rel_type, 
   constrained_rels.rel_segment,constrained_rels.rel_side, 
   constrained_rels.required_rel_segment
from (select rel_constraints.constraint_id, rel_constraints.constraint_name, 
             r.rel_id, r.container_id, r.party_id, r.rel_type, 
             rel_constraints.rel_segment,
             rel_constraints.rel_side, 
             rel_constraints.required_rel_segment
      from rel_constraints, rel_segment_party_map r
      where rel_constraints.rel_side = 'two'
        and rel_constraints.rel_segment = r.segment_id
     ) constrained_rels,
     rel_segment_party_map rspm
where rspm.segment_id(+) = constrained_rels.required_rel_segment
  and constrained_rels.party_id is null
  and rspm.party_id is null;


-- View: rc_all_constraints
--
-- Question: Given group :group_id and rel_type :rel_type . . .
--
--           What segments must a party be in 
--           if the party were to be on side :rel_side of a relation of 
--           type :rel_type to group :group_id ?
--
-- Answer:   select required_rel_segment
--           from rc_all_constraints
--           where group_id = :group_id
--             and rel_type = :rel_type
--             and rel_side = :rel_side
--
-- Notes: we take special care not to get identity rows, where group_id and 
-- rel_type are equivalent to segment_id.  This can happen if there are some 
-- funky constraints in the system, such as membership to Arsdigita requires 
-- user_profile to Arsdigita. Then you could get rows from the 
-- rc_all_constraints view saying that:
--     user_profile to Arsdigita 
--     requires being in the segment of Arsdigita Users.
--
-- This happens because user_profile is a type of memebrship, and there's a 
-- constraint saying that membership to Arsdigita requires being in the
-- Arsdigita Users segment.  We eliminate such rows from the rc_all_constraints
-- view with the "not (...)" clause below.
--
create or replace view rc_all_constraints as
select group_rel_types.group_id, 
       group_rel_types.rel_type,
       rel_constraints.rel_segment,
       rel_constraints.rel_side,
       required_rel_segment
  from rel_constraints,
       rel_segment_group_rel_type_map group_rel_types,
       rel_segments req_seg
 where rel_constraints.rel_segment = group_rel_types.segment_id
   and rel_constraints.required_rel_segment = req_seg.segment_id
   and not (req_seg.group_id = group_rel_types.group_id and
            req_seg.rel_type = group_rel_types.rel_type);

create or replace view rc_all_distinct_constraints as
select distinct 
       group_id, rel_type, rel_segment, rel_side, required_rel_segment
from rc_all_constraints;


-- THIS VIEW IS FOR COMPATIBILITY WITH EXISTING CODE
-- New code should use rc_all_constraints instead!
--
-- View: rc_required_rel_segments
--
-- Question: Given group :group_id and rel_type :rel_type . . .
--
--           What segments must a party be in 
--           if the party were to be belong to group :group_id 
--           through a relation of type :rel_type ?
--
-- Answer:   select required_rel_segment
--           from rc_required_rel_segments
--           where group_id = :group_id
--             and rel_type = :rel_type
--

create or replace view rc_required_rel_segments as
select distinct group_id, rel_type, required_rel_segment
from rc_all_constraints
where rel_side = 'two';

                    
-- View: rc_parties_in_required_segs
--
-- Question: Given group :group_id and rel_type :rel_type . . .
--
--           What parties are "allowed" to be in group :group_id
--           through a relation of type :rel_type ?  By "allowed",
--           we mean that no relational constraints would be violated.
--
-- Answer:   select party_id, acs_object.name(party_id)
--           from parties_in_rc_required_rel_segments
--           where group_id = :group_id
--             and rel_type = :rel_type
--
create or replace view rc_parties_in_required_segs as
select parties_in_required_segs.group_id,
       parties_in_required_segs.rel_type,
       parties_in_required_segs.party_id
from
   (select required_segs.group_id, 
           required_segs.rel_type, 
           seg_parties.party_id,
           count(*) as num_matching_segs
    from rc_required_rel_segments required_segs,
         rel_segment_party_map seg_parties
    where required_segs.required_rel_segment = seg_parties.segment_id
    group by required_segs.group_id, 
             required_segs.rel_type, 
             seg_parties.party_id) parties_in_required_segs,
   (select group_id, rel_type, count(*) as total
    from rc_required_rel_segments
    group by group_id, rel_type) total_num_required_segs
where
      parties_in_required_segs.group_id = total_num_required_segs.group_id
  and parties_in_required_segs.rel_type = total_num_required_segs.rel_type
  and parties_in_required_segs.num_matching_segs = total_num_required_segs.total
UNION ALL
select group_rel_type_combos.group_id,
       group_rel_type_combos.rel_type,
       parties.party_id
from rc_required_rel_segments, 
     (select groups.group_id, comp_or_member_rel_types.rel_type
      from groups,
           (select object_type as rel_type from acs_object_types
            start with object_type = 'membership_rel'
                    or object_type = 'composition_rel'
            connect by supertype = prior object_type) comp_or_member_rel_types
     ) group_rel_type_combos,
     parties
where rc_required_rel_segments.group_id(+) = group_rel_type_combos.group_id
  and rc_required_rel_segments.rel_type(+) = group_rel_type_combos.rel_type
  and rc_required_rel_segments.group_id is null;


-- View: rc_valid_rel_types
--
-- Question: What types of membership or composition are "valid"
--           for group :group_id ?   A membership or composition 
--           type R is "valid" when no relational constraints would 
--           be violated if a party were to belong to group :group_id 
--           through a rel of type R.
--
-- Answer:   select rel_type
--           from rc_valid_rel_types
--           where group_id = :group_id
--
-- 
create or replace view rc_valid_rel_types as
select side_one_constraints.group_id, 
       side_one_constraints.rel_type
  from (select required_segs.group_id, 
               required_segs.rel_type, 
               count(*) as num_satisfied
          from rc_all_constraints required_segs,
               rel_segment_party_map map
         where required_segs.rel_side = 'one'
           and required_segs.required_rel_segment = map.segment_id
           and required_segs.group_id = map.party_id
        group by required_segs.group_id, 
                 required_segs.rel_type) side_one_constraints,
       (select group_id, rel_type, count(*) as total
          from rc_all_constraints
         where rel_side = 'one'
        group by group_id, rel_type) total_side_one_constraints
 where side_one_constraints.group_id = total_side_one_constraints.group_id
   and side_one_constraints.rel_type = total_side_one_constraints.rel_type
   and side_one_constraints.num_satisfied = total_side_one_constraints.total
UNION ALL
select group_rel_type_combos.group_id,
       group_rel_type_combos.rel_type
from (select * from rc_all_constraints where rel_side='one') rc_all_constraints, 
     (select groups.group_id, comp_or_member_rel_types.rel_type
      from groups, 
           (select object_type as rel_type from acs_object_types
            start with object_type = 'membership_rel'
                    or object_type = 'composition_rel'
            connect by supertype = prior object_type) comp_or_member_rel_types
     ) group_rel_type_combos
where rc_all_constraints.group_id(+) = group_rel_type_combos.group_id
  and rc_all_constraints.rel_type(+) = group_rel_type_combos.rel_type
  and rc_all_constraints.group_id is null;


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


-- View: rc_segment_required_seg_map
--
-- Question: Given a relational segment :rel_segment . . .
--
--           What are all the segments in the system that a party has to 
--           be in if the party were to be on side :rel_side of a relation
--           in segement :rel_segment?  
--
--           We want not only the direct required_segments (which we could
--           get from the rel_constraints table directly), but also the 
--           indirect ones (i.e., the segments that are required by the 
--           required segments, and so on).
--
-- Answer:   select required_rel_segment
--           from rc_segment_required_seg_map
--           where rel_segment = :rel_segment
--             and rel_side = :rel_side
--
--
create or replace view rc_segment_required_seg_map as
select rc.rel_segment, rc.rel_side, rc_required.required_rel_segment
from rel_constraints rc, rel_constraints rc_required 
where rc.rel_segment in (
          select rel_segment
          from rel_constraints
          start with rel_segment = rc_required.rel_segment
          connect by required_rel_segment = prior rel_segment
                 and prior rel_side = 'two'
      );

-- View: rc_segment_dependency_levels
--
-- This view is designed to determine what order of segments is safe
-- to use when adding a party to multiple segments.
--
-- Question: Given a table or view called segments_I_want_to_be_in,
--           which segments can I add a party to first, without violating
--           any relational constraints?
--
-- Answer:   select segment_id
--           from segments_I_want_to_be_in s,
--                rc_segment_dependency_levels dl
--           where s.segment_id = dl.segment_id(+)
--           order by nvl(dl.dependency_level, 0)
--
-- Note: dependency_level = 1 is the minimum dependency level.
--       dependency_level = N means that you cannot add a party to the
--                          segment until you first add the party to some
--                          segment of dependency_level N-1 (this view doesn't
--                          tell you which segment -- you can get that info
--                          from rel_constraints table or other views.
--
-- Another Note: not all segemnts in rel_segemnts are returned by this view.
-- This view only returns segments S that have at least one rel_constraints row
-- where rel_segment = S.  Segments that have no constraints defined on them
-- can be said to have dependency_level=0, hence the outer join and nvl in the
-- example query above (see "Answer:").  I could have embeded that logic into
-- this view, but that would unnecessarily degrade performance.
--
create or replace view rc_segment_dependency_levels as
      select rel_segment as segment_id,
             max(tree_level) as dependency_level
      from (select rel_segment, level as tree_level
            from rel_constraints
            connect by required_rel_segment = prior rel_segment
                and prior rel_side = 'two')
      group by rel_segment
;


