select acs_privilege__add_child('admin', 'annotate');

-- adding missing cascade part
ALTER TABLE site_node_object_mappings DROP CONSTRAINT snom_object_id_fk;
ALTER TABLE site_node_object_mappings ADD CONSTRAINT snom_object_id_fk FOREIGN KEY (object_id) REFERENCES acs_objects (object_id) ON UPDATE CASCADE ON DELETE CASCADE;
