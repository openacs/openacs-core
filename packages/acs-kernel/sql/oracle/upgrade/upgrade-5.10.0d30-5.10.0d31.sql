--
-- Avoid potential loops on context_ids. A context_id must be
-- different from the object_id. If no context_id should be checked, its
-- value must be NULL. Note that this constraint is not guaranteed to
-- avoid all loops; it is still possible to create indirect recursive
-- loops but excludes some real-world problems.
--
ALTER TABLE acs_objects ADD CONSTRAINT acs_objects_context_id_ck CHECK (context_id != object_id);
