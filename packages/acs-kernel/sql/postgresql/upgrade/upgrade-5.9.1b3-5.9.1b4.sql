
-- This data model change is not required for people installing
-- OpenACS from versions >= 5.2, but was never put in an upgrade
-- script and therefore older instances will need it.

begin;

alter table acs_rels drop constraint acs_rels_object_id_one_fk;
alter table acs_rels drop constraint acs_rels_object_id_two_fk;

alter table acs_rels add constraint acs_rels_object_id_one_fk foreign key (object_id_one) references acs_objects(object_id) on delete cascade;
alter table acs_rels add constraint acs_rels_object_id_two_fk foreign key (object_id_two) references acs_objects(object_id) on delete cascade;

end;
