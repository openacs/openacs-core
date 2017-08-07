declare
 attr_id acs_attributes.attribute_id%TYPE;
begin
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

alter table acs_objects add (
        title			varchar2(1000) default null,
        package_id		integer default null
				constraint acs_objects_package_id_fk
				references apm_packages(package_id) on delete set null
);

create index acs_objects_package_object_idx on acs_objects (package_id, object_id);
create index acs_objects_title_idx on acs_objects(title);

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

---------
-- update data
---------

update acs_objects
set title = (select group_name
             from groups
             where group_id = object_id)
where object_id in (select group_id from groups);

update acs_objects
set title = (select email
             from parties
             where party_id = object_id)
where object_type = 'party';

update acs_objects
set title = (select first_names || ' ' || last_name
             from persons
             where person_id = object_id)
where object_type in ('user','person');

update acs_objects
set title = (select short_name
             from auth_authorities
             where authority_id = object_id)
where object_type = 'authority';

update acs_objects
set title = (select action
             from journal_entries
             where journal_id = object_id)
where object_type = 'journal_entry';

update acs_objects
set title = (select name
             from site_nodes
             where node_id = acs_objects.object_id),
    package_id = (select object_id
                  from site_nodes
                  where node_id = acs_objects.object_id)
where object_type = 'site_node';

update acs_objects
set title = (select instance_name
             from apm_packages
             where package_id = object_id),
    package_id = object_id
where object_type in ('apm_package','apm_application','apm_service');

update acs_objects
set title = (select package_key || ', Version ' || version_name
             from apm_package_versions
             where version_id = object_id)
where object_type = 'apm_package_version';

update acs_objects
set title = (select package_key || ': Parameter ' || parameter_name
             from apm_parameters
             where parameter_id = object_id)
where object_type = 'apm_parameter';

update acs_objects
set title = (select rel_type || ': ' || object_id_one || ' - ' || object_id_two
             from acs_rels
             where rel_id = object_id)
where object_id in (select rel_id from acs_rels);

update acs_objects
set title = (select segment_name
             from rel_segments
             where segment_id = object_id)
where object_type = 'rel_segment';

update acs_objects
set title = (select constraint_name
             from rel_constraints
             where constraint_id = object_id)
where object_type = 'rel_constraint';

update acs_objects
set title = 'Unregistered Visitor'
where object_id = 0;

update acs_objects
set title = 'Default Context'
where object_id = -3;

update acs_objects
set title = 'Root Security Context'
where object_id = -4;

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

-------
-- Acs_Rels
-------

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

---------
-- APM
---------

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
       object_type => 'apm_parameter',
       title => register_parameter.package_key || ': Parameter ' || register_parameter.parameter_name
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

    update acs_objects
       set title = (select package_key || ': Parameter ' || parameter_name
                    from apm_parameters
                    where parameter_id = update_parameter.parameter_id)
     where object_id = update_parameter.parameter_id;

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
       if instance_name is null then 
	 v_instance_name := package_key || ' ' || v_package_id;
       else
	 v_instance_name := instance_name;
       end if;

       v_package_id := acs_object.new(
          object_id => package_id,
          object_type => object_type,
          title => v_instance_name,
          creation_date => creation_date,
          creation_user => creation_user,
	  creation_ip => creation_ip,
	  context_id => context_id
	 );

       update acs_objects
       set package_id = v_package_id
       where object_id = v_package_id;

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
		object_type => 'apm_package_version',
                title => package_key || ', Version ' || version_name
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

        update acs_objects
        set title = (select v.package_key || ', Version ' || v.version_name
                     from apm_package_versions v
                     where v.version_id = copy.version_id)
        where object_id = copy.version_id;
    
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

-------------------
-- PARTY PACKAGE --
-------------------

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
   acs_object.new(
     object_id => party_id,
     object_type => object_type,
     title => lower(email),
     creation_date => creation_date,
     creation_user => creation_user,
     creation_ip => creation_ip,
     context_id => context_id);

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

  update acs_objects
  set title = first_names || ' ' || last_name
  where object_id = v_person_id;

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

---------
-- Acs Groups
---------

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

  update acs_objects
  set title = group_name
  where object_id = v_group_id;


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

--------
-- Journal
--------

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
          title => action,
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

--------
-- Site Nodes
--------

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
      title => name,
      package_id => object_id,
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

@@ ../authentication-package-create.sql
@@ ../rel-segments-body-create.sql
@@ ../rel-constraints-body-create.sql
