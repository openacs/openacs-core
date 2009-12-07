-- Data model to support content repository of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Authors:      Michael Pih (pihman@arsdigita.com)
--               Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- Create a trigger to make sure that there will never be more than
-- one default template for a given content type and use context

set serveroutput on

create or replace trigger cr_type_template_map_tr
before insert on cr_type_template_map 
for each row
begin

  if :new.is_default = 't' then
    update
      cr_type_template_map
    set
      is_default = 'f'
    where
      content_type = :new.content_type
    and
      use_context = :new.use_context
    and 
      template_id ^= :new.template_id
    and
      is_default = 't';
  end if;

  return;
end cr_type_template_map_tr;
/
show errors

create or replace package body content_type is

procedure create_type (
    content_type	in acs_object_types.object_type%TYPE,
    supertype		in acs_object_types.object_type%TYPE 
                           default 'content_revision',
    pretty_name		in acs_object_types.pretty_name%TYPE,
    pretty_plural	in acs_object_types.pretty_plural%TYPE,
    table_name		in acs_object_types.table_name%TYPE default null,
    id_column		in acs_object_types.id_column%TYPE default 'XXX',
    name_method           in acs_object_types.name_method%TYPE default null
) is

  table_exists integer;
  v_supertype_table acs_object_types.table_name%TYPE;
  v_count       integer;
begin

  if (supertype != 'content_revision') and (content_type != 'content_revision') then
    select count(*)
    into  v_count
    from  acs_object_type_supertype_map
    where object_type = create_type.supertype
    and   ancestor_type = 'content_revision';

    if v_count = 0 then
        raise_application_error(-20000, 'Content types can only be created as subclasses of content_revision or a derivation thereof. ' || supertype || ' is not a subclass oc content_revision.');
    end if;
  end if;


 -- create the attribute table if not already created

  select decode(count(*),0,0,1) into table_exists from user_tables 
    where table_name = upper(create_type.table_name);

  if table_exists = 0 and create_type.table_name is not null then
    select table_name into v_supertype_table from acs_object_types
      where object_type = create_type.supertype;

    execute immediate 'create table ' || table_name || ' (' ||
      id_column  || ' integer primary key references ' || 
      v_supertype_table || ')';
  end if;

  acs_object_type.create_type (
    supertype     => create_type.supertype,
    object_type   => create_type.content_type,
    pretty_name   => create_type.pretty_name,
    pretty_plural => create_type.pretty_plural,
    table_name    => create_type.table_name,
    id_column     => create_type.id_column,
    name_method   => create_type.name_method
  );

  refresh_view(content_type);

end create_type;

procedure drop_type (
  content_type		in acs_object_types.object_type%TYPE,
  drop_children_p	in char default 'f',
  drop_table_p		in char default 'f',
  drop_objects_p		in char default 'f'
) is


  cursor attribute_cur is
    select
      attribute_name
    from
      acs_attributes
    where
      object_type = drop_type.content_type;

  cursor child_type_cur is 
    select 
      object_type
    from 
      acs_object_types
    where
      supertype = drop_type.content_type;
 
  cursor revision_cur is
      select revision_id 
      from cr_revisions, acs_objects
      where revision_id = object_id
      and object_type = drop_type.content_type;

  cursor item_cur is 
      select item_id 
      from cr_items
      where content_type = drop_type.content_type;
   
  table_exists integer;
  v_table_name varchar2(50);
  is_subclassed_p char;

 
