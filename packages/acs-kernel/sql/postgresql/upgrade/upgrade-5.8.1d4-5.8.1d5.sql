alter table acs_attributes drop constraint acs_attributes_datatype_fk; 
alter table acs_attributes add constraint acs_attributes_datatype_fk 
   foreign key (datatype) 
   references acs_datatypes(datatype) on update cascade;
