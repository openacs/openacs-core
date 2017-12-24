ALTER TABLE acs_objects drop column IF EXISTS tree_sortkey cascade;
ALTER TABLE acs_objects drop column IF EXISTS max_child_sortkey cascade;

DROP TRIGGER IF EXISTS acs_objects_insert_tr on acs_objects;
DROP TRIGGER IF EXISTS acs_objects_update_tr on acs_objects;

-- 
-- procedure content_type__refresh_view/1
-- 
CREATE OR REPLACE FUNCTION content_type__refresh_view(
   refresh_view__content_type varchar
) RETURNS integer AS $$
DECLARE
  cols                                 varchar default '';
  tabs                                 varchar default '';
  joins                                varchar default '';
  v_table_name                         varchar;
  join_rec                             record;
BEGIN

  for join_rec in select ot2.table_name, ot2.id_column, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot2.object_type <> 'acs_object'
                    and ot2.object_type <> 'content_revision'
                    and lower(ot2.table_name) <> 'acs_objects'
                    and lower(ot2.table_name) <> 'cr_revisions'
                    and ot1.object_type = refresh_view__content_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by ot2.tree_sortkey desc
  LOOP
    if join_rec.table_name is not null then
        cols := cols || ', ' || join_rec.table_name || '.*';
        tabs := tabs || ', ' || join_rec.table_name;
        joins := joins || ' and acs_objects.object_id = ' ||
                 join_rec.table_name || '.' || join_rec.id_column;
    end if;
  end loop;

  -- Since we allow null table name use object type if table name is null so
  -- we still can have a view.
  select coalesce(table_name,object_type) into v_table_name from acs_object_types
    where object_type = refresh_view__content_type;

  if length(v_table_name) > 57 then
      raise exception 'Table name cannot be longer than 57 characters, because that causes conflicting rules when we create the views.';
  end if;

  -- create the input view (includes content columns)

  if table_exists(v_table_name || 'i') then
     execute 'drop view ' || v_table_name || 'i' || ' CASCADE';
  end if;

  -- FIXME:  need to look at content_revision__get_content.  Since the CR
  -- can store data in a lob, a text field or in an external file, getting
  -- the data attribute for this view will be problematic.

  execute 'create view ' || v_table_name ||
    'i as select  acs_objects.object_id,
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
    content_revision__get_content(cr.revision_id) as data,
    cr_text.text_data as text,
    cr.description, cr.publish_date, cr.mime_type, cr.nls_language' ||
    cols ||
    ' from acs_objects, cr_revisions cr, cr_text' || tabs || ' where
    acs_objects.object_id = cr.revision_id ' || joins;

  -- create the output view (excludes content columns to enable SELECT *)

  if table_exists(v_table_name || 'x') then
     execute 'drop view ' || v_table_name || 'x cascade';
  end if;

  execute 'create view ' || v_table_name ||
    'x as select  acs_objects.object_id,
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

  PERFORM content_type__refresh_trigger(refresh_view__content_type);

-- exception
--   when others then
--     dbms_output.put_line('Error creating attribute view or trigger for'
--  || content_type);

  return 0;
END;
$$ LANGUAGE plpgsql;


--
-- The ALTER TABLE ... CASCADE deletes several automatically and
-- manually built views and functions. The automatically built
-- dependent objects can be rebuilt with the helper function
-- 'content_type__refresh_view'.
--
-- However, we have as well rebuild a few views which included
-- (sometimes implicitly, e.g. via acs_objects.*) the
-- tree_sortkey. We perform this operation here (since the views were
-- dropped by this upgrade script) but as well in update scripts for
-- the relevant packages referring explicitly to the tree_sortkey
-- fields.
--


SELECT t2.object_type, content_type__refresh_view(t2.object_type)
from acs_object_types t1, acs_object_types t2
where t2.tree_sortkey between t1.tree_sortkey and
tree_right(t1.tree_sortkey) and t1.object_type = 'content_revision';


