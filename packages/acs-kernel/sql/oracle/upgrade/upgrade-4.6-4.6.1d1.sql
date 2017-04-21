-- Add two new datatypes (supported by templating already).
-- 
 insert into acs_datatypes
  (datatype, max_n_values)
 values
  ('url', null);

 insert into acs_datatypes
  (datatype, max_n_values)
 values
  ('email', null);

-- This giant package body is here since we are adding 
-- two lines to acs_object.delete() to delete direct permissions 
-- granted on the object which we are deleting
--

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

 procedure delete (
  object_id	in acs_objects.object_id%TYPE
 )
 is
   v_exists_p char;
 begin
  
  -- Delete dynamic/generic attributes
  delete from acs_attribute_values where object_id = acs_object.delete.object_id;

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
                                where o.object_id = acs_object.delete.object_id)
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

 end delete;

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
        last_modified in acs_objects.last_modified%TYPE default sysdate
    )
    is
        v_parent_id acs_objects.context_id%TYPE;
    begin
        update acs_objects
        set acs_objects.last_modified = acs_object.update_last_modified.last_modified
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

-- DRB: Change security context to object -4

drop trigger acs_objects_context_id_in_tr;
drop trigger acs_objects_context_id_up_tr;

delete from acs_magic_objects
where name = 'security_context_root';

declare
  foo acs_objects.object_id%TYPE;
begin
  foo := acs_object.new (
           object_id => -4,
           object_type => 'acs_object'
         );
end;
/
show errors;

insert into acs_magic_objects
 (name, object_id)
values
 ('security_context_root', -4);

update acs_object_context_index
set ancestor_id = -4
where ancestor_id = 0;

update acs_object_context_index
set object_id = -4
where object_id = 0;

update acs_permissions
set object_id = -4
where object_id = 0;

update acs_objects
set context_id = -4
where context_id = 0;

-- Content Repository sets parent_id to security_context_root
-- for content modules

update cr_items
set parent_id = -4
where parent_id = 0;

begin
  acs_object.delete(0);
end;
/
show errors;

create or replace trigger acs_objects_context_id_in_tr
after insert on acs_objects
for each row
declare
  security_context_root acs_magic_objects.object_id%TYPE;
begin
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

    select object_id into security_context_root
    from acs_magic_objects
    where name = 'security_context_root';

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
  security_context_root acs_magic_objects.object_id%TYPE;
begin
  if :new.object_id = :old.object_id and
     :new.context_id = :old.context_id and
     :new.security_inherit_p = :old.security_inherit_p then
    return;
  end if;

  -- Remove my old ancestors from my descendants.
  delete from acs_object_context_index
  where object_id in (select object_id
                      from acs_object_contexts
                      where ancestor_id = :old.object_id)
  and ancestor_id in (select ancestor_id
		      from acs_object_contexts
		      where object_id = :old.object_id);

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

    select object_id into security_context_root
    from acs_magic_objects
    where name = 'security_context_root';

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

----------------------------------------------------------------------------

-- DRB: We now will turn the magic -1 party into a group that contains
-- all registered users and a new unregistered visitor.  This will allow
-- us to do all permission checking on a materialized version of the
-- party_member_map.

-- Make our new "Unregistered Visitor" be object 0, which corresponds
-- with the user_id assigned throughout the toolkit Tcl code

insert into acs_objects
  (object_id, object_type)
values
  (0, 'person');

insert into parties
  (party_id)
values
  (0);

insert into persons
  (person_id, first_names, last_name)
values
  (0, 'Unregistered', 'Visitor');

insert into acs_magic_objects
  (name, object_id)
values
  ('unregistered_visitor', 0);

-- Now transform the old special -1 party into a legitimate group with
-- one user, our Unregistered Visitor

update acs_objects
set object_type = 'group'
where object_id = -1;
 
insert into groups
 (group_id, group_name, join_policy)
values
 (-1, 'The Public', 'closed');

declare
  foo acs_objects.object_id%TYPE;
begin

  -- Add our only user, the Unregistered Visitor

  foo := membership_rel.new (
           rel_type => 'membership_rel',
           object_id_one => acs.magic_object_id('the_public'),      
           object_id_two => acs.magic_object_id('unregistered_visitor'),
           member_state => 'approved'
         );

  -- Now declare "The Public" to be composed of itself and the "Registered
  -- Users" group

  foo := composition_rel.new (
           rel_type => 'composition_rel',
           object_id_one => acs.magic_object_id('the_public'),
           object_id_two => acs.magic_object_id('registered_users')
         );
