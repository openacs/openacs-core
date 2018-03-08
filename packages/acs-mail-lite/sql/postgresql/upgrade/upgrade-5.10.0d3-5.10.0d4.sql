
-- add on delete cascade on foreign key constraints for acs_mail_lite_send_msg_id_map table

alter table acs_mail_lite_send_msg_id_map
  drop constraint if exists aml_package_id_fk,  
  add constraint aml_package_id_fk foreign key (package_id)
     references apm_packages(package_id) on delete cascade,
     
  drop constraint if exists aml_from_external_party_id_fk,     
  add constraint aml_from_external_party_id_fk foreign key (party_id)   
     references parties(party_id) on delete cascade,
                
  drop constraint if exists aml_from_external_obect_id_fk,     
  add constraint aml_from_external_object_id_fk foreign key (object_id)
     references acs_objects(object_id) on delete cascade;
