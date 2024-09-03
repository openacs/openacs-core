--
-- Avoid potential loops on parent_ids. An item must not be equal to
-- its own parent.  Note that this constraint is not guaranteed to
-- avoid all loops; it is still possible to create indirect recursive
-- loops but excludes some real-world problems.
--
ALTER TABLE cr_items ADD CONSTRAINT cr_items_parent_id_ck CHECK (item_id != parent_id);