end;
/
show errors;

-------------------------------------------------------------------------------

-- DRB: Replace the old party_emmber_map and party_approved_member_map views
-- (they were both the same and very slow) with a table containing the same
-- information.  This can be used to greatly speed permissions checking.

drop view party_member_map;
drop view party_approved_member_map;

-- The count column is needed because composition_rels lead to a lot of
-- redundant data in the group element map (i.e. you can belong to the
-- registered users group an infinite number of times, strange concept)

-- (it is "cnt" rather than "count" because Oracle confuses it with the
-- "count()" aggregate in some contexts)

-- Though for permission checking we only really need to map parties to
-- member users, the old view included identity entries for all parties
-- in the system.  It doesn't cost all that much to maintain the extra
-- rows so we will, just in case some overly clever programmer out there
-- depends on it.

create table party_approved_member_map (
    party_id        integer
                    constraint party_member_party_fk
                    references parties,
    member_id       integer
                    constraint party_member_member_fk
                    references parties,
    cnt             integer,
    constraint party_approved_member_map_pk
    primary key (party_id, member_id)
);

-- Need this to speed referential integrity 
create index party_member_member_idx on party_approved_member_map(member_id);

-- Every person is a member of itself

insert into party_approved_member_map
  (party_id, member_id, cnt)
select party_id, party_id, 1
from parties;

-- Every party is a member if it is an approved member of
-- some sort of membership_rel

insert into party_approved_member_map
  (party_id, member_id, cnt)
select group_id, member_id, count(*)
from group_approved_member_map
group by group_id, member_id;

-- Every party is a member if it is an approved member of
-- some sort of relation segment

insert into party_approved_member_map
  (party_id, member_id, cnt)
select segment_id, member_id, count(*)
from rel_seg_approved_member_map
group by segment_id, member_id;

-- Triggers to maintain party_approved_member_map when parties are create or replaced or
-- destroyed.

create or replace trigger parties_in_tr after insert on parties
for each row 
begin
  insert into party_approved_member_map
    (party_id, member_id, cnt)
  values
    (:new.party_id, :new.party_id, 1);
end parties_in_tr;
/
show errors;

create or replace trigger parties_del_tr before delete on parties
for each row
begin
  delete from party_approved_member_map
  where party_id = :old.party_id
    and member_id = :old.party_id;
end parties_del_tr;
/
show errors;

-- Triggers to maintain party_approved_member_map when relational segments are
-- create or replaced or destroyed.   We only remove the (segment_id, member_id) rows as
-- removing the relational segment itself does not remove members from the
-- group with that rel_type.  This was intentional on the part of the aD folks
-- who added relational segments to ACS 4.2.

create or replace trigger rel_segments_in_tr after insert on rel_segments
for each row
begin
  insert into party_approved_member_map
    (party_id, member_id, cnt)
  select :new.segment_id, element_id, 1
    from group_element_index
    where group_id = :new.group_id
      and rel_type = :new.rel_type;
end rel_segments_in_tr;
/
show errors;

create or replace trigger rel_segments_del_tr before delete on rel_segments
for each row
begin
  delete from party_approved_member_map
  where party_id = :old.segment_id
    and member_id in (select element_id
                      from group_element_index
                      where group_id = :old.group_id
                        and rel_type = :old.rel_type);
end parties_del_tr;
/
show errors;

-- DRB: Helper functions to maintain the materialized party_approved_member_map.  The counting crap
-- has to do with the fact that composition rels create duplicate rows in groups.

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

create or replace trigger membership_rels_up_tr
before update on membership_rels
for each row
begin
  
  if :new.member_state = :old.member_state then
    return;
  end if;

  for map in (select group_id, element_id, rel_type
              from group_element_index
              where rel_id = :new.rel_id)
  loop
    if :new.member_state = 'approved' then
      party_approved_member.add(map.group_id, map.element_id, map.rel_type);
    else
      party_approved_member.remove(map.group_id, map.element_id, map.rel_type);
    end if;
  end loop;

