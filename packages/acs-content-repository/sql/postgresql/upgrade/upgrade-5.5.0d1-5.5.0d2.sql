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
    if join_rec.table_name is not null then
        cols := cols || '', '' || join_rec.table_name || ''.*'';
        tabs := tabs || '', '' || join_rec.table_name;
        joins := joins || '' and acs_objects.object_id = '' || 
                 join_rec.table_name || ''.'' || join_rec.id_column;
    end if;
  end loop;

  select table_name into v_table_name from acs_object_types
    where object_type = refresh_view__content_type;

  if length(v_table_name) > 57 then
      raise exception ''Table name cannot be longer than 57 characters, because that causes conflicting rules when we create the views.'';
  end if;

  -- create the input view (includes content columns)

  if table_exists(v_table_name || ''i'') then
     execute ''drop view '' || v_table_name || ''i'' || '' CASCADE'';
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

