--
-- Avoid potential loops on site_node parent_ids. A parent_id must be
-- different from the node_id. 
-- Note that this constraint is not guaranteed to avoid all loops; 
-- it is still possible to create indirect recursive
-- loops but excludes some real-world problems.
--
--
-- Reduce the impact of adding a constraint on concurrent updates.
-- See: section on NOT VALID in https://www.postgresql.org/docs/current/sql-altertable.html
--
ALTER TABLE site_nodes ADD CONSTRAINT site_nodes_parent_id_ck CHECK (node_id <> parent_id) NOT VALID;
ALTER TABLE site_nodes VALIDATE CONSTRAINT site_nodes_parent_id_ck;
