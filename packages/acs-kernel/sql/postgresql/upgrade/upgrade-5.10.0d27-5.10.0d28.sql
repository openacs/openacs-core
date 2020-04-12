--
-- create index since column is used as foreign key
--
CREATE INDEX IF NOT EXISTS group_elem_idx_container_idx ON group_element_index(container_id);