begin


  -- first we'll rid ourselves of any dependent child types, if any , along with their
  -- own dependent grandchild types
  select 
    decode(count(*),0,'f','t') into is_subclassed_p 
  from 
    acs_object_types 
  where supertype = drop_type.content_type;

  -- this is weak and will probably break;
  -- to remove grand child types, the process will probably
  -- require some sort of querying for drop_type 
  -- methods within the children's packages to make
  -- certain there are no additional unanticipated
  -- restraints preventing a clean drop

  if drop_children_p = 't' and is_subclassed_p = 't' then

    for child_rec in child_type_cur loop
      drop_type( 
        content_type => child_rec.object_type,
	drop_children_p => 't',
	drop_table_p => drop_table_p,
	drop_objects_p => drop_objects_p );
    end loop;

  end if;

  -- now drop all the attributes related to this type
  for attr_row in attribute_cur loop
    drop_attribute(
     content_type => drop_type.content_type,
      attribute_name => attr_row.attribute_name
    );
  end loop;

  -- we'll remove the associated table if it exists
  select 
    decode(count(*),0,0,1) into table_exists 
  from 
    user_tables u, acs_object_types objet
  where 
    objet.object_type = drop_type.content_type and
    u.table_name = upper(objet.table_name);

  if table_exists = 1 and drop_table_p = 't' then
    select 
      nvl(table_name,object_type) into v_table_name 
    from 
      acs_object_types 
    where
      object_type = drop_type.content_type;

    -- drop the input/output views for the type
    -- being dropped.
    -- FIXME: does the trigger get dropped when the 
    -- view is dropped?  This did not exist in the 4.2 release,
    -- and it needs to be tested.

       
    execute immediate 'drop view ' || v_table_name || 'x';
    execute immediate 'drop view ' || v_table_name || 'i';

    execute immediate 'drop table ' || v_table_name;

  end if;

  if drop_objects_p = 't' then
    for revision_row in revision_cur loop
      content_revision.del( 
        revision_id => revision_row.revision_id
      );
    end loop;
    for item_row in item_cur loop
      content_item.del( 
        item_id => item_row.item_id
      );
    end loop;
  end if;

  acs_object_type.drop_type(
    object_type   => drop_type.content_type
  );
end drop_type;

function create_attribute (
  content_type		in acs_attributes.object_type%TYPE,
  attribute_name	in acs_attributes.attribute_name%TYPE,
  datatype		in acs_attributes.datatype%TYPE,
  pretty_name		in acs_attributes.pretty_name%TYPE,
  pretty_plural		in acs_attributes.pretty_plural%TYPE default null,
  sort_order		in acs_attributes.sort_order%TYPE default null,
  default_value		in acs_attributes.default_value%TYPE default null,
  column_spec           in varchar2 default 'varchar2(4000)'
) return acs_attributes.attribute_id%TYPE is

   v_attr_id	acs_attributes.attribute_id%TYPE;
   v_table_name acs_object_types.table_name%TYPE;
   v_column_exists integer;

