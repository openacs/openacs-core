--
-- Avoid potential loops on parent_ids. An item must not be equal to
-- its own parent.  Note that this constraint is not guaranteed to
-- avoid all loops; it is still possible to create indirect recursive
-- loops but excludes some real-world problems.
--
--
-- Reduce the impact of adding a constraint on concurrent updates.
-- See: section on NOT VALID in https://www.postgresql.org/docs/current/sql-altertable.html
--
ALTER TABLE cr_items ADD CONSTRAINT cr_items_parent_id_ck CHECK (item_id != parent_id) NOT VALID;
ALTER TABLE cr_items VALIDATE CONSTRAINT cr_items_parent_id_ck;
