-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2005-01-05
-- @arch-tag: 5be8fd4b-0259-4ded-905a-37cb95b7fa9f
-- @cvs-id $Id$
--

-- procedure delete
select define_function_args('content_folder__del','folder_id,cascade_p;f');
create or replace function content_folder__del (integer, boolean)
returns integer as '
declare
  delete__folder_id              alias for $1;  
  p_cascade_p                    alias for $2;
  v_count                        integer;       
  v_child_row                    record;
  v_parent_id                    integer;  
  v_path                         varchar;     
  v_folder_sortkey               varbit;
begin

  if p_cascade_p = ''f'' then
    select count(*) into v_count from cr_items 
     where parent_id = delete__folder_id;
    -- check if the folder contains any items
    if v_count > 0 then
      v_path := content_item__get_path(delete__folder_id, null);
      raise EXCEPTION ''-20000: Folder ID % (%) cannot be deleted because it is not empty.'', delete__folder_id, v_path;
    end if;  
  else 
  -- delete children
    select into v_folder_sortkey tree_sortkey
    from cr_items where item_id=delete__folder_id;

    for v_child_row in select
        item_id, tree_sortkey, name
        from cr_items
        where tree_sortkey between v_folder_sortkey and tree_right(v_folder_sortkey)   
	and tree_sortkey != v_folder_sortkey
        order by tree_sortkey desc
    loop
	if content_folder__is_folder(v_child_row.item_id) then
	  perform content_folder__delete(v_child_row.item_id);
        else
         perform content_item__delete(v_child_row.item_id);
	end if;
    end loop;
  end if;

  PERFORM content_folder__unregister_content_type(
      delete__folder_id,
      ''content_revision'',
      ''t'' 
  );

  delete from cr_folder_type_map
    where folder_id = delete__folder_id;

  select parent_id into v_parent_id from cr_items 
    where item_id = delete__folder_id;
  raise notice ''deleteing folder %'',delete__folder_id;
  PERFORM content_item__delete(delete__folder_id);

  -- check if any folders are left in the parent
  update cr_folders set has_child_folders = ''f'' 
    where folder_id = v_parent_id and not exists (
      select 1 from cr_items 
        where parent_id = v_parent_id and content_type = ''content_folder'');

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_folder__delete','folder_id,cascade_p;f');

create or replace function content_folder__delete (integer, boolean)
returns integer as '
declare
  delete__folder_id              alias for $1;  
  p_cascade_p                    alias for $2;
begin
        PERFORM content_folder__del(delete__folder_id,p_cascade_p);
  return 0; 
end;' language 'plpgsql';


create or replace function content_folder__delete (integer)
returns integer as '
declare
  delete__folder_id              alias for $1;  
  v_count                        integer;       
  v_parent_id                    integer;  
  v_path                         varchar;     
begin
	return content_folder__del(
		delete__folder_id,
		''f''
		);
end;' language 'plpgsql';

-- procedure delete
select define_function_args('content_revision__del','revision_id');
create or replace function content_revision__delete (integer)
returns integer as '
declare
  delete__revision_id    alias for $1;  
  v_item_id              cr_items.item_id%TYPE;
  v_latest_revision      cr_revisions.revision_id%TYPE;
  v_live_revision        cr_revisions.revision_id%TYPE;
  v_rec                  record;                                      
begin

  -- Get item id and latest/live revisions
  select item_id into v_item_id from cr_revisions 
    where revision_id = delete__revision_id;

  select 
    latest_revision, live_revision
  into 
    v_latest_revision, v_live_revision
  from 
    cr_items
  where 
    item_id = v_item_id;

  -- Recalculate latest revision
  if v_latest_revision = delete__revision_id then
      for v_rec in 
          select r.revision_id
            from cr_revisions r, acs_objects o
           where o.object_id = r.revision_id
             and r.item_id = v_item_id
             and r.revision_id <> delete__revision_id
        order by o.creation_date desc 
      LOOP

          v_latest_revision := v_rec.revision_id;
          exit;
      end LOOP;
      if NOT FOUND then
         v_latest_revision := null;        
      end if;
      
      update cr_items set latest_revision = v_latest_revision
      where item_id = v_item_id;    
  end if; 
 
  -- Clear live revision
  if v_live_revision = delete__revision_id then
    update cr_items set live_revision = null
      where item_id = v_item_id;   
  end if; 

  -- Clear the audit
  delete from cr_item_publish_audit
    where old_revision = delete__revision_id
       or new_revision = delete__revision_id;

  -- Delete the revision
  PERFORM acs_object__delete(delete__revision_id);

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_revision__delete','revision_id');

create or replace function content_revision__delete (integer)
returns integer as '
declare
  delete__revision_id    alias for $1;  
