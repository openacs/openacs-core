--
-- Note: some of the update operations might take on large sites a
-- couple of minutes, since these operate on the largest tables of
-- OpenACS. You might consider to run this on production offline or
-- with a proxy turned off.
--
-- Make sure there are no stray entries in cr_child_rels
--
delete from cr_child_rels where parent_id in (select parent_id from cr_child_rels except select object_id from acs_objects);
delete from cr_child_rels where child_id in (select child_id from cr_child_rels except select item_id from cr_items);

--
-- Add FK constraints for cr_child_rels with cascade operations
--
ALTER TABLE cr_child_rels DROP CONSTRAINT IF EXISTS cr_child_rels_parent_id_fk;
ALTER TABLE cr_child_rels ADD CONSTRAINT cr_child_rels_parent_id_fk
FOREIGN KEY (parent_id) REFERENCES acs_objects(object_id) ON DELETE CASCADE;

ALTER TABLE cr_child_rels DROP CONSTRAINT IF EXISTS cr_child_rels_child_id_fk;
ALTER TABLE cr_child_rels ADD CONSTRAINT cr_child_rels_child_id_fk
FOREIGN KEY (child_id) REFERENCES cr_items(item_id) ON DELETE CASCADE;

--
-- Add FK constraints for cr_item_rels with cascade operations
--
ALTER TABLE cr_item_rels DROP CONSTRAINT IF EXISTS cr_item_rels_item_id_fk;
ALTER TABLE cr_item_rels ADD CONSTRAINT cr_item_rels_item_id_fk
FOREIGN KEY (item_id) REFERENCES cr_items(item_id) ON DELETE CASCADE;

--
-- alter FK constraints to of context index and of acs_objects.context_id to cascade operations
--
ALTER TABLE acs_object_context_index DROP CONSTRAINT IF EXISTS acs_obj_context_idx_anc_id_fk;
ALTER TABLE acs_object_context_index ADD CONSTRAINT acs_obj_context_idx_anc_id_fk
FOREIGN KEY (ancestor_id) REFERENCES acs_objects(object_id) ON DELETE CASCADE;

ALTER TABLE acs_object_context_index DROP CONSTRAINT IF EXISTS acs_obj_context_idx_obj_id_fk;
ALTER TABLE acs_object_context_index ADD CONSTRAINT acs_obj_context_idx_obj_id_fk
FOREIGN KEY (object_id) REFERENCES acs_objects(object_id) ON DELETE CASCADE;

ALTER TABLE acs_objects DROP CONSTRAINT IF EXISTS acs_objects_context_id_fk;
ALTER TABLE acs_objects ADD CONSTRAINT acs_objects_context_id_fk
FOREIGN KEY (context_id) REFERENCES acs_objects(object_id) ON DELETE CASCADE;

--
-- Since acs_objects_context_id_fk cascades, there is no need for an
-- extra trigger
--
DROP TRIGGER IF EXISTS acs_objects_context_id_del_tr ON acs_objects;
DROP FUNCTION IF EXISTS acs_objects_context_id_del_tr();

--
-- alter FK constraints of symlinks to cascade
--
ALTER TABLE cr_symlinks DROP CONSTRAINT IF EXISTS cr_symlinks_target_id_fk;
ALTER TABLE cr_symlinks ADD CONSTRAINT cr_symlinks_target_id_fk
FOREIGN KEY (target_id) REFERENCES cr_items(item_id) ON DELETE CASCADE;

--
-- procedure content_item__del/1
--
CREATE OR REPLACE FUNCTION content_item__del(
   delete__item_id integer
) RETURNS integer AS $$
DECLARE
  v_revision_val record;
  v_child_val record;
BEGIN
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
  -- Delete all children of this item via a recursive call.
  --
  -- The following loop is just needed to delete the revisions of
  -- child items. It could be removed, when proper foreign keys are
  -- used along the inheritance path of cr_content_revisions (which is
  -- not enforced and not always the case).
  --
  for v_child_val in select item_id
                      from   cr_items
                      where  parent_id = delete__item_id 
  LOOP     
     PERFORM content_item__delete(v_child_val.item_id);
  end loop; 

  --
  -- Finally, delete the acs_object of the item.
  --
  PERFORM acs_object__delete(delete__item_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;


--
-- The content_search__dtrg tries to add entries on deletion the
-- search queue via
--
--      SELECT search_observer__enqueue(old.revision_id,'DELETE')
--
-- However, we do not need to queue the revision_id for deletion,
-- since the content-repository uses always the revision_id as
-- object_id. It might be a problem, if there would be a way to use
-- the item_id as object_id for search and to remove content based on
-- the revision_id, but this does not seem to be possible. If i am
-- wrong, one has to revive content_search__dtrg.
--
-- Since the search_observer_queue and txt have FK with cascades,
-- there is no need for an extra trigger
--
DROP TRIGGER IF EXISTS content_search__dtrg ON cr_revisions;
DROP FUNCTION IF EXISTS content_search__dtrg();

