--
-- Avoid duplicate entries in acs_sc_msg_type_elements.
--
-- The three columns msg_type_id, element_name, and
-- element_msg_type_id identify the paramter uniquely, and must be
-- therefore not null.
--
ALTER TABLE acs_sc_msg_type_elements MODIFY (
    msg_type_id		     integer NOT NULL
			     constraint acs_sc_msg_type_el_mtype_id_fk
			     references acs_sc_msg_types(msg_type_id)
			     on delete cascade,
    element_name	     varchar2(100) NOT NULL,
    element_msg_type_id	     integer NOT NULL
			     constraint acs_sc_msg_type_el_emti_id_fk
			     references acs_sc_msg_types(msg_type_id));

ALTER TABLE acs_sc_msg_type_elements ADD CONSTRAINT acs_sc_msg_type_el_un
UNIQUE (msg_type_id, element_name, element_msg_type_id );
