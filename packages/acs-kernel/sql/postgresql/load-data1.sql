


insert into acs_object_types (object_type,supertype) 
                              values 
                             ('acs_object', null);
insert into acs_object_types (object_type,supertype) 
                              values 
                             ('relationship', 'acs_object');
insert into acs_object_types (object_type,supertype) 
                              values 
                             ('party', 'acs_object');
insert into acs_object_types (object_type,supertype) 
                              values 
                             ('person', 'party');
insert into acs_object_types (object_type,supertype) 
                              values 
                             ('user', 'person');
insert into acs_object_types (object_type,supertype) 
                              values 
                             ('group', 'party');
insert into acs_object_types (object_type,supertype) 
                              values 
                             ('membership_rel', 'acs_object');
insert into acs_object_types (object_type,supertype) 
                              values 
                             ('composition_rel', 'acs_object');
insert into acs_object_types (object_type,supertype) 
                              values 
                             ('journal_entry', 'acs_object');
insert into acs_object_types (object_type,supertype) 
                              values 
                             ('site_node', 'acs_object');