end;
/
show errors

create or replace trigger membership_rels_in_tr
after insert on membership_rels
for each row
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error varchar2(4000);
begin
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint.violation(:new.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  select object_id_one, object_id_two, rel_type
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels
  where rel_id = :new.rel_id;

  -- Insert a row for me in the group_member_index.
  insert into group_element_index
   (group_id, element_id, rel_id, container_id, 
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, :new.rel_id, v_object_id_one, 
    v_rel_type, 'membership_rel');

  if :new.member_state = 'approved' then
    party_approved_member.add(v_object_id_one, v_object_id_two, v_rel_type);
  end if;

  -- For all groups of which I am a component, insert a
  -- row in the group_member_index.
  for map in (select distinct group_id
	      from group_component_map
	      where component_id = v_object_id_one) loop
    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    values
     (map.group_id, v_object_id_two, :new.rel_id, v_object_id_one,
      v_rel_type, 'membership_rel');

    if :new.member_state = 'approved' then
      party_approved_member.add(map.group_id, v_object_id_two, v_rel_type);
    end if;

  end loop;
end;
/
show errors

create or replace trigger membership_rels_del_tr
before delete on membership_rels
for each row
declare 
  v_error varchar2(4000);
begin
  -- First check if removing this relation would violate any relational constraints
  v_error := rel_constraint.violation_if_removed(:old.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  for map in (select group_id, element_id, rel_type
              from group_element_index
              where rel_id = :old.rel_id)
  loop
    party_approved_member.remove(map.group_id, map.element_id, map.rel_type);
  end loop;

  delete from group_element_index
  where rel_id = :old.rel_id;
end;
/
show errors;

-- New fast version of acs_object_party_privilege_map

create or replace view acs_object_party_privilege_map as
select c.object_id, pdm.descendant as privilege, pamm.member_id as party_id
from acs_object_context_index c, acs_permissions p, acs_privilege_descendant_map pdm,
  party_approved_member_map pamm
where c.ancestor_id = p.object_id
  and pdm.privilege = p.privilege
  and pamm.party_id = p.grantee_id;

-- Kept to avoid breaking existing code, should eventually go away.

create or replace view all_object_party_privilege_map as
select * from acs_object_party_privilege_map;

create or replace package body acs_permission
as
  procedure grant_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  )
  as
  begin
    insert into acs_permissions
      (object_id, grantee_id, privilege)
    values
      (object_id, grantee_id, privilege);
  exception
    when dup_val_on_index then
      return;
  end grant_permission;
  --
  procedure revoke_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  )
  as
  begin
    delete from acs_permissions
    where object_id = revoke_permission.object_id
    and grantee_id = revoke_permission.grantee_id
    and privilege = revoke_permission.privilege;
  end revoke_permission;

  function permission_p (
    object_id	 acs_objects.object_id%TYPE,
    party_id	 parties.party_id%TYPE,
    privilege	 acs_privileges.privilege%TYPE
  ) return char
  as
    exists_p char(1);
  begin

    select decode(count(*),0,'f','t') into exists_p
    from dual where exists
      (select 1
       from acs_permissions p, party_approved_member_map m,
         acs_object_context_index c, acs_privilege_descendant_map h
       where p.object_id = c.ancestor_id
         and h.descendant = permission_p.privilege
         and c.object_id = permission_p.object_id
         and m.member_id = permission_p.party_id
         and p.privilege = h.privilege
         and p.grantee_id = m.party_id);

    return exists_p;

  end permission_p;

end acs_permission;
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


 procedure delete (
    group_id     in groups.group_id%TYPE
  )
  is
  begin
 
   -- Delete all segments defined for this group
   for row in (select segment_id 
                 from rel_segments 
                where group_id = acs_group.delete.group_id) loop

       rel_segment.delete(row.segment_id);

   end loop;

   -- Delete all the relations of any type to this group
   for row in (select r.rel_id, t.package_name
                 from acs_rels r, acs_object_types t
                where r.rel_type = t.object_type
                  and (r.object_id_one = acs_group.delete.group_id
                       or r.object_id_two = acs_group.delete.group_id)) loop
      execute immediate 'begin ' ||  row.package_name || '.delete(' || row.rel_id || '); end;';
   end loop;
 
   party.delete(group_id);
 end delete;

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