begin
        PERFORM content_revision__del(delete__revision_id);
  return 0; 
end;' language 'plpgsql';

-- item
select define_function_args('content_item__del','item_id');
create or replace function content_item__del (integer)
returns integer as '
declare
  delete__item_id                alias for $1;  
  -- v_wf_cases_val                 record;
  v_symlink_val                  record;
  v_revision_val                 record;
  v_rel_val                      record;
begin

  -- Removed this as having workflow stuff in the CR is just plain wrong.
  -- DanW, Aug 25th, 2001.

  --   raise NOTICE ''Deleting associated workflows...'';
  -- 1) delete all workflow cases associated with this item
  --   for v_wf_cases_val in select
  --                           case_id
  --                         from
  --                           wf_cases
  --                         where
  --                           object_id = delete__item_id 
  --   LOOP
  --     PERFORM workflow_case__delete(v_wf_cases_val.case_id);
  --   end loop;

  raise NOTICE ''Deleting symlinks...'';
  -- 2) delete all symlinks to this item
  for v_symlink_val in select 
                         symlink_id
                       from 
                         cr_symlinks
                       where 
                         target_id = delete__item_id 
  LOOP
    PERFORM content_symlink__delete(v_symlink_val.symlink_id);
  end loop;

  raise NOTICE ''Unscheduling item...'';
  delete from cr_release_periods
    where item_id = delete__item_id;

  raise NOTICE ''Deleting associated revisions...'';
  -- 3) delete all revisions of this item
  delete from cr_item_publish_audit
    where item_id = delete__item_id;

  for v_revision_val in select
                          revision_id 
                        from
                          cr_revisions
                        where
                          item_id = delete__item_id 
  LOOP
    PERFORM acs_object__delete(v_revision_val.revision_id);
  end loop;
  
  raise NOTICE ''Deleting associated item templates...'';
  -- 4) unregister all templates to this item
  delete from cr_item_template_map
    where item_id = delete__item_id; 

  raise NOTICE ''Deleting item relationships...'';
  -- Delete all relations on this item
  for v_rel_val in select
                     rel_id
                   from
                     cr_item_rels
                   where
                     item_id = delete__item_id
                   or
                     related_object_id = delete__item_id 
  LOOP
    PERFORM acs_rel__delete(v_rel_val.rel_id);
  end loop;  

  raise NOTICE ''Deleting child relationships...'';
  for v_rel_val in select
                     rel_id
                   from
                     cr_child_rels
                   where
                     child_id = delete__item_id 
  LOOP
    PERFORM acs_rel__delete(v_rel_val.rel_id);
  end loop;  

  raise NOTICE ''Deleting parent relationships...'';
  for v_rel_val in select
                     rel_id, child_id
                   from
                     cr_child_rels
                   where
                     parent_id = delete__item_id 
  LOOP
    PERFORM acs_rel__delete(v_rel_val.rel_id);
    PERFORM content_item__delete(v_rel_val.child_id);
  end loop;  

  raise NOTICE ''Deleting associated permissions...'';
  -- 5) delete associated permissions
  delete from acs_permissions
    where object_id = delete__item_id;

  raise NOTICE ''Deleting keyword associations...'';
  -- 6) delete keyword associations
  delete from cr_item_keyword_map
    where item_id = delete__item_id;

  raise NOTICE ''Deleting associated comments...'';
  -- 7) delete associated comments
  PERFORM journal_entry__delete_for_object(delete__item_id);

  -- context_id debugging loop
  --for v_error_val in c_error_cur loop
  --  raise NOTICE ''ID='' || v_error_val.object_id || '' TYPE='' 
  --    || v_error_val.object_type);
  --end loop;

  raise NOTICE ''Deleting content item...'';
  PERFORM acs_object__delete(delete__item_id);

  return 0; 
end;' language 'plpgsql';


select define_function_args('content_item__delete','item_id');
create or replace function content_item__delete (integer)
returns integer as '
declare
  delete__item_id                alias for $1;  
begin
        PERFORM content_item__del (delete__item_id);
  return 0; 
end;' language 'plpgsql';


-- template
select define_function_args('content_template__del','template_id');
create or replace function content_template__del (integer)
returns integer as '
declare
  delete__template_id            alias for $1;  
begin

  delete from cr_type_template_map
    where template_id = delete__template_id;

  delete from cr_item_template_map
    where template_id = delete__template_id;
 
  delete from cr_templates
    where template_id = delete__template_id;

  PERFORM content_item__delete(delete__template_id);

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_template__delete','template_id');

create or replace function content_template__delete (integer)
returns integer as '
declare
  delete__template_id            alias for $1;  
begin
  PERFORM content_template__delete(delete__template_id);

  return 0; 
end;' language 'plpgsql';
