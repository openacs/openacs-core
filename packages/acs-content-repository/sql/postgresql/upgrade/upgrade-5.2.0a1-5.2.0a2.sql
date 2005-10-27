-- procedure refresh_trigger
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

--  procedure refresh_view
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
--                  select 
--                    table_name, id_column, level
--                  from
--                    acs_object_types
--                  where
--                    object_type <> ''acs_object''
--                  and
--                    object_type <> ''content_revision''
--                  start with
--                    object_type = refresh_view__content_type
--                  connect by
--                    object_type = prior supertype 

  for join_rec in select ot2.table_name, ot2.id_column, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot2.object_type <> ''acs_object''                       
                    and ot2.object_type <> ''content_revision''
                    and lower(ot2.table_name) <> ''acs_objects''     
                    and lower(ot2.table_name) <> ''cr_revisions''
                    and ot1.object_type = refresh_view__content_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by ot2.tree_sortkey desc
  LOOP
    cols := cols || '', '' || join_rec.table_name || ''.*'';
    tabs := tabs || '', '' || join_rec.table_name;
    joins := joins || '' and acs_objects.object_id = '' || 
             join_rec.table_name || ''.'' || join_rec.id_column;
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

-- recreate all views and triggers
create function inline_0 ()
returns integer as '
declare
    ct RECORD;
begin
  for ct in select t.object_type,t.table_name
            from acs_object_type_supertype_map m, acs_object_types t
            where t.object_type = m.object_type
            and m.ancestor_type = ''content_revision''
  loop
        if table_exists(ct.table_name) = ''t'' then 
                perform content_type__refresh_view (ct.object_type);
        end if;
  end loop;

  return null;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();
