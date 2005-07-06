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

select define_function_args('content_type__create_type','content_type,supertype;content_revision,pretty_name,pretty_plural,table_name,id_column,name_method');

create or replace function content_type__create_type (varchar,varchar,varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
  create_type__content_type           alias for $1;  
  create_type__supertype              alias for $2;  -- default ''content_revision''  
  create_type__pretty_name            alias for $3;  
  create_type__pretty_plural          alias for $4;  
  create_type__table_name             alias for $5;
  create_type__id_column              alias for $6;  -- default ''XXX''
  create_type__name_method            alias for $7;  -- default null
  v_temp_p                            boolean;       
  v_supertype_table                   acs_object_types.table_name%TYPE;
                                        
begin

  if (create_type__supertype <> ''content_revision'')
      and (create_type__content_type <> ''content_revision'') then
    select count(*) > 0 into v_temp_p
    from  acs_object_type_supertype_map
    where object_type = create_type__supertype
    and ancestor_type = ''content_revision'';

    if not v_temp_p then
      raise EXCEPTION ''-20000: supertype % must be a subtype of content_revision'', create_type__supertype;
    end if;
  end if;

 -- create the attribute table if not already created

  select count(*) > 0 into v_temp_p 
    from pg_class
   where relname = lower(create_type__table_name);

  if NOT v_temp_p and create_type__table_name is not null then
    select table_name into v_supertype_table from acs_object_types
      where object_type = create_type__supertype;

    execute ''create table '' || create_type__table_name || '' ('' ||
      create_type__id_column  || '' integer primary key references '' || 
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

select define_function_args('content_type__drop_type','content_type,drop_children_p;f,drop_table_p;f');

create or replace function content_type__drop_type (varchar,boolean,boolean)
returns integer as '
declare
  drop_type__content_type           alias for $1;  
  drop_type__drop_children_p        alias for $2;  -- default ''f''  
  drop_type__drop_table_p           alias for $3;  -- default ''f''
  table_exists_p                      boolean;       
  v_table_name                      varchar;   
  is_subclassed_p                   boolean;      
  child_rec                         record;    
  attr_row                          record;
begin

  -- first we''ll rid ourselves of any dependent child types, if any , 
  -- along with their own dependent grandchild types

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
    table_exists(lower(table_name)) into table_exists_p
  from 
    acs_object_types
  where 
    object_type = drop_type__content_type;

  if table_exists_p and drop_type__drop_table_p then
    select 
      table_name into v_table_name 
    from 
      acs_object_types 
    where
      object_type = drop_type__content_type;
       
    -- drop the rule and input/output views for the type
    -- being dropped.
    -- FIXME: this did not exist in the oracle code and it needs to be
    -- tested.  Thanks to Vinod Kurup for pointing this out.
    -- The rule dropping might be redundant as the rule might be dropped
    -- when the view is dropped.

    -- different syntax for dropping a rule in 7.2 and 7.3 so check which
    -- version is being used (olah).

    if version() like ''%PostgreSQL 7.2%'' then
      execute ''drop rule '' || v_table_name || ''_r'';
    else
      -- 7.3 syntax
      execute ''drop rule '' || v_table_name || ''_r '' || ''on '' || v_table_name || ''i'';
    end if;

    execute ''drop view '' || v_table_name || ''x'';
    execute ''drop view '' || v_table_name || ''i'';

    execute ''drop table '' || v_table_name;
  end if;

  PERFORM acs_object_type__drop_type(drop_type__content_type, ''f'');

  return 0; 
end;' language 'plpgsql';



select define_function_args('content_type__create_attribute','content_type,attribute_name,datatype,pretty_name,pretty_plural,sort_order,default_value,column_spec;text');

create or replace function content_type__create_attribute (varchar,varchar,varchar,varchar,varchar,integer,varchar,varchar)
returns integer as '
declare
  create_attribute__content_type           alias for $1;  
  create_attribute__attribute_name         alias for $2;  
  create_attribute__datatype               alias for $3;  
  create_attribute__pretty_name            alias for $4;  
  create_attribute__pretty_plural          alias for $5;  -- default null  
  create_attribute__sort_order             alias for $6;  -- default null
  create_attribute__default_value          alias for $7;  -- default null
  create_attribute__column_spec            alias for $8;  -- default ''text''
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
  where c.relname::varchar = v_table_name
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


select define_function_args('content_type__drop_attribute','content_type,attribute_name,drop_column;f');

create or replace function content_type__drop_attribute (varchar,varchar,boolean)
returns integer as '
declare
  drop_attribute__content_type           alias for $1;  
  drop_attribute__attribute_name         alias for $2;  
  drop_attribute__drop_column            alias for $3;  -- default ''f''  
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
    raise EXCEPTION ''-20000: Attribute %:% does not exist in content_type.drop_attribute'', drop_attribute__content_type, drop_attribute__attribute_name;
  end if;

  -- Drop the attribute
  PERFORM acs_attribute__drop_attribute(drop_attribute__content_type, 
                                        drop_attribute__attribute_name);

  -- FIXME: postgresql does not support drop column.
  -- Drop the column if neccessary
  if drop_attribute__drop_column then
      execute ''alter table '' || v_table || '' drop column '' ||
	drop_attribute__attribute_name || '' cascade'';

  end if;  

  PERFORM content_type__refresh_view(drop_attribute__content_type);

  return 0; 
end;' language 'plpgsql';


select define_function_args('content_type__register_template','content_type,template_id,use_context,is_default;f');
create or replace function content_type__register_template (varchar,integer,varchar,boolean)
returns integer as '
declare
  register_template__content_type           alias for $1;  
  register_template__template_id            alias for $2;  
  register_template__use_context            alias for $3;  
  register_template__is_default             alias for $4;  -- default ''f''  
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

select define_function_args('content_type__set_default_template','content_type,template_id,use_context');

create or replace function content_type__set_default_template (varchar,integer,varchar)
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


select define_function_args('content_type__get_template','content_type,use_context');

create or replace function content_type__get_template (varchar,varchar)
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

  return v_template_id;
 
end;' language 'plpgsql' stable strict;


select define_function_args('content_type__unregister_template','content_type,template_id,use_context');

create or replace function content_type__unregister_template (varchar,integer,varchar)
returns integer as '
declare
  unregister_template__content_type           alias for $1;  -- default null  
  unregister_template__template_id            alias for $2; 
  unregister_template__use_context            alias for $3;  -- default null 
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


select define_function_args('content_type__trigger_insert_statement','content_type');

create or replace function content_type__trigger_insert_statement (varchar)
returns varchar as '
declare
  trigger_insert_statement__content_type   alias for $1;  
  v_table_name                             acs_object_types.table_name%TYPE;
  v_id_column                              acs_object_types.id_column%TYPE;
  cols                                     varchar default '''';
  vals                                     varchar default '''';
  attr_rec                                 record;
begin
  if trigger_insert_statement__content_type is null then 
	return exception ''content_type__trigger_insert_statement called with null content_type'';
  end if;

  select 
    table_name, id_column into v_table_name, v_id_column
  from 
    acs_object_types 
  where 
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
    '' ( '' || v_id_column || cols || '' ) values (cr_dummy.val'' ||
    vals || '')'';
  
end;' language 'plpgsql' stable;

-- dummy table provides a target for updates in dynamically generated trigger
-- statements.  If type is cr_revisions then rule would end up having only a 
-- select statement which causes an error to be thrown by the dml command.
-- dml command checks for NS_ROWS result and throws an error if found.  
-- Using a dummy update causes NS_OK to be returned which satisfies the dml
-- result checking.

-- DCW, 2001-06-09

create table cr_dummy (
       val integer
);

insert into cr_dummy (val) values (null);

create function cr_dummy_ins_del_tr () returns opaque as '
begin
        raise exception ''Only updates are allowed on cr_dummy'';
        return null;
end;' language 'plpgsql';

create trigger cr_dummy_ins_del_tr before insert or delete on 
cr_dummy for each row execute procedure cr_dummy_ins_del_tr ();


-- FIXME: need to look at this in more detail.  This probably can't be made 
-- to work reliably in postgresql.  Currently we are using a rule to insert 
-- into the input view when a new content revision is added.  Pg locks the 
-- underlying table when the rule is dropped, so the dropping and recreating
-- of the new content revisons seems like it would be reliable, but the 
-- possiblity of a race condition exists for either the initial creation
-- of dropping of a type.  I'm not sure if the possiblity of a race condition
-- acually exists in practice.  The thing to do here might be to just create 
-- a function that dynamically builds the insert strings and does the 
-- each time an insert is done on the content_type view.  Trade-off being
-- that the inserts would be slower due to the use of dynamic code in pl/psql.
-- More digging required ...

-- DCW, 2001-03-30.

-- Create or replace a trigger on insert for simplifying addition of
-- revisions for any content type

select define_function_args('content_type__refresh_trigger','content_type');

create or replace function content_type__refresh_trigger (varchar)
returns integer as '
declare
  refresh_trigger__content_type           alias for $1;  
  rule_text                               text default '''';
  v_table_name                            acs_object_types.table_name%TYPE;
  type_rec                                record;
begin

  -- get the table name for the content type (determines view name)

  select table_name 
    into v_table_name
    from acs_object_types 
   where object_type = refresh_trigger__content_type;

  --=================== start building rule code =======================

  rule_text := ''create rule '' || v_table_name || ''_r as on insert to '' ||
               v_table_name || ''i do instead (
                update cr_dummy set val = (
                select content_revision__new(
                                     new.title,
                                     new.description,
                                     now(),
                                     new.mime_type,
                                     new.nls_language,
                                     case when new.text is null 
                                              then new.data 
                                              else new.text
                                           end,
                                     content_symlink__resolve(new.item_id),
                                     new.revision_id,
                                     now(),
                                     new.creation_user, 
                                     new.creation_ip,
                                     new.object_package_id
                ));
                '';

  -- add an insert statement for each subtype in the hierarchy for this type

  for type_rec in select ot2.object_type, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot2.object_type <> ''acs_object''                       
                    and ot2.object_type <> ''content_revision''
                    and ot1.object_type = refresh_trigger__content_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by level desc
  LOOP
    rule_text := rule_text || '' '' || content_type__trigger_insert_statement(type_rec.object_type) || '';'';
  end loop;

  -- end building the rule definition code

  rule_text := rule_text || '' );'';

  --================== done building rule code =======================

  -- drop the old rule
  if rule_exists(v_table_name || ''_r'', v_table_name || ''i'') then 

    -- different syntax for dropping a rule in 7.2 and 7.3 so check which
    -- version is being used (olah).
    if version() like ''%PostgreSQL 7.2%'' then
      execute ''drop rule '' || v_table_name || ''_r'';
    else
      -- 7.3 syntax
      execute ''drop rule '' || v_table_name || ''_r '' || ''on '' || v_table_name || ''i'';
    end if;

  end if;

  -- create the new rule for inserts on the content type
  execute rule_text;

  return null; 

end;' language 'plpgsql';

select define_function_args('content_type__refresh_view','content_type');

create or replace function content_type__refresh_view (varchar)
returns integer as '
declare
  refresh_view__content_type           alias for $1;  
  cols                                 varchar default ''''; 
  tabs                                 varchar default ''''; 
  joins                                varchar default '''';
  v_table_name                         varchar;
  join_rec                             record;
begin

  if v_table_name is null then
    return 0;
  end if;

  for join_rec in select ot2.table_name, ot2.id_column, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot2.object_type <> ''acs_object''                       
                    and ot2.object_type <> ''content_revision''
                    and ot1.object_type = refresh_view__content_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by ot2.tree_sortkey desc
  LOOP
    if join_rec.table_name is not null then
        cols := cols || '', '' || join_rec.table_name || ''.*'';
        tabs := tabs || '', '' || join_rec.table_name;
        joins := joins || '' and acs_objects.object_id = '' || 
                 join_rec.table_name || ''.'' || join_rec.id_column;
    end if;
  end loop;

  select table_name into v_table_name from acs_object_types
    where object_type = refresh_view__content_type;

  if length(v_table_name) > 25 then
      raise exception ''Table name cannot be longer than 25 characters, because that causes conflicting rules when we create the views.'';
  end if;

  -- create the input view (includes content columns)

  if table_exists(v_table_name || ''i'') then
     execute ''drop view '' || v_table_name || ''i'';
  end if;

  -- FIXME:  need to look at content_revision__get_content.  Since the CR
  -- can store data in a lob, a text field or in an external file, getting
  -- the data attribute for this view will be problematic.

  execute ''create view '' || v_table_name ||
    ''i as select  acs_objects.object_id,
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
 acs_objects.tree_sortkey,
 acs_objects.max_child_sortkey, cr.revision_id, cr.title, cr.item_id,
    content_revision__get_content(cr.revision_id) as data, 
    cr_text.text_data as text,
    cr.description, cr.publish_date, cr.mime_type, cr.nls_language'' || 
    cols || 
    '' from acs_objects, cr_revisions cr, cr_text'' || tabs || '' where 
    acs_objects.object_id = cr.revision_id '' || joins;

  -- create the output view (excludes content columns to enable SELECT *)

  if table_exists(v_table_name || ''x'') then
     execute ''drop view '' || v_table_name || ''x'';
  end if;

  execute ''create view '' || v_table_name ||
    ''x as select  acs_objects.object_id,
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
 acs_objects.tree_sortkey,
 acs_objects.max_child_sortkey, cr.revision_id, cr.title, cr.item_id,
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

select define_function_args('content_type__register_child_type','parent_type,child_type,relation_tag;generic,min_n;0,max_n');

create or replace function content_type__register_child_type (varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  register_child_type__parent_type   alias for $1;  
  register_child_type__child_type    alias for $2;  
  register_child_type__relation_tag  alias for $3;  -- default ''generic''  
  register_child_type__min_n         alias for $4;  -- default 0
  register_child_type__max_n         alias for $5;  -- default null
  v_exists                           integer;
begin

  select count(*) into v_exists 
    from cr_type_children
    where parent_type = register_child_type__parent_type
    and child_type = register_child_type__child_type
    and relation_tag = register_child_type__relation_tag;

  if v_exists = 0 then

    insert into cr_type_children (
      parent_type, child_type, relation_tag, min_n, max_n
    ) values (
      register_child_type__parent_type, register_child_type__child_type, 
      register_child_type__relation_tag, 
      register_child_type__min_n, 
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


select define_function_args('content_type__unregister_child_type','content_type,child_type,relation_tag');

create or replace function content_type__unregister_child_type (varchar,varchar,varchar)
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


select define_function_args('content_type__register_relation_type','content_type,target_type,relation_tag;generic,min_n;0,max_n');

create or replace function content_type__register_relation_type (varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  register_relation_type__content_type  alias for $1;  
  register_relation_type__target_type   alias for $2;  
  register_relation_type__relation_tag  alias for $3;  -- default ''generic''  
  register_relation_type__min_n         alias for $4;  -- default 0
  register_relation_type__max_n         alias for $5;  -- default null
  v_exists                              integer;       
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


select define_function_args('content_type__unregister_relation_type','content_type,target_type,relation_tag;generic');

create or replace function content_type__unregister_relation_type (varchar,varchar,varchar)
returns integer as '
declare
  unregister_relation_type__content_type  alias for $1;  
  unregister_relation_type__target_type   alias for $2;  
  unregister_relation_type__relation_tag  alias for $3;  -- default null  
                                        
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


select define_function_args('content_type__register_mime_type','content_type,mime_type');

create or replace function content_type__register_mime_type (varchar,varchar)
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


select define_function_args('content_type__unregister_mime_type','content_type,mime_type');

create or replace function content_type__unregister_mime_type (varchar,varchar)
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


select define_function_args('content_type__is_content_type','content_type'); 

create or replace function content_type__is_content_type (varchar)
returns boolean as '
declare
  is_content_type__object_type            alias for $1;  
  v_is_content_type                       boolean;
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
 
end;' language 'plpgsql' stable;


select define_function_args('content_type__rotate_template','template_id,content_type,use_context');

create or replace function content_type__rotate_template (integer,varchar,varchar)
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
    PERFORM content_type__register_template(
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

create or replace function inline_0 ()
returns integer as '
declare 
        type_rec        record;
begin

  for type_rec in select ot.object_type 
                  from acs_object_types ot, acs_object_types ot2
                  where ot2.object_type = ''content_revision''
                    and ot.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by ot.tree_sortkey
  LOOP
    PERFORM content_type__refresh_view (type_rec.object_type);
  end LOOP;

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

