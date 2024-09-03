--
-- Avoid duplicate entries in acs_sc_msg_type_elements.
--
-- The three columns msg_type_id, element_name, and
-- element_msg_type_id identify the paramter uniquely, and must be
-- therefore not null.
--
ALTER TABLE acs_sc_msg_type_elements ALTER COLUMN msg_type_id SET NOT NULL;
ALTER TABLE acs_sc_msg_type_elements ALTER COLUMN element_name SET NOT NULL;
ALTER TABLE acs_sc_msg_type_elements ALTER COLUMN element_msg_type_id SET NOT NULL;

ALTER TABLE acs_sc_msg_type_elements DROP CONSTRAINT IF EXISTS acs_sc_msg_type_el_un;
ALTER TABLE acs_sc_msg_type_elements ADD CONSTRAINT acs_sc_msg_type_el_un UNIQUE (msg_type_id, element_name, element_msg_type_id );
