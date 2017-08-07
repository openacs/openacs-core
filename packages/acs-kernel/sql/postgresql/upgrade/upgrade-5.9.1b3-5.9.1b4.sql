
-- This data model change is not required for people installing
-- OpenACS from versions >= 5.2, but was never put in an upgrade
-- script and therefore older instances will need it.

begin;

-- make sure the old constraint names don't exist
alter table acs_rels drop constraint if exists acs_object_rels_one_fk;
alter table acs_rels drop constraint if exists acs_object_rels_two_fk;

-- create the new constraints if they don't exist already
DO $$
BEGIN
   BEGIN
      alter table acs_rels add constraint acs_rels_object_id_one_fk foreign key (object_id_one) references acs_objects(object_id) on delete cascade;
   EXCEPTION
      WHEN duplicate_object THEN RAISE NOTICE 'Table constraint acs_rels_object_id_one_fk already exists, skipping';
   END;
   BEGIN
      alter table acs_rels add constraint acs_rels_object_id_two_fk foreign key (object_id_two) references acs_objects(object_id) on delete cascade;
   EXCEPTION
      WHEN duplicate_object THEN RAISE NOTICE 'Table constraint acs_rels_object_id_two_fk already exists, skipping';
   END;
END $$;

end;
