create or replace function content_item__get_content_type (integer)
returns varchar as '
declare
  get_content_type__item_id                alias for $1;  
  v_content_type                           cr_items.content_type%TYPE;
begin

  select
    content_type into v_content_type
  from 
    cr_items
  where 
    item_id = get_content_type__item_id;  

  return v_content_type;
 
end;' language 'plpgsql' stable strict;



create or replace function content_item__get_best_revision (integer)
returns integer as '
declare
  get_best_revision__item_id                alias for $1;  
  v_revision_id                             cr_revisions.revision_id%TYPE;
begin
    
  select
    coalesce(live_revision, latest_revision )
  into
    v_revision_id
  from
    cr_items
  where
    item_id = get_best_revision__item_id;

  return v_revision_id;
 
end;' language 'plpgsql' stable strict;


create or replace function content_item__get_context (integer)
returns integer as '
declare
  get_context__item_id                alias for $1;  
  v_context_id                        acs_objects.context_id%TYPE;
begin

  select
    context_id
  into
    v_context_id
  from
    acs_objects
  where
    object_id = get_context__item_id;

  if NOT FOUND then 
     raise EXCEPTION ''-20000: Content item % does not exist in content_item.get_context'', get_context__item_id;
  end if;

  return v_context_id;
 
end;' language 'plpgsql' stable;



create or replace function content_item__get_latest_revision (integer)
returns integer as '
declare
  get_latest_revision__item_id                alias for $1;
  v_revision_id                               integer;
  v_rec                                       record;
begin
  for v_rec in 
  select 
    r.revision_id 
  from 
    cr_revisions r, acs_objects o
  where 
    r.revision_id = o.object_id
  and 
    r.item_id = get_latest_revision__item_id
  order by 
    o.creation_date desc
  LOOP
      v_revision_id := v_rec.revision_id;
      exit;
  end LOOP;

  return v_revision_id;
 
end;' language 'plpgsql' strict stable;


create or replace function content_item__get_live_revision (integer)
returns integer as '
declare
  get_live_revision__item_id                alias for $1;  
  v_revision_id                             acs_objects.object_id%TYPE;
begin

  select
    live_revision into v_revision_id
  from
    cr_items
  where
    item_id = get_live_revision__item_id;

  return v_revision_id;
 
end;' language 'plpgsql' stable strict;


-- there was an infinite loop in content_item.get_parent_folder if called with 
-- a child content_item rather than a content item which was directly below a 
-- folder.

create or replace function content_item__get_parent_folder (integer)
returns integer as '
declare
  get_parent_folder__item_id               alias for $1;  
  v_folder_id                              cr_folders.folder_id%TYPE;
  v_parent_folder_p                        boolean default ''f'';       
begin
  v_folder_id := get_parent_folder__item_id;

  while NOT v_parent_folder_p and v_folder_id is not null LOOP

    select
      parent_id, content_folder__is_folder(parent_id) 
    into 
      v_folder_id, v_parent_folder_p
    from
      cr_items
    where
      item_id = v_folder_id;

  end loop; 

  return v_folder_id;
 
end;' language 'plpgsql' stable strict;


create or replace function content_item__get_publish_date (integer,boolean)
returns timestamptz as '
declare
  get_publish_date__item_id                alias for $1;  
  get_publish_date__is_live                alias for $2;  -- default ''f''  
  v_revision_id                            cr_revisions.revision_id%TYPE;
  v_publish_date                           cr_revisions.publish_date%TYPE;
begin

  if get_publish_date__is_live then
    select
	publish_date into v_publish_date
    from
	cr_revisions r, cr_items i
    where
      i.item_id = get_publish_date__item_id
    and
      r.revision_id = i.live_revision;
  else
    select
	publish_date into v_publish_date
    from
	cr_revisions r, cr_items i
    where
      i.item_id = get_publish_date__item_id
    and
      r.revision_id = i.latest_revision;
  end if;

  return v_publish_date;
 
end;' language 'plpgsql' stable;

create or replace function content_item__get_publish_date (integer,boolean)
returns timestamptz as '
declare
  get_publish_date__item_id                alias for $1;  
  get_publish_date__is_live                alias for $2;  -- default ''f''  
  v_revision_id                            cr_revisions.revision_id%TYPE;
  v_publish_date                           cr_revisions.publish_date%TYPE;
