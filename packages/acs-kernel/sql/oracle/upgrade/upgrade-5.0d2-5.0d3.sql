-- 
-- Upgrade script from 5.0d2 to 5.0d3
--
-- @author Peter Marklund (peter@collaboraid.biz)
--
-- @cvs-id $Id$
--


-- Change delete (reserved word in Oracle) to del

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

   -- This function will verify that each actually descendant of
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

-- ****** New authentication datamodel

create table auth_authorities (
    authority_id             integer
                             constraint auth_authorities_pk
                             primary key
                             constraint auth_authorities_aid_fk
                             references acs_objects(object_id)
                             on delete cascade,
    short_name               varchar2(255)
                             constraint auth_authority_short_name_un
                             unique,
    pretty_name              varchar2(4000),
    help_contact_text        varchar2(4000),
    help_contact_text_format varchar(200),
    enabled_p                char(1) default 't' 
                             constraint auth_authority_enabled_p_nn
                             not null 
                             constraint auth_authority_enabled_p_ck
                             check (enabled_p in ('t','f')),
    sort_order               integer not null,
    -- auth_authentication implementation
    -- (Cannot reference acs_sc_impls table as it doesn't exist yet)
    auth_impl_id             integer
                             constraint auth_authority_auth_impl_fk
                             references acs_objects(object_id),
    -- auth_password implementation
    pwd_impl_id              integer
                             constraint auth_authority_pwd_impl_fk
                             references acs_objects(object_id),
    forgotten_pwd_url        varchar2(4000),
    change_pwd_url           varchar2(4000),
    -- auth_registration implementation
    register_impl_id         integer
                             constraint auth_authority_reg_impl_fk
                             references acs_objects(object_id),
    register_url             varchar2(4000),
    -- auth_user_info implementation
    user_info_impl_id        integer
                             constraint auth_authority_userinf_impl_fk
                             references acs_objects(object_id),
    -- batch sync
    -- auth_sync_retrieve implementation
    get_doc_impl_id          integer references acs_objects(object_id),
    -- auth_sync_process implementation
    process_doc_impl_id      integer references acs_objects(object_id),
    batch_sync_enabled_p     char(1) default 'f' 
                             constraint auth_authority_bs_enabled_p_nn
                             not null 
                             constraint auth_authority_bs_enabled_p_ck
                             check (batch_sync_enabled_p in ('t','f'))
);

comment on column auth_authorities.help_contact_text is '
    Contact information (phone, email, etc.) to be displayed
    as a last resort when people are having problems with an authority.
';

comment on column auth_authorities.forgotten_pwd_url is '
    Any username in this url must be on the syntax foo={username}
    and {username} will be replaced with the real username
';

comment on column auth_authorities.change_pwd_url is '
    Any username in this url must be on the syntax foo={username}
    and {username} will be replaced with the real username
';

-- Define the acs object type
begin
  acs_object_type.create_type (
    object_type => 'authority',
    pretty_name => 'Authority',
    pretty_plural => 'Authorities',
    supertype => 'acs_object',
    table_name => 'auth_authorities',
    id_column => 'authority_id',
    package_name => null,
    abstract_p => 'f',
    type_extension_table => null,
    name_method => null
  );
end;
/
show errors

create table auth_driver_params(
      authority_id    integer
                      constraint auth_driver_params_aid_fk 
                      references auth_authorities(authority_id)
                      constraint auth_driver_params_aid_nn
                      not null,
      impl_id         integer
                      constraint auth_driver_params_iid_fk
                      -- Cannot reference acs_sc_impls table as it doesn't exist yet
                      references acs_objects(object_id)
                      constraint auth_driver_params_iid_nn
                      not null,
      key             varchar2(200),
      value           clob,
      constraint auth_driver_params_pk
      primary key (authority_id, impl_id, key)
);

-- Create PLSQL package
create or replace package authority
as 
    function new(
        authority_id in auth_authorities.authority_id%TYPE default null,
        object_type acs_object_types.object_type%TYPE default 'authority',
        short_name in auth_authorities.short_name%TYPE,
        pretty_name in auth_authorities.pretty_name%TYPE,
        enabled_p in auth_authorities.enabled_p%TYPE default 't',
        sort_order in auth_authorities.sort_order%TYPE,
        auth_impl_id in auth_authorities.auth_impl_id%TYPE default null,
        pwd_impl_id in auth_authorities.pwd_impl_id%TYPE default null,
        forgotten_pwd_url in auth_authorities.forgotten_pwd_url%TYPE default null,
        change_pwd_url in auth_authorities.change_pwd_url%TYPE default null,
        register_impl_id in auth_authorities.register_impl_id%TYPE default null,
        register_url in auth_authorities.register_url%TYPE default null,
        help_contact_text in auth_authorities.help_contact_text%TYPE default null,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    ) return integer;

    function del(
        delete_authority_id in auth_authorities.authority_id%TYPE
    ) return integer;

end authority;
/
show errors

create or replace package body authority
as 
    function new(
        authority_id in auth_authorities.authority_id%TYPE default null,
        object_type acs_object_types.object_type%TYPE default 'authority',
        short_name in auth_authorities.short_name%TYPE,
        pretty_name in auth_authorities.pretty_name%TYPE,
        enabled_p in auth_authorities.enabled_p%TYPE default 't',
        sort_order in auth_authorities.sort_order%TYPE,
        auth_impl_id in auth_authorities.auth_impl_id%TYPE default null,
        pwd_impl_id in auth_authorities.pwd_impl_id%TYPE default null,
        forgotten_pwd_url in auth_authorities.forgotten_pwd_url%TYPE default null,
        change_pwd_url in auth_authorities.change_pwd_url%TYPE default null,
        register_impl_id in auth_authorities.register_impl_id%TYPE default null,
        register_url in auth_authorities.register_url%TYPE default null,
        help_contact_text in auth_authorities.help_contact_text%TYPE default null,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    )
    return integer
    is
        v_authority_id integer; 
        v_sort_order integer;        
    begin
        if sort_order is null then
          select max(sort_order) + 1
                 into v_sort_order
                 from auth_authorities;
        else
           v_sort_order := sort_order;
        end if;


        v_authority_id  := acs_object.new(
            object_id     => new.authority_id,
            object_type   => new.object_type,
            creation_date => sysdate(),
            creation_user => new.creation_user,
            creation_ip   => new.creation_ip,
            context_id    => new.context_id
        );

        insert into auth_authorities (authority_id, short_name, pretty_name, enabled_p, 
                                      sort_order, auth_impl_id, pwd_impl_id, 
                                      forgotten_pwd_url, change_pwd_url, register_impl_id,
                                      help_contact_text)
        values (v_authority_id, new.short_name, new.pretty_name, new.enabled_p, 
                                      v_sort_order, new.auth_impl_id, new.pwd_impl_id, 
                                      new.forgotten_pwd_url, new.change_pwd_url, new.register_impl_id, 
                                      new.help_contact_text);

        return v_authority_id;
    end new;

    function del(
        delete_authority_id in auth_authorities.authority_id%TYPE
    )
    return integer
    is
    begin
        acs_object.del(delete_authority_id);
        return 0;
    end del;

end authority;
/
show errors


-- Create the local authority
declare
  v_authority_id integer;
begin 
    v_authority_id := authority.new(
        short_name  => 'local',
        pretty_name => 'OpenACS Local',
        sort_order  => '1'
    );
end;
/
show errors


-- ****** Changes to the users table

alter table users add authority_id            integer
                                constraint users_auth_authorities_fk
                                references auth_authorities(authority_id);

alter table users add username  varchar2(100) default '-'
                                constraint users_username_nn 
                                not null;

-- set all current users' username to equal their email
-- and their authority to be the local authority
-- Exclude the unregistered visitor as he/she has a null email
update users 
set    username = (select email 
                   from parties 
                   where party_id = user_id),
       authority_id = (select authority_id from auth_authorities where short_name = 'local')
where user_id <> 0;

-- add a unique constraint
alter table users add constraint users_authority_username_un unique (authority_id, username);

-- Need to recreate the cc_users view
create or replace view cc_users
as
select
o.object_id,o.object_type,o.context_id,o.security_inherit_p,o.creation_user,o.creation_date,o.creation_ip,o.last_modified,o.modifying_user,o.modifying_ip,
pa.party_id, pa.email, pa.url, 
pe.person_id, pe.first_names, pe.last_name, 
u.user_id,u.authority_id,username,u.password,u.salt,u.screen_name,u.priv_name,u.priv_email,u.email_verified_p,u.email_bouncing_p,u.no_alerts_until,u.last_visit,u.second_to_last_visit,u.n_sessions,u.password_question,u.password_answer,password_changed_date,
mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr, acs_magic_objects mo
where o.object_id = pa.party_id
and pa.party_id = pe.person_id
and pe.person_id = u.user_id
and u.user_id = m.member_id
and m.group_id = mo.object_id
and mo.name = 'registered_users'
and m.rel_id = mr.rel_id
and m.container_id = m.group_id;