-- 
-- we have to recreate cc_users, since it exports o.*
-- 
create or replace view cc_users as
select o.*, pa.*, pe.*, u.*, mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr
where o.object_id = pa.party_id
  and pa.party_id = pe.person_id
  and pe.person_id = u.user_id
  and u.user_id = m.member_id
  and m.group_id = acs__magic_object_id('registered_users')
  and m.rel_id = mr.rel_id
  and m.container_id = m.group_id
  and m.rel_type = 'membership_rel';

-- 
-- we have to recreate fs_urls_full, when file-storage is in use,
-- since the view exports acs_objects.*
--
create function inline_0()
returns integer as $inline_0$
declare success integer;
begin

  -- We know we have to update when we have one of the tables of the
  -- file-storage package.

  select 1 from pg_class into success where relname = 'fs_folders';
  IF found THEN 
     create or replace view fs_urls_full as
       select cr_extlinks.extlink_id as url_id,
           cr_extlinks.url,
           cr_items.parent_id as folder_id,
           cr_extlinks.label as name,
           cr_extlinks.description,
           acs_objects.*
       from cr_extlinks,
         cr_items,
         acs_objects
       where cr_extlinks.extlink_id = cr_items.item_id
       and cr_items.item_id = acs_objects.object_id;
   END IF;

   return null;
end;
$inline_0$ LANGUAGE plpgsql;

select inline_0();
drop function inline_0();


-- 
-- We have to recreate download_repository_obj and
-- download_arch_revisions_obj, when download is in use, since the
-- views exports acs_objects.tree_sortkey
--

create function inline_0()
returns integer as $inline_0$
declare success integer;
begin

  --
  -- We know we have to update the view when we have one of the base tables.
  --
  select 1 from pg_class into success where relname = 'download_repository';
  IF found THEN 

     -- If the upgrade script is run multiple times, then
     --   "ALTER TABLE acs_objects drop column ..."
     -- might not have dropped the view. So we do this manually.
     
     select 1 from pg_class into success where relname = 'download_repository_obj';
     IF found THEN
        drop view download_repository_obj;
     END if;
     create view download_repository_obj as
       select repository_id, 
                 o.object_id, o.object_type, o.title as obj_title, o.package_id as obj_package_id, o.context_id,
                 o.security_inherit_p, o.creation_user, o.creation_date, o.creation_ip, o.last_modified, o.modifying_user,
                 o.modifying_ip, 
                  i.parent_id, 
                          r.title, 
                          r.description, 
                          r.content as help_text
       from download_repository dr, acs_objects o, cr_items i, cr_revisions r
           where dr.repository_id = o.object_id
	   and i.item_id = o.object_id
	   and r.revision_id = i.live_revision;

     --
     -- now the same with download_arch_revisions_obj
     --
     select 1 from pg_class into success where relname = 'download_arch_revisions_obj';
     IF found THEN
        drop view download_arch_revisions_obj;
     END if;

     create view download_arch_revisions_obj as
       select dar.*, 
                          o.object_id, o.object_type, o.title as obj_title, o.package_id as obj_package_id, o.context_id,
                          o.security_inherit_p, o.creation_user, o.creation_date, o.creation_ip, o.last_modified, o.modifying_user,
                          o.modifying_ip, 
                          r.item_id as archive_id, 
                          r.title as file_name, 
                          r.description as version_name, 
                          r.publish_date, 
                          r.mime_type, 
                          r.content
       from download_archive_revisions dar, acs_objects o, cr_revisions r
           where dar.revision_id = o.object_id
	   and   dar.revision_id = r.revision_id;
   END IF;
	   
   return null;
end;
$inline_0$ LANGUAGE plpgsql;

select inline_0();
drop function inline_0();

-- the triggers are deleted automatically
--
--    drop trigger acs_objects_insert_tr on acs_objects;
--    drop trigger acs_objects_update_tr on acs_objects;

drop function IF EXISTS acs_objects_get_tree_sortkey(integer);
drop function IF EXISTS acs_objects_insert_tr();
drop function IF EXISTS acs_objects_update_tr();
