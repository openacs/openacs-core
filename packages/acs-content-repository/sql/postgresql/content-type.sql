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

--set serveroutput on

create function cr_type_template_map_tr () returns opaque as '
begin

  if new.is_default = ''t'' then
    update
      cr_type_template_map
    set
      is_default = ''f''
    where
      content_type = new.content_type
    and
      use_context = new.use_context
    and 
      template_id <> new.template_id
    and
      is_default = ''t'';
  end if;

  return new;

end;' language 'plpgsql';

create trigger cr_type_template_map_tr before insert on cr_type_template_map
for each row execute procedure cr_type_template_map_tr ();

-- show errors

-- create or replace package body content_type is
-- procedure create_type
create function content_type__create_type (varchar,varchar,varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
  create_type__content_type           alias for $1;  
  create_type__supertype              alias for $2;  
  create_type__pretty_name            alias for $3;  
  create_type__pretty_plural          alias for $4;  
  create_type__table_name             alias for $5;  
  create_type__id_column              alias for $6;  
  create_type__name_method            alias for $7;  
  table_exists                        boolean;       
  v_supertype_table                   acs_object_types.table_name%TYPE;
                                        
begin

 -- create the attribute table if not already created

  select count(*) > 0 into table_exists 
    from pg_class
   where relname = lower(create_type__table_name);

  if NOT table_exists then
    select table_name into v_supertype_table from acs_object_types
      where object_type = create_type__supertype;

    execute ''create table '' || table_name || '' ('' ||
      id_column  || '' integer primary key references '' || 
      v_supertype_table || '')'';
  end if;

  PERFORM acs_object_type__create_type (
    create_type__content_type,
    create_type__pretty_name,
    create_type__pretty_plural,
    create_type__supertype,
    create_type__table_name,
    create_type__id_column,
    null,
    ''f'',
    null,
    create_type__name_method
  );

  PERFORM content_type__refresh_view(create_type__content_type);

  return 0; 
end;' language 'plpgsql';


create function content_type__drop_type (varchar,boolean,boolean)
returns integer as '
declare
  drop_type__content_type           alias for $1;  
  drop_type__drop_children_p        alias for $2;  
  drop_type__drop_table_p           alias for $3;  
  table_exists                      boolean;       
  v_table_name                      varchar;   
  is_subclassed_p                   boolean;      
  child_rec                         record;    
  attr_row                          record;
begin

  -- first we''ll rid ourselves of any dependent child types, if any , along with their
  -- own dependent grandchild types
  select 
    count(*) > 0 into is_subclassed_p 
  from 
    acs_object_types 
  where supertype = drop_type__content_type;

  -- this is weak and will probably break;
  -- to remove grand child types, the process will probably
  -- require some sort of querying for drop_type 
  -- methods within the children''s packages to make
  -- certain there are no additional unanticipated
  -- restraints preventing a clean drop

  if drop_type__drop_children_p and is_subclassed_p then

    for child_rec in select 
                       object_type
                     from 
                       acs_object_types
                     where
                       supertype = drop_type__content_type 
    LOOP
      PERFORM content_type__drop_type(child_rec.object_type, ''t'', ''f'');
    end LOOP;

  end if;

  -- now drop all the attributes related to this type
  for attr_row in select
                    attribute_name
                  from
                    acs_attributes
                  where
                    object_type = drop_type__content_type 
  LOOP
    PERFORM content_type__drop_attribute(drop_type__content_type,
                                         attr_row.attribute_name,
                                         ''f''
    );
  end LOOP;

  -- we''ll remove the associated table if it exists
  select 
    count(*) > 0 into table_exists 
  from 
    user_tables u, acs_object_types objet
  where 
    objet.object_type = drop_type__content_type and
    u.table_name = upper(objet.table_name);

  if table_exists and content_type__drop_table_p then
    select 
      table_name into v_table_name 
    from 
      acs_object_types 
    where
      object_type = drop_type__content_type;
       
    execute ''drop table '' || v_table_name ;
  end if;

  PERFORM acs_object_type__drop_type(drop_type__content_type, ''f'');

return 0; 
end;' language 'plpgsql';


-- function create_attribute
create function content_type__create_attribute (varchar,varchar,varchar,varchar,varchar,integer,varchar,varchar)
returns integer as '
declare
  create_attribute__content_type           alias for $1;  
  create_attribute__attribute_name         alias for $2;  
  create_attribute__datatype               alias for $3;  
  create_attribute__pretty_name            alias for $4;  
  create_attribute__pretty_plural          alias for $5;  
  create_attribute__sort_order             alias for $6;  
  create_attribute__default_value          alias for $7;  
  create_attribute__column_spec            alias for $8;  
  v_attr_id                                acs_attributes.attribute_id%TYPE;
  v_table_name                             acs_object_types.table_name%TYPE;
  v_column_exists                          boolean;       
begin

 -- add the appropriate column to the table
 
 select table_name into v_table_name from acs_object_types
  where object_type = create_attribute__content_type;

 if NOT FOUND then
   raise EXCEPTION ''-20000: Content type % does not exist in content_type.create_attribute'', create_attribute__content_type;
 end if; 

 select count(*) > 0 into v_column_exists 
   from pg_class c, pg_attribute a
  where c.relname = v_table_name
    and c.oid = a.attrelid
    and a.attname = lower(create_attribute__attribute_name);

 if NOT v_column_exists then
   execute ''alter table '' || v_table_name || '' add '' || 
      create_attribute__attribute_name || '' '' 
      || create_attribute__column_spec;
 end if;

 v_attr_id := acs_attribute__create_attribute (
   create_attribute__content_type,
   create_attribute__attribute_name,
   create_attribute__datatype,
   create_attribute__pretty_name,
   create_attribute__pretty_plural,
   null,
   null,
   create_attribute__default_value,
   1,
   1,
   create_attribute__sort_order,
   ''type_specific'',
   ''f''
 );

 PERFORM content_type__refresh_view(create_attribute__content_type);

 return v_attr_id;

end;' language 'plpgsql';


-- procedure drop_attribute
create function content_type__drop_attribute (varchar,varchar,boolean)
returns integer as '
declare
  drop_attribute__content_type           alias for $1;  
  drop_attribute__attribute_name         alias for $2;  
  drop_attribute__drop_column            alias for $3;  
  v_attr_id                              acs_attributes.attribute_id%TYPE;
  v_table                                acs_object_types.table_name%TYPE;
begin

  -- Get attribute information 
  select 
    upper(t.table_name), a.attribute_id 
  into 
    v_table, v_attr_id
  from 
    acs_object_types t, acs_attributes a
  where 
    t.object_type = drop_attribute__content_type
  and 
    a.object_type = drop_attribute__content_type
  and
    a.attribute_name = drop_attribute__attribute_name;
    
  if NOT FOUND then
    raise EXCEPTION ''-20000: Attribute %:% does not exist in content_type.drop_attribute'', content_type, attribute_name;
  end;

  -- Drop the attribute
  PERFORM acs_attribute__drop_attribute(drop_attribute__content_type, 
                                        drop_attribute__attribute_name);

  -- FIXME: postgresql does not support drop column.
  -- Drop the column if neccessary
  if drop_attribute__drop_column then
      execute ''alter table '' || v_table || '' drop column '' ||
	drop_attribute__attribute_name;

--    exception when others then
--      raise_application_error(-20000, ''Unable to drop column '' || 
--       v_table || ''.'' || attribute_name || '' in content_type.drop_attribute'');  
  end if;  

  PERFORM content_type__refresh_view(drop_attribute__content_type);

  return 0; 
end;' language 'plpgsql';


-- procedure register_template
create function content_type__register_template (varchar,integer,varchar,boolean)
returns integer as '
declare
  register_template__content_type           alias for $1;  
  register_template__template_id            alias for $2;  
  register_template__use_context            alias for $3;  
  register_template__is_default             alias for $4;  
  v_template_registered                     boolean;       
begin
  select 
    count(*) > 0 into v_template_registered
  from
    cr_type_template_map
  where
    content_type = register_template__content_type
  and
    use_context =  register_template__use_context
  and
    template_id =  register_template__template_id;

  -- register the template
  if NOT v_template_registered then
    insert into cr_type_template_map (
      template_id, content_type, use_context, is_default
    ) values (
      register_template__template_id, register_template__content_type, 
      register_template__use_context, register_template__is_default
    );

  -- update the registration status of the template
  else

    -- unset the default template before setting this one as the default
    if register_template__is_default then
      update cr_type_template_map
        set is_default = ''f''
        where content_type = register_template__content_type
        and use_context = register_template__use_context;
    end if;

    update cr_type_template_map
      set is_default =    register_template__is_default
      where template_id = register_template__template_id
      and content_type =  register_template__content_type
      and use_context =   register_template__use_context;
  end if;

  return 0; 
end;' language 'plpgsql';


-- procedure set_default_template
create function content_type__set_default_template (varchar,integer,varchar)
returns integer as '
declare
  set_default_template__content_type           alias for $1;  
  set_default_template__template_id            alias for $2;  
  set_default_template__use_context            alias for $3;  
                                        
begin

  update cr_type_template_map
    set is_default = ''t''
    where template_id = set_default_template__template_id
    and content_type = set_default_template__content_type
    and use_context = set_default_template__use_context;

  -- make sure there is only one default template for
  --   any given content_type/use_context pair
  update cr_type_template_map
    set is_default = ''f''
    where template_id <> set_default_template__template_id
    and content_type = set_default_template__content_type
    and use_context = set_default_template__use_context
    and is_default = ''t'';

  return 0; 
end;' language 'plpgsql';


-- function get_template
create function content_type__get_template (varchar,varchar)
returns integer as '
declare
  get_template__content_type           alias for $1;  
  get_template__use_context            alias for $2;  
  v_template_id                        cr_templates.template_id%TYPE;
begin
  select
    template_id
  into
    v_template_id
  from
    cr_type_template_map
  where
    content_type = get_template__content_type
  and
    use_context = get_template__use_context
  and
    is_default = ''t'';

  if NOT FOUND then 
     return null;
  else
     return v_template_id;
  end if;
 
end;' language 'plpgsql';


-- procedure unregister_template
create function content_type__unregister_template (varchar,integer,varchar)
returns integer as '
declare
  unregister_template__content_type           alias for $1;  
  unregister_template__template_id            alias for $2;  
  unregister_template__use_context            alias for $3;  
begin

  if unregister_template__use_context is null and 
     unregister_template__content_type is null then

    delete from cr_type_template_map
      where template_id = unregister_template__template_id;

  else if unregister_template__use_context is null then

    delete from cr_type_template_map
      where template_id = unregister_template__template_id
      and content_type = unregister_template__content_type;

  else if unregister_template__content_type is null then

    delete from cr_type_template_map
      where template_id = unregister_template__template_id
      and use_context = unregister_template__use_context;

  else

    delete from cr_type_template_map
      where template_id = unregister_template__template_id
      and content_type = unregister_template__content_type
      and use_context = unregister_template__use_context;

  end if; end if; end if;

  return 0; 
end;' language 'plpgsql';


-- function trigger_insert_statement
create function content_type__trigger_insert_statement (varchar)
returns varchar as '
declare
  trigger_insert_statement__content_type   alias for $1;  
  v_table_name                             acs_object_types.table_name%TYPE;
  v_id_column                              acs_object_types.id_column%TYPE;
  cols                                     varchar default '''';
  vals                                     varchar default '''';
  attr_cur                                 record;
begin

  select table_name, id_column into v_table_name, v_id_column
  from acs_object_types where 
    object_type = trigger_insert_statement__content_type;

  for attr_rec in select
                    attribute_name
                  from
                    acs_attributes
                  where
                    object_type = trigger_insert_statement__content_type 
  LOOP
    cols := cols || '', '' || attr_rec.attribute_name;
    vals := vals || '', new.'' || attr_rec.attribute_name;
  end LOOP;

  return ''insert into '' || v_table_name || 
    '' ( '' || v_id_column || cols || '' ) values ( new_revision_id'' ||
    vals || '')'';
  
end;' language 'plpgsql';

-- FIXME: need to look at this in more detail.  This probably can't be made 
-- to work reliably in postgresql.

-- Create or replace a trigger on insert for simplifying addition of
-- revisions for any content type

-- procedure refresh_trigger
create function content_type__refresh_trigger (varchar)
returns integer as '
declare
  refresh_trigger__content_type           alias for $1;  
  tr_text                                 text default '''';
  v_table_name                            acs_object_types.table_name%TYPE;
  type_rec                                record;
begin

  -- get the table name for the content type (determines view name)

  select table_name into v_table_name
  from acs_object_types where object_type = refresh_trigger__content_type;

  -- start building trigger code

  tr_text := ''

create function '' || v_table_name || ''t()  returns opaque as \\\'
declare
  new_revision_id integer;
begin

  if new.item_id is null then
    raise EXCEPTION \\\'\\\'-20000: item_id is required when inserting into %i \\\'\\\', v_table_name;
  end if;

  if new.text is not null then

    new_revision_id := content_revision__new(
                   new.title,
                   new.description,
                   now(),
                   new.mime_type,
                   new.nls_language,
                   new.data,
                   content_symlink__resolve(new.item_id),
                   new.revision_id,
                   now(),
                   new.creation_user, 
                   new.creation_ip
    );

  else

    new_revision_id := content_revision__new(
                   new.title,
                   new.description,
                   now(),
                   new.mime_type,
                   new.nls_language,
                   new.data,
                   content_symlink__resolve(new.item_id),
                   new.revision_id,
                   now(),
                   new.creation_user, 
                   new.creation_ip
    );

  end if;'';

  -- add an insert statement for each subtype in the hierarchy for this type

  for type_rec in select                                                
                    object_type
                  from                                                
                    acs_object_types                                  
                  where                                               
                    object_type <> ''acs_object''                       
                  and                                                 
                    object_type <> ''content_revision''                 
                  connect by                                          
                    prior supertype = object_type                     
                  start with                                          
                    object_type = refresh_trigger.content_type
                  order by
                    level desc
  LOOP
    tr_text := tr_text || ''
'' || content_type__trigger_insert_statement(type_rec.object_type) || '';
  end loop;

  -- end building the trigger code
  tr_text := tr_text || ''
end;\\\' language \\\'plpgsql\\\';
create trigger '' || v_table_name || ''t before insert on '' || v_table_name || ''i for each row execute procedure '' || v_table_name || ''t()'';

  -- (Re)create the trigger
  execute tr_text;

  return 0; 
end;' language 'plpgsql';


-- procedure refresh_view
create function content_type__refresh_view (varchar)
returns integer as '
declare
  refresh_view__content_type           alias for $1;  
  cols                                 varchar; 
  tabs                                 varchar; 
  joins                                varchar;
  v_table_name                         varchar;
  join_rec                             record;
begin

  for join_rec in select
                    table_name, id_column, level
                  from
                    acs_object_types
                  where
                    object_type <> 'acs_object'
                  and
                    object_type <> 'content_revision'
                  start with
                    object_type = refresh_view__content_type
                  connect by
                    object_type = prior supertype 
  LOOP
    cols := cols || '', '' || join_rec.table_name || ''.*'';
    tabs := tabs || '', '' || join_rec.table_name;
    joins := joins || '' and acs_objects.object_id = '' || 
             join_rec.table_name || ''.'' || join_rec.id_column;
  end loop;

  select table_name into v_table_name from acs_object_types
    where object_type = refresh_view__content_type;

  -- create the input view (includes content columns)

  execute ''create view '' || v_table_name ||
    ''i as select acs_objects.*, cr.revision_id, cr.title, cr.item_id,
    content_revision__get_content(cr.revision_id) as data, cr_text.text,
    cr.description, cr.publish_date, cr.mime_type, cr.nls_language'' || 
    cols || 
    '' from acs_objects, cr_revisions cr, cr_text'' || tabs || '' where 
    acs_objects.object_id = cr.revision_id '' || joins;

  -- create the output view (excludes content columns to enable SELECT *)

  execute ''create view '' || v_table_name ||
    ''x as select acs_objects.*, cr.revision_id, cr.title, cr.item_id,
    cr.description, cr.publish_date, cr.mime_type, cr.nls_language,
    i.name, i.parent_id'' || 
    cols || 
    '' from acs_objects, cr_revisions cr, cr_items i, cr_text'' || tabs || 
    '' where acs_objects.object_id = cr.revision_id 
      and cr.item_id = i.item_id'' || joins;

  PERFORM content_type__refresh_trigger(refresh_view__content_type);

-- exception
--   when others then
--     dbms_output.put_line(''Error creating attribute view or trigger for''
--  || content_type);

  return 0; 
end;' language 'plpgsql';


-- procedure register_child_type
create function content_type__register_child_type (varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  register_child_type__parent_type            alias for $1;  
  register_child_type__child_type             alias for $2;  
  register_child_type__relation_tag           alias for $3;  
  register_child_type__min_n                  alias for $4;  
  register_child_type__max_n                  alias for $5;
  v_exists                                    integer;
begin

  select count(*) into v_exists 
    from cr_type_children
    where parent_type = register_child_type__parent_type
    and child_type = register_child_type__child_type;

  if v_exists = 0 then

    insert into cr_type_children (
      parent_type, child_type, relation_tag, min_n, max_n
    ) values (
      register_child_type__parent_type, register_child_type__child_type, 
      register_child_type__relation_tag, register_child_type__min_n, 
      register_child_type__max_n
    );

  else

    update cr_type_children set
      min_n = register_child_type__min_n,
      max_n = register_child_type__max_n
    where 
      parent_type = register_child_type__parent_type
    and 
      child_type = register_child_type__child_type
    and
      relation_tag = register_child_type__relation_tag;

  end if;
      
  return 0; 
end;' language 'plpgsql';


-- procedure unregister_child_type
create function content_type__unregister_child_type (varchar,varchar,varchar)
returns integer as '
declare
  unregister_child_type__parent_type            alias for $1;  
  unregister_child_type__child_type             alias for $2;  
  unregister_child_type__relation_tag           alias for $3;  
                                        
begin

  delete from 
    cr_type_children
  where 
    parent_type = unregister_child_type__parent_type
  and 
    child_type = unregister_child_type__child_type
  and
    relation_tag = unregister_child_type__relation_tag;

  return 0; 
end;' language 'plpgsql';


-- procedure register_relation_type
create function content_type__register_relation_type (varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  register_relation_type__content_type           alias for $1;  
  register_relation_type__target_type            alias for $2;  
  register_relation_type__relation_tag           alias for $3;  
  register_relation_type__min_n                  alias for $4;  
  register_relation_type__max_n                  alias for $5;  
  v_exists                                       integer;       
begin

  -- check if the relation type exists
  select 
    count(*) into v_exists 
  from 
    cr_type_relations
  where 
    content_type = register_relation_type__content_type
  and
    target_type = register_relation_type__target_type
  and 
    relation_tag = register_relation_type__relation_tag;

  -- if the relation type does not exist, insert a row into cr_type_relations
  if v_exists = 0 then
    insert into cr_type_relations (
      content_type, target_type, relation_tag, min_n, max_n
    ) values (
      register_relation_type__content_type, 
      register_relation_type__target_type, 
      register_relation_type__relation_tag, 
      register_relation_type__min_n, register_relation_type__max_n
    );

  -- otherwise, update the row in cr_type_relations
  else
    update cr_type_relations set
      min_n = register_relation_type__min_n,
      max_n = register_relation_type__max_n
    where 
      content_type = register_relation_type__content_type
    and 
      target_type = register_relation_type__target_type
    and
      relation_tag = register_relation_type__relation_tag;
  end if;

  return 0; 
end;' language 'plpgsql';


-- procedure unregister_relation_type
create function content_type__unregister_relation_type (varchar,varchar,varchar)
returns integer as '
declare
  unregister_relation_type__content_type           alias for $1;  
  unregister_relation_type__target_type            alias for $2;  
  unregister_relation_type__relation_tag           alias for $3;  
                                        
begin

  delete from 
    cr_type_relations
  where 
    content_type = unregister_relation_type__content_type
  and 
    target_type = unregister_relation_type__target_type
  and
    relation_tag = unregister_relation_type__relation_tag;

  return 0; 
end;' language 'plpgsql';


-- procedure register_mime_type
create function content_type__register_mime_type (varchar,varchar)
returns integer as '
declare
  register_mime_type__content_type           alias for $1;  
  register_mime_type__mime_type              alias for $2;  
  v_valid_registration                       integer;       
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
                   mime_type = register_mime_type__mime_type
                 and
                   content_type = register_mime_type__content_type )
  and
    mime_type = register_mime_type__mime_type;

  if v_valid_registration = 1 then    
    insert into cr_content_mime_type_map (
      content_type, mime_type
    ) values (
      register_mime_type__content_type, register_mime_type__mime_type
    );
  end if;

  return 0; 
end;' language 'plpgsql';


-- procedure unregister_mime_type
create function content_type__unregister_mime_type (varchar,varchar)
returns integer as '
declare
  unregister_mime_type__content_type           alias for $1;  
  unregister_mime_type__mime_type              alias for $2;  
begin

  delete from cr_content_mime_type_map
    where content_type = unregister_mime_type__content_type
    and mime_type = unregister_mime_type__mime_type;

  return 0; 
end;' language 'plpgsql';


-- function is_content_type
create function content_type__is_content_type (varchar)
returns boolean as '
declare
  is_content_type__object_type            alias for $1;  
  v_is_content_type                       boolean       
begin

  if is_content_type__object_type = ''content_revision'' then

    v_is_content_type := ''t'';

  else    
    select count(*) > 0 into v_is_content_type
    from acs_object_type_supertype_map
    where object_type = is_content_type__object_type 
    and ancestor_type = ''content_revision'';
  end if;
  
  return v_is_content_type;
 
end;' language 'plpgsql';


-- procedure rotate_template
create function content_type__rotate_template (integer,varchar,varchar)
returns integer as '
declare
  rotate_template__template_id            alias for $1;  
  rotate_template__v_content_type         alias for $2;  
  rotate_template__use_context            alias for $3;  
  v_template_id                           cr_templates.template_id%TYPE;
  v_items_val                             record;
begin

  -- get the default template
  select
    template_id into v_template_id
  from
    cr_type_template_map
  where
    content_type = rotate_template__v_content_type
  and
    use_context = rotate_template__use_context
  and
    is_default = ''t'';

  if v_template_id is not null then

    -- register an item-template to all items without an item-template
    for v_items_val in select
                         item_id
                       from
                         cr_items i, cr_type_template_map m
                       where
                         i.content_type = rotate_template__v_content_type
                       and
                         m.use_context = rotate_template__use_context
                       and
                         i.content_type = m.content_type
                       and
                         not exists ( select 1
                                        from
                                          cr_item_template_map
                                        where
                                          item_id = i.item_id
                                        and
                                          use_context = rotate_template__use_context ) 
    LOOP
      PERFORM content_item__register_template ( 
         v_items_val.item_id, 
         v_template_id,
         rotate_template__use_context
      );
    end loop;
  end if;

  -- register the new template as the default template of the content type
  if v_template_id != rotate_template__template_id then
    content_type__register_template(
        rotate_template__v_content_type,
        rotate_template__template_id,
        rotate_template__use_context,
        ''t''
    );
  end if;

  return 0; 
end;' language 'plpgsql';



-- show errors

-- Refresh the attribute views

-- prompt *** Refreshing content type attribute views...

create function inline_0 ()
returns integer as '
declare 
        type_rec        record;
begin

  for type_rec in select object_type 
                   from acs_object_types 
                   connect by supertype = prior object_type 
                   start with object_type = ''content_revision'' 
  LOOP
    PERFORM content_type__refresh_view (type_rec.object_type);
  end LOOP;

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