begin

 -- add the appropriate column to the table
 begin
   select upper(table_name) into v_table_name from acs_object_types
     where object_type = create_attribute.content_type;
 exception when no_data_found then
   raise_application_error(-20000, 'Content type ''' || content_type || 
      ''' does not exist in content_type.create_attribute');
 end;

 select decode(count(*),0,0,1) into v_column_exists from user_tab_columns
   where table_name = v_table_name
   and column_name = upper(attribute_name);

 if v_column_exists = 0 then
   execute immediate 'alter table ' || v_table_name || ' add ' || 
      attribute_name || ' ' || column_spec;
 end if;

 v_attr_id := acs_attribute.create_attribute (
   object_type => create_attribute.content_type,
   attribute_name => create_attribute.attribute_name,
   datatype => create_attribute.datatype,
   pretty_name => create_attribute.pretty_name,
   pretty_plural => create_attribute.pretty_plural,
   sort_order => create_attribute.sort_order,
   default_value => create_attribute.default_value
 );

 refresh_view(content_type);

 return v_attr_id;

end create_attribute;


procedure drop_attribute (
  content_type		in acs_attributes.object_type%TYPE,
  attribute_name	in acs_attributes.attribute_name%TYPE,
  drop_column           in varchar2 default 'f'
)
is
   v_attr_id acs_attributes.attribute_id%TYPE;
   v_table   acs_object_types.table_name%TYPE;
begin

  -- Get attribute information 
  begin
    select 
      upper(t.table_name), a.attribute_id 
    into 
      v_table, v_attr_id
    from 
      acs_object_types t, acs_attributes a
    where 
      t.object_type = drop_attribute.content_type
    and 
      a.object_type = drop_attribute.content_type
    and
      a.attribute_name = drop_attribute.attribute_name;
  exception when no_data_found then
    raise_application_error(-20000, 'Attribute ' || content_type || ':' || 
       attribute_name || ' does not exist in content_type.drop_attribute');
  end;

  -- Drop the attribute
  acs_attribute.drop_attribute(content_type, attribute_name);

  -- Drop the column if neccessary
  if drop_column = 't' then
    begin
      execute immediate 'alter table ' || v_table || ' drop column ' ||
	attribute_name;
    exception when others then
      raise_application_error(-20000, 'Unable to drop column ' || 
       v_table || '.' || attribute_name || ' in content_type.drop_attribute');  
    end;
  end if;  

  refresh_view(content_type);

end drop_attribute;

procedure register_template (
  content_type  in cr_type_template_map.content_type%TYPE,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE,
  is_default	in cr_type_template_map.is_default%TYPE default 'f'
) is
  v_template_registered integer;
begin
  select 
    count(*) into v_template_registered
  from
    cr_type_template_map
  where
    content_type = register_template.content_type
  and
    use_context =  register_template.use_context
  and
    template_id =  register_template.template_id;

  -- register the template
  if v_template_registered = 0 then
    insert into cr_type_template_map (
      template_id, content_type, use_context, is_default
    ) values (
      template_id, content_type, use_context, is_default
    );

  -- update the registration status of the template
  else

    -- unset the default template before setting this one as the default
    if register_template.is_default = 't' then
      update cr_type_template_map
        set is_default = 'f'
        where content_type = register_template.content_type
        and use_context = register_template.use_context;
    end if;

    update cr_type_template_map
      set is_default =    register_template.is_default
      where template_id = register_template.template_id
      and content_type =  register_template.content_type
      and use_context =   register_template.use_context;

  end if;
end register_template;


procedure set_default_template (
  content_type  in cr_type_template_map.content_type%TYPE,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE
) is

begin

  update cr_type_template_map
    set is_default = 't'
    where template_id = set_default_template.template_id
    and content_type = set_default_template.content_type
    and use_context = set_default_template.use_context;

  -- make sure there is only one default template for
  --   any given content_type/use_context pair
  update cr_type_template_map
    set is_default = 'f'
    where template_id ^= set_default_template.template_id
    and content_type = set_default_template.content_type
    and use_context = set_default_template.use_context
    and is_default = 't';

end set_default_template;

function get_template (
  content_type  in cr_type_template_map.content_type%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE
) return cr_templates.template_id%TYPE
is
  v_template_id cr_templates.template_id%TYPE;
begin
  select
    template_id
  into
    v_template_id
  from
    cr_type_template_map
  where
    content_type = get_template.content_type
  and
    use_context = get_template.use_context
  and
    is_default = 't';

  return v_template_id;

exception
  when NO_DATA_FOUND then 
    return null;
end get_template;

procedure unregister_template (
  content_type  in cr_type_template_map.content_type%TYPE default null,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE default null
) is
begin

  if unregister_template.use_context is null and 
     unregister_template.content_type is null then

    delete from cr_type_template_map
      where template_id = unregister_template.template_id;

  elsif unregister_template.use_context is null then

    delete from cr_type_template_map
      where template_id = unregister_template.template_id
      and content_type = unregister_template.content_type;

  elsif unregister_template.content_type is null then

    delete from cr_type_template_map
      where template_id = unregister_template.template_id
      and use_context = unregister_template.use_context;

  else

    delete from cr_type_template_map
      where template_id = unregister_template.template_id
      and content_type = unregister_template.content_type
      and use_context = unregister_template.use_context;

  end if;

end unregister_template;

-- Helper function for refresh_trigger (below) to generate the
-- insert statement for a particular content type;

function trigger_insert_statement (
  content_type  in acs_object_types.object_type%TYPE
) return varchar2 is

  v_table_name acs_object_types.table_name%TYPE;
  v_id_column acs_object_types.id_column%TYPE;

  cursor attr_cur is
    select
      attribute_name
    from
      acs_attributes
    where
      object_type = trigger_insert_statement.content_type;

  cols varchar2(2000) := '';
  vals varchar2(2000) := '';

begin

  select table_name, id_column into v_table_name, v_id_column
  from acs_object_types where 
    object_type = trigger_insert_statement.content_type;

  for attr_rec in attr_cur loop
    cols := cols || ', ' || attr_rec.attribute_name;
    vals := vals || ', :new.' || attr_rec.attribute_name;
  end loop;

  return 'insert into ' || v_table_name || 
    ' ( ' || v_id_column || cols || ' ) values ( new_revision_id' ||
    vals || ')';
  
end trigger_insert_statement;

-- Create or replace a trigger on insert for simplifying addition of
-- revisions for any content type

procedure refresh_trigger (
  content_type  in acs_object_types.object_type%TYPE
) is

  tr_text varchar2(10000) := '';
  v_table_name acs_object_types.table_name%TYPE;

  cursor type_cur is
    select                                                
      object_type
    from                                                
      acs_object_types                                  
    where                                               
      object_type ^= 'acs_object'                       
    and                                                 
      object_type ^= 'content_revision'
    and table_name is not null
    connect by                                          
      prior supertype = object_type                     
    start with                                          
      object_type = refresh_trigger.content_type
    order by
      level desc;

begin

  -- get the table name for the content type (determines view name)

  select nvl(table_name,object_type) into v_table_name
  from acs_object_types where object_type = refresh_trigger.content_type;

  -- start building trigger code

  tr_text := '

create or replace trigger ' || v_table_name || 't 
  instead of insert on ' || v_table_name || 'i 
  for each row 
declare
  new_revision_id integer;
begin

  if :new.item_id is null then
    raise_application_error(-20000, ''item_id is required when inserting into ' || 
    v_table_name || 'i '');
  end if;

  if :new.text is not null then

    new_revision_id := content_revision.new(
                   revision_id   => :new.revision_id,
                   title         => :new.title,
                   description   => :new.description,
                   mime_type     => :new.mime_type,
                   nls_language  => :new.nls_language,
                   item_id       => content_symlink.resolve(:new.item_id),
                   creation_ip   => :new.creation_ip,
                   creation_user => :new.creation_user, 
                   text          => :new.text,
                   package_id    => :new.object_package_id
    );

  else

    new_revision_id := content_revision.new(
                   revision_id   => :new.revision_id,
                   title         => :new.title,
                   description   => :new.description,
                   mime_type     => :new.mime_type,
                   nls_language  => :new.nls_language,
                   item_id       => content_symlink.resolve(:new.item_id),
                   creation_ip   => :new.creation_ip,
                   creation_user => :new.creation_user, 
                   data          => :new.data,
                   package_id    => :new.object_package_id
    );

  end if;';

  -- add an insert statement for each subtype in the hierarchy for this type

  for type_rec in type_cur loop
    tr_text := tr_text || '
' || trigger_insert_statement(type_rec.object_type) || ';
';

  end loop;

  -- end building the trigger code
  tr_text := tr_text || '
end ' || v_table_name || 't;';

  -- (Re)create the trigger
  execute immediate tr_text;

end refresh_trigger;

-- Create or replace a view joining all attribute tables

procedure refresh_view (
  content_type  in cr_type_template_map.content_type%TYPE
) is

  -- exclude the BLOB column because it will make it impossible
  -- to do a select *

  cursor join_cur is
    select
      distinct lower(table_name) as table_name,
      id_column, level
    from
      acs_object_types
    where
      object_type <> 'acs_object'
    and
      object_type <> 'content_revision'
    and lower(table_name) <> 'acs_objects'
    and lower(table_name) <> 'cr_revisions'
    start with
      object_type = refresh_view.content_type
    connect by
      object_type = prior supertype;

  cols varchar2(1000);
  tabs varchar2(1000);
  joins varchar2(1000) := '';
 
  v_table_name varchar2(40);

begin

  for join_rec in join_cur loop

    cols := cols || ', ' || join_rec.table_name || '.*';
    tabs := tabs || ', ' || join_rec.table_name;
    joins := joins || ' and acs_objects.object_id = ' || 
             join_rec.table_name || '.' || join_rec.id_column;

  end loop;

  select nvl(table_name,object_type) into v_table_name from acs_object_types
    where object_type = content_type;

  -- create the input view (includes content columns)

  execute immediate 'create or replace view ' || v_table_name ||
    'i as select acs_objects.object_id,
 acs_objects.object_type,
 acs_objects.title as object_title,
 acs_objects.package_id as object_package_id,
 acs_objects.context_id,
 acs_objects.security_inherit_p,
 acs_objects.creation_user,
 acs_objects.creation_date,
 acs_objects.creation_ip,
 acs_objects.last_modified,
 acs_objects.modifying_user,
 acs_objects.modifying_ip,
 cr.revision_id, cr.title, cr.item_id,
    cr.content as data, cr_text.text,
    cr.description, cr.publish_date, cr.mime_type, cr.nls_language' || 
    cols || 
    ' from acs_objects, cr_revisions cr, cr_text' || tabs || ' where 
    acs_objects.object_id = cr.revision_id ' || joins;

  -- create the output view (excludes content columns to enable SELECT *)

  execute immediate 'create or replace view ' || v_table_name ||
    'x as select acs_objects.object_id,
 acs_objects.object_type,
 acs_objects.title as object_title,
 acs_objects.package_id as object_package_id,
 acs_objects.context_id,
 acs_objects.security_inherit_p,
 acs_objects.creation_user,
 acs_objects.creation_date,
 acs_objects.creation_ip,
 acs_objects.last_modified,
 acs_objects.modifying_user,
 acs_objects.modifying_ip,
 cr.revision_id, cr.title, cr.item_id,
    cr.description, cr.publish_date, cr.mime_type, cr.nls_language,
    i.name, i.parent_id' || 
    cols || 
    ' from acs_objects, cr_revisions cr, cr_items i, cr_text' || tabs || 
    ' where acs_objects.object_id = cr.revision_id 
      and cr.item_id = i.item_id' || joins;

  refresh_trigger(content_type);

exception
  when others then
    dbms_output.put_line('Error creating attribute view or trigger for ' ||
                         content_type);
end refresh_view;

procedure register_child_type (
  parent_type  in cr_type_children.parent_type%TYPE,
  child_type    in cr_type_children.child_type%TYPE,
  relation_tag  in cr_type_children.relation_tag%TYPE default 'generic',
  min_n         in integer default 0,
  max_n         in integer default null
) is

  v_exists integer;

begin

  select decode(count(*),0,0,1) into v_exists 
    from cr_type_children
    where parent_type = register_child_type.parent_type
    and child_type = register_child_type.child_type
    and relation_tag = register_child_type.relation_tag;

  if v_exists = 0 then

    insert into cr_type_children (
      parent_type, child_type, relation_tag, min_n, max_n
    ) values (
      parent_type, child_type, relation_tag, min_n, max_n
    );

  else

    update cr_type_children set
      min_n = register_child_type.min_n,
      max_n = register_child_type.max_n
    where 
      parent_type = register_child_type.parent_type
    and 
      child_type = register_child_type.child_type
    and
      relation_tag = register_child_type.relation_tag;

  end if;
      
end register_child_type;

procedure unregister_child_type (
  parent_type  in cr_type_children.parent_type%TYPE,
  child_type   in cr_type_children.child_type%TYPE,
  relation_tag in cr_type_children.relation_tag%TYPE default null
) is

begin

  delete from 
    cr_type_children
  where 
    parent_type = unregister_child_type.parent_type
  and 
    child_type = unregister_child_type.child_type
  and
    relation_tag = unregister_child_type.relation_tag;

end unregister_child_type;

procedure register_relation_type (
  content_type  in cr_type_relations.content_type%TYPE,
  target_type   in cr_type_relations.target_type%TYPE,
  relation_tag  in cr_type_relations.relation_tag%TYPE default 'generic',
  min_n         in integer default 0,
  max_n         in integer default null
) is
  v_exists integer;
begin

  -- check if the relation type exists
  select 
    decode(count(*),0,0,1) into v_exists 
  from 
    cr_type_relations
  where 
    content_type = register_relation_type.content_type
  and
    target_type = register_relation_type.target_type
  and 
    relation_tag = register_relation_type.relation_tag;

  -- if the relation type does not exist, insert a row into cr_type_relations
  if v_exists = 0 then
    insert into cr_type_relations (
      content_type, target_type, relation_tag, min_n, max_n
    ) values (
      content_type, target_type, relation_tag, min_n, max_n
    );

  -- otherwise, update the row in cr_type_relations
  else
    update cr_type_relations set
      min_n = register_relation_type.min_n,
      max_n = register_relation_type.max_n
    where 
      content_type = register_relation_type.content_type
    and 
      target_type = register_relation_type.target_type
    and
      relation_tag = register_relation_type.relation_tag;

  end if;
end register_relation_type;

procedure unregister_relation_type (
  content_type in cr_type_relations.content_type%TYPE,
  target_type   in cr_type_relations.target_type%TYPE,
  relation_tag in cr_type_relations.relation_tag%TYPE default null
) is

begin

  delete from 
    cr_type_relations
  where 
    content_type = unregister_relation_type.content_type
  and 
    target_type = unregister_relation_type.target_type
  and
    relation_tag = unregister_relation_type.relation_tag;

end unregister_relation_type;

procedure register_mime_type (
  content_type  in cr_content_mime_type_map.content_type%TYPE,
  mime_type	in cr_content_mime_type_map.mime_type%TYPE
) is 
  v_valid_registration  integer;
begin

  -- check if this type is already registered  
  select
    count(*) into v_valid_registration
  from 
    cr_mime_types
  where 
    not exists ( select 1
                 from
	           cr_content_mime_type_map
                 where
                   mime_type = register_mime_type.mime_type
                 and
                   content_type = register_mime_type.content_type )
  and
    mime_type = register_mime_type.mime_type;

  if v_valid_registration = 1 then
    
    insert into cr_content_mime_type_map (
      content_type, mime_type
    ) values (
      register_mime_type.content_type, register_mime_type.mime_type
    );

  end if;

end register_mime_type;


procedure unregister_mime_type (
  content_type  in cr_content_mime_type_map.content_type%TYPE,
  mime_type	in cr_content_mime_type_map.mime_type%TYPE
) is
begin

  delete from cr_content_mime_type_map
    where content_type = unregister_mime_type.content_type
    and mime_type = unregister_mime_type.mime_type;

end unregister_mime_type;

function is_content_type (
  object_type   in acs_object_types.object_type%TYPE
) return char is

  v_is_content_type char(1) := 'f';

begin

  if object_type = 'content_revision' then

    v_is_content_type := 't';

  else
    
    select decode(count(*),0,'f','t') into v_is_content_type
    from acs_object_type_supertype_map
    where object_type = is_content_type.object_type 
    and ancestor_type = 'content_revision';

  end if;
  
  return v_is_content_type;

end is_content_type;



procedure rotate_template ( 
  template_id       in cr_templates.template_id%TYPE,
  v_content_type    in cr_items.content_type%TYPE,
  use_context       in cr_type_template_map.use_context%TYPE
) is
  v_template_id cr_templates.template_id%TYPE;

  -- items that have an associated default template but not at the item level
  cursor c_items_cursor is
    select
      item_id
    from
      cr_items i, cr_type_template_map m
    where
      i.content_type = rotate_template.v_content_type
    and
      m.use_context = rotate_template.use_context
    and
      i.content_type = m.content_type
    and
      not exists ( select 1
                   from
                     cr_item_template_map
                   where
                     item_id = i.item_id
                   and
                     use_context = rotate_template.use_context );
begin

  -- get the default template
  select
    template_id into v_template_id
  from
    cr_type_template_map
  where
    content_type = rotate_template.v_content_type
  and
    use_context = rotate_template.use_context
  and
    is_default = 't';

  if v_template_id is not null then

    -- register an item-template to all items without an item-template
    for v_items_val in c_items_cursor loop

      content_item.register_template ( 
         item_id     => v_items_val.item_id, 
         template_id => v_template_id,
         use_context => rotate_template.use_context
      );
    end loop;
  end if;

  -- register the new template as the default template of the content type
  if v_template_id ^= rotate_template.template_id then
    content_type.register_template(
        content_type => rotate_template.v_content_type,
        template_id  => rotate_template.template_id,
        use_context  => rotate_template.use_context,
        is_default   => 't'
    );
  end if;

end rotate_template;


end content_type;
/
show errors

-- Refresh the attribute views

prompt *** Refreshing content type attribute views...

begin

  for type_rec in (select object_type from acs_object_types 
    connect by supertype = prior object_type 
    start with object_type = 'content_revision') loop
    content_type.refresh_view(type_rec.object_type);
  end loop;

end;
/