begin

  if get_publish_date__is_live then
    select
	publish_date into v_publish_date
    from
	cr_revisions r, cr_items i
    where
      i.item_id = get_publish_date__item_id
    and
      r.revision_id = i.live_revision;
  else
    select
	publish_date into v_publish_date
    from
	cr_revisions r, cr_items i
    where
      i.item_id = get_publish_date__item_id
    and
      r.revision_id = i.latest_revision;
  end if;

  return v_publish_date;
 
end;' language 'plpgsql' stable;


-- This used to have a pretty gross loop and sort.
--
create or replace function content_item__is_subclass (varchar,varchar)
returns boolean as '
declare
  is_subclass__object_type            alias for $1;  
  is_subclass__supertype              alias for $2;  
  v_subclass_p                        boolean;      
  v_inherit_val                       record;
begin
  select count(*) > 0 into v_subclass_p where exists (
	select 1
          from acs_object_types o, acs_object_types o2
         where o2.object_type = is_subclass__supertype
           and o.object_type = is_subclass__object_type
           and o.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey));

  return v_subclass_p;

end;' language 'plpgsql' stable;



create or replace function content_item__is_publishable (integer)
returns boolean as '
declare
  is_publishable__item_id                alias for $1;  
  v_child_count                          integer;       
  v_rel_count                            integer;       
  v_template_id                          cr_templates.template_id%TYPE;
  v_child_type                           record;
  v_rel_type                             record;
  v_content_type			 varchar;
  -- v_pub_wf                               record;
begin
  -- check valid item_id
  select content_item__get_content_type(is_publishable__item_id) into v_content_type;

  if v_content_type is null then 
	raise exception ''content_item__is_publishable item_id % invalid'',is_publishable__item_id;
  end if;

  -- validate children
  -- make sure the # of children of each type fall between min_n and max_n
  for v_child_type in select
                        child_type, min_n, max_n
                      from
                        cr_type_children
                      where
                        parent_type = v_content_type 
	                and (min_n is not null or max_n is not null)
  LOOP
    select
      count(rel_id) into v_child_count
    from
      cr_child_rels
    where
      parent_id = is_publishable__item_id
    and
      content_item__get_content_type(child_id) = v_child_type.child_type;

    -- make sure # of children is in range
    if v_child_type.min_n is not null 
      and v_child_count < v_child_type.min_n then
      return ''f'';
    end if;
    if v_child_type.max_n is not null
      and v_child_count > v_child_type.max_n then
      return ''f'';
    end if;

  end LOOP;

  -- validate relations
  -- make sure the # of ext links of each type fall between min_n and max_n
  -- only check if one of min_n max_n not null
  for v_rel_type in select
                      target_type, min_n, max_n
                    from
                      cr_type_relations
                    where
                      content_type = v_content_type
		      and (max_n is not null or min_n is not null)
  LOOP
    select
      count(rel_id) into v_rel_count
    from
      cr_item_rels i, acs_objects o
    where
      i.related_object_id = o.object_id
    and
      i.item_id = is_publishable__item_id
    and
      coalesce(content_item__get_content_type(o.object_id),o.object_type) = v_rel_type.target_type;
      
    -- make sure # of object relations is in range
    if v_rel_type.min_n is not null 
      and v_rel_count < v_rel_type.min_n then
      return ''f'';
    end if;
    if v_rel_type.max_n is not null 
      and v_rel_count > v_rel_type.max_n then
      return ''f'';
    end if;
  end loop;

  -- validate publishing workflows
  -- make sure any ''publishing_wf'' associated with this item are finished
  -- KG: logic is wrong here.  Only the latest workflow matters, and even
  -- that is a little problematic because more than one workflow may be
  -- open on an item.  In addition, this should be moved to CMS.
  
  -- Removed this as having workflow stuff in the CR is just plain wrong.
  -- DanW, Aug 25th, 2001.

  --   for v_pub_wf in  select
  --                      case_id, state
  --                    from
  --                      wf_cases
  --                    where
  --                      workflow_key = ''publishing_wf''
  --                    and
  --                      object_id = is_publishable__item_id
  -- 
  --   LOOP
  --     if v_pub_wf.state != ''finished'' then
  --        return ''f'';
  --     end if;
  --   end loop;

  -- if NOT FOUND then 
  --   return ''f'';
  -- end if;

  return ''t'';
 
end;' language 'plpgsql' stable;



create or replace function content_item__move (integer,integer)
returns integer as '
declare
  move__item_id                alias for $1;  
  move__target_folder_id       alias for $2;  
