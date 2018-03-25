
begin;

-- apisano 2018-02-21:
-- - added proper removal of cr_child_rels when item is deleted.
-- - streamlined idioms
-- - added missing on delete cascade
-- - removed dead acs_objects formerly linked to deleted cr_child_rels

-- Cleanup

-- This is not done unless uncommented, because could take a long time on busy sites!
-- -- delete dead tuples coming from sins of the past (mostly erased portraits)
-- select acs_object__delete(object_id) from acs_objects o
--  where object_type = 'cr_item_child_rel' and
--    not exists (select 1 from cr_child_rels where rel_id = o.object_id);


-- Data model upgrade

alter table images
  -- current name of the constraint
  drop constraint if exists images_image_id_fk,
  -- old name of the same constraint in old databases
  drop constraint if exists "$1",
  add constraint images_image_id_fk foreign key (image_id)
     references cr_revisions(revision_id) on delete cascade;

alter table cr_revision_attributes
  drop constraint cr_revision_attributes_fk,
  add constraint cr_revision_attributes_fk foreign key (revision_id)
     references cr_revisions(revision_id) on delete cascade;

--
-- procedure content_item__del/1
--
CREATE OR REPLACE FUNCTION content_item__del(
   delete__item_id integer
) RETURNS integer AS $$
BEGIN

  -- Also child relationships must be deleted. On delete cascade
  -- would not help here, as related acs_object would stay.
  PERFORM acs_object__delete(object_id)
    from acs_objects where object_id in 
    (select rel_id from cr_child_rels where
         child_id  = delete__item_id or
         parent_id = delete__item_id);

  --
  -- Delete all revisions of this item
  --
  -- On delete cascade should work for us, but not in case of
  -- relationships. Therefore, we call acs_object__delete explicitly
  -- on the revisions. Is is also safer in general, as referential
  -- integrity might not have been enforced every time.
  --
  PERFORM acs_object__delete(revision_id)
    from cr_revisions where item_id = delete__item_id;

  --
  -- Delete all children of this item via a recursive call.
  --
  -- On delete cascade should work for us, but not in case of
  -- relationships. Therefore, we call acs_object__delete explicitly
  -- on the revisions. Is is also safer in general, as referential
  -- integrity might not have been enforced every time.
  --
  PERFORM content_item__delete(item_id)
    from cr_items where parent_id = delete__item_id;

  --
  -- Finally, delete the acs_object of the item.
  --      
  PERFORM acs_object__delete(delete__item_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;

end;
