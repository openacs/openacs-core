-- 
-- Scalability reform part 3 (content-repository):
--   
-- - content_revision__del:
--   * Removed manual nulling of live_revision and latest_revision
--     by using appropriate ond delete actions on foreign keys
--   * Removed manual deletion of old_revision and new_revision in
--     cr_item_publish_audit by using "on delete cascade"
-- 
-- - content_item__del:
--   * Removed manual deletion of item_id in cr_item_publish_audit
--     by using "on delete cascade"
--   * Removed manual deletion of item_id in cr_release_periods
--     by using "on delete cascade"
--   * Removed manual deletion of item_id in cr_item_template_map
--     by using "on delete cascade"
--   * Removed manual deletion of item_id in cr_item_keyword_map
--     by using "on delete cascade"
--   * Removed manual deletion of direct permissions (was already
--     cascading)
--
-- - Added missing index for child_id to cr_child_rels.
--   This index was in the create scripts (with a non-conformant name),
--   but not in the upgrade scripts


-- constraints from acs-content-repository/sql/postgresql/content-revision.sql

ALTER TABLE cr_item_publish_audit DROP CONSTRAINT IF EXISTS cr_item_publish_audit_orev_fk;
ALTER TABLE cr_item_publish_audit ADD CONSTRAINT cr_item_publish_audit_orev_fk
FOREIGN KEY (old_revision) REFERENCES cr_revisions(revision_id) ON DELETE CASCADE;

ALTER TABLE cr_item_publish_audit DROP CONSTRAINT IF EXISTS cr_item_publish_audit_nrev_fk;
ALTER TABLE cr_item_publish_audit ADD CONSTRAINT cr_item_publish_audit_nrev_fk
FOREIGN KEY (new_revision) REFERENCES cr_revisions(revision_id) ON DELETE CASCADE;


-- constraints from acs-content-repository/sql/postgresql/content-item.sql

ALTER TABLE cr_release_periods DROP CONSTRAINT IF EXISTS cr_release_periods_item_id_fk;
ALTER TABLE cr_release_periods ADD CONSTRAINT cr_release_periods_item_id_fk
FOREIGN KEY (item_id) REFERENCES cr_items(item_id) ON DELETE CASCADE;

ALTER TABLE cr_item_publish_audit DROP CONSTRAINT IF EXISTS  cr_item_publish_audit_item_fk;
ALTER TABLE cr_item_publish_audit ADD CONSTRAINT cr_item_publish_audit_item_fk
FOREIGN KEY (item_id) REFERENCES cr_items(item_id) ON DELETE CASCADE;

ALTER TABLE cr_item_template_map DROP CONSTRAINT IF EXISTS cr_item_template_map_item_fk;
ALTER TABLE cr_item_template_map ADD CONSTRAINT cr_item_template_map_item_fk
FOREIGN KEY (item_id) REFERENCES cr_items(item_id) ON DELETE CASCADE;

ALTER TABLE cr_item_keyword_map DROP CONSTRAINT IF EXISTS cr_item_keyword_map_item_id_fk;
ALTER TABLE cr_item_keyword_map ADD CONSTRAINT cr_item_keyword_map_item_id_fk
FOREIGN KEY (item_id) REFERENCES cr_items(item_id) ON DELETE CASCADE;

ALTER TABLE cr_items DROP CONSTRAINT IF EXISTS cr_items_latest_fk;
ALTER TABLE cr_items ADD CONSTRAINT cr_items_latest_fk
FOREIGN KEY (latest_revision) REFERENCES cr_revisions(revision_id) on delete set null;

ALTER TABLE cr_items DROP CONSTRAINT IF EXISTS cr_items_live_fk;
ALTER TABLE cr_items ADD CONSTRAINT cr_items_live_fk
FOREIGN KEY (live_revision) REFERENCES cr_revisions(revision_id) on delete set null;


DROP INDEX if exists CR_CHILD_RELS_kids_IDx;
DROP INDEX if exists cr_child_rels_child_id_idx;
CREATE INDEX cr_child_rels_child_id_idx on cr_child_rels(child_id);

--
-- updated functions
--

CREATE OR REPLACE FUNCTION content_revision__del(
   delete__revision_id integer
) RETURNS integer AS $$
DECLARE
  v_item_id              cr_items.item_id%TYPE;
  v_latest_revision      cr_revisions.revision_id%TYPE;
BEGIN
  --
  -- Get item_id and the latest revision
  --
  select item_id
  into   v_item_id
  from   cr_revisions 
  where  revision_id = delete__revision_id;

  select latest_revision
  into   v_latest_revision
  from   cr_items
  where  item_id = v_item_id;

  --
  -- Recalculate latest revision in case it was deleted
  --
  if v_latest_revision = delete__revision_id then

      select r.revision_id
       into v_latest_revision
       from cr_revisions r, acs_objects o
      where o.object_id = r.revision_id
        and r.item_id = v_item_id
        and r.revision_id <> delete__revision_id
      order by o.creation_date desc limit 1;

      if NOT FOUND then
         v_latest_revision := null;
      end if;

      update cr_items set latest_revision = v_latest_revision
      where item_id = v_item_id;
      
  end if; 

  --
  -- Delete the revision
  --
  PERFORM acs_object__delete(delete__revision_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;



--
-- procedure content_item__del/1
--
CREATE OR REPLACE FUNCTION content_item__del(
   delete__item_id integer
) RETURNS integer AS $$
DECLARE
  v_symlink_val                  record;
  v_revision_val                 record;
  v_rel_val                      record;
BEGIN
  --
  -- Delete all symlinks to this item
  --
  for v_symlink_val in select symlink_id
                       from   cr_symlinks
                       where  target_id = delete__item_id 
  LOOP
    PERFORM content_symlink__delete(v_symlink_val.symlink_id);
  end loop;

  --
  -- Delete all revisions of this item
  --
  -- The following loop could be dropped / replaced by a cascade
  -- operation, when proper foreign keys are used along the
  -- inheritance path.
  --
  for v_revision_val in select revision_id 
                        from   cr_revisions
                        where  item_id = delete__item_id 
  LOOP
    PERFORM acs_object__delete(v_revision_val.revision_id);
  end loop;

  --
  -- Delete all relations on this item
  --
  for v_rel_val in select rel_id
                   from   cr_item_rels
                   where  item_id = delete__item_id
                   or     related_object_id = delete__item_id 
  LOOP
    PERFORM acs_rel__delete(v_rel_val.rel_id);
  end loop;  

  for v_rel_val in select rel_id
                   from   cr_child_rels
                   where  child_id = delete__item_id 
  LOOP
    PERFORM acs_rel__delete(v_rel_val.rel_id);
  end loop;  

  for v_rel_val in select rel_id, child_id
                   from   cr_child_rels
                   where  parent_id = delete__item_id 
  LOOP
    PERFORM acs_rel__delete(v_rel_val.rel_id);
    PERFORM content_item__delete(v_rel_val.child_id);
  end loop;  

  --
  -- Delete associated comments
  --
  PERFORM journal_entry__delete_for_object(delete__item_id);

  --
  -- Finally, delete the acs_object of the item.
  --
  PERFORM acs_object__delete(delete__item_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;