begin

  if move__target_folder_id is null then 
	raise exception ''attempt to move item_id % to null folder_id'', move__item_id;
  end if;

  if content_folder__is_folder(move__item_id) = ''t'' then

    PERFORM content_folder__move(move__item_id, move__target_folder_id);

  else if content_folder__is_folder(move__target_folder_id) = ''t'' then
   

    if content_folder__is_registered(move__target_folder_id,
          content_item__get_content_type(move__item_id),''f'') = ''t'' and
       content_folder__is_registered(move__target_folder_id,
          content_item__get_content_type(content_symlink__resolve(move__item_id)),''f'') = ''t''
      then

    -- update the parent_id for the item
    update cr_items 
      set parent_id = move__target_folder_id
      where item_id = move__item_id;
    end if;

  end if; end if;

  return 0; 
end;' language 'plpgsql';



create or replace function content_revision__copy_attributes (varchar,integer,integer)
returns integer as '
declare
  copy_attributes__content_type           alias for $1;  
  copy_attributes__revision_id            alias for $2;  
  copy_attributes__copy_id                alias for $3;  
  v_table_name                            acs_object_types.table_name%TYPE;
  v_id_column                             acs_object_types.id_column%TYPE;
  cols                                    varchar default ''''; 
  attr_rec                                record;
begin

  if copy_attributes__content_type is null or copy_attributes__revision_id is null or copy_attributes__copy_id is null then 
     raise exception ''content_revision__copy_attributes called with null % % %'',copy_attributes__content_type,copy_attributes__revision_id, copy_attributes__copy_id;
  end if;

  select table_name, id_column into v_table_name, v_id_column
  from acs_object_types where object_type = copy_attributes__content_type;

  for attr_rec in select
                    attribute_name
                  from
                    acs_attributes
                  where
                    object_type = copy_attributes__content_type 
  LOOP
    cols := cols || '', '' || attr_rec.attribute_name;
  end loop;

  execute ''insert into '' || v_table_name || '' select '' || copy_attributes__copy_id || 
          '' as '' || v_id_column || cols || '' from '' || 
          v_table_name || '' where '' || v_id_column || '' = '' || 
          copy_attributes__revision_id;
  
  return 0; 
end;' language 'plpgsql';

create or replace function content_keyword__is_assigned (integer,integer,varchar)
returns boolean as '
declare
  is_assigned__item_id                alias for $1;  
  is_assigned__keyword_id             alias for $2;  
  is_assigned__recurse                alias for $3;  -- default ''none''  
  v_ret                               boolean;    
  v_is_assigned__recurse	      varchar;
begin
  if is_assigned__recurse is null then 
	v_is_assigned__recurse := ''none'';
  else
      	v_is_assigned__recurse := is_assigned__recurse;	
  end if;

  -- Look for an exact match
  if v_is_assigned__recurse = ''none'' then
      return count(*) > 0 from cr_item_keyword_map
       where item_id = is_assigned__item_id
         and keyword_id = is_assigned__keyword_id;
  end if;

  -- Look from specific to general
  if v_is_assigned__recurse = ''up'' then
      return count(*) > 0
      where exists (select 1
                    from (select keyword_id from cr_keywords c, cr_keywords c2
	                  where c2.keyword_id = is_assigned__keyword_id
                            and c.tree_sortkey between c2.tree_sortkey and tree_right(c2.tree_sortkey)) t,
                      cr_item_keyword_map m
                    where t.keyword_id = m.keyword_id
                      and m.item_id = is_assigned__item_id);
  end if;

  if v_is_assigned__recurse = ''down'' then
      return count(*) > 0
      where exists (select 1
                    from (select k2.keyword_id
                          from cr_keywords k1, cr_keywords k2
                          where k1.keyword_id = is_assigned__keyword_id
                            and k1.tree_sortkey between k2.tree_sortkey and tree_right(k2.tree_sortkey)) t, 
                      cr_item_keyword_map m
                    where t.keyword_id = m.keyword_id
                      and m.item_id = is_assigned__item_id);

  end if;  

  -- Tried none, up and down - must be an invalid parameter
  raise EXCEPTION ''-20000: The recurse parameter to content_keyword.is_assigned should be \\\'none\\\', \\\'up\\\' or \\\'down\\\''';
  
  return null;
end;' language 'plpgsql' stable;


create or replace function content_folder__is_registered (integer,varchar,boolean)
returns boolean as '
declare
  is_registered__folder_id              alias for $1;  
  is_registered__content_type           alias for $2;  
  is_registered__include_subtypes       alias for $3;  -- default ''f''  
  v_is_registered                       integer;
  v_subtype_val                         record;
begin

  if is_registered__include_subtypes = ''f'' or  is_registered__include_subtypes is null then
    select 
      count(1)
    into 
      v_is_registered
    from
      cr_folder_type_map
    where
      folder_id = is_registered__folder_id
    and
      content_type = is_registered__content_type;

  else
--                         select
--                            object_type
--                          from 
--                            acs_object_types
--                          where 
--                            object_type <> ''acs_object''
--                          connect by 
--                            prior object_type = supertype
--                          start with 
--                            object_type = is_registered.content_type 

    v_is_registered := 1;
    for v_subtype_val in select o.object_type
                         from acs_object_types o, acs_object_types o2
                         where o.object_type <> ''acs_object''
                           and o2.object_type = is_registered__content_type
                           and o.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
                         order by o.tree_sortkey
    LOOP
      if content_folder__is_registered(is_registered__folder_id,
                       v_subtype_val.object_type, ''f'') = ''f'' then
        v_is_registered := 0;
      end if;
    end loop;
  end if;

  if v_is_registered = 0 then
    return ''f'';
  else
    return ''t'';
  end if;
 
end;' language 'plpgsql' stable;


create or replace function content_revision__content_copy (integer,integer)
returns integer as '
declare
  content_copy__revision_id            alias for $1;  
  content_copy__revision_id_dest       alias for $2;  -- default null  
  v_item_id                            cr_items.item_id%TYPE;
  v_content_length                     cr_revisions.content_length%TYPE;
  v_revision_id_dest                   cr_revisions.revision_id%TYPE;
  v_content                            cr_revisions.content%TYPE;
  v_lob                                cr_revisions.lob%TYPE;
  v_new_lob                            cr_revisions.lob%TYPE;
  v_storage_type                       varchar;
begin
  if content_copy__revision_id is null then 
	raise exception ''content_revision__content_copy attempt to copy a null revision_id'';
  end if;

  select
    content_length, item_id
  into
    v_content_length, v_item_id
  from
    cr_revisions
  where
    revision_id = content_copy__revision_id;

  -- get the destination revision
  if content_copy__revision_id_dest is null then
    select
      latest_revision into v_revision_id_dest
    from
      cr_items
    where
      item_id = v_item_id;
  else
    v_revision_id_dest := content_copy__revision_id_dest;
  end if;


  -- only copy the content if the source content is not null
  if v_content_length is not null and v_content_length > 0 then

    /* The internal LOB types - BLOB, CLOB, and NCLOB - use copy semantics, as 
       opposed to the reference semantics which apply to BFILEs.
       When a BLOB, CLOB, or NCLOB is copied from one row to another row in 
       the same table or in a different table, the actual LOB value is
       copied, not just the LOB locator. */

    select r.content, r.content_length, r.lob, i.storage_type 
      into v_content, v_content_length, v_lob, v_storage_type
      from cr_revisions r, cr_items i 
     where r.item_id = i.item_id 
       and r.revision_id = content_copy__revision_id;

    if v_storage_type = ''lob'' then
        v_new_lob := empty_lob();

        update cr_revisions
           set content = null,
               content_length = v_content_length,
               lob = v_new_lob
         where revision_id = v_revision_id_dest;
        PERFORM lob_copy(v_lob, v_new_lob);
    else 
        -- this will work for both file and text types... well sort of.
        -- this really just creates a reference to the first file which is
        -- wrong since, the item_id, revision_id uniquely describes the 
        -- location of the file in the content repository file system.  
        -- after copy is called, the content attribute needs to be updated 
        -- with the new relative file path:

        -- update cr_revisions
        -- set content = ''[cr_create_content_file $item_id $revision_id [cr_fs_path]$old_rel_path]''
        -- where revision_id = :revision_id
        
        -- old_rel_path is the content attribute value of the content revision
        -- that is being copied.
        update cr_revisions
           set content = v_content,
               content_length = v_content_length,
               lob = null
         where revision_id = v_revision_id_dest;
    end if;

  end if;

  return 0; 
end;' language 'plpgsql';

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


create or replace function rule_exists (varchar,varchar) returns boolean as '
declare
        rule_name       alias for $1;
        table_name      alias for $2;
begin
        return count(*) = 1
          from pg_rules
         where tablename::varchar = lower(table_name)
           and rulename::varchar = lower(rule_name);

end;' language 'plpgsql' stable;

