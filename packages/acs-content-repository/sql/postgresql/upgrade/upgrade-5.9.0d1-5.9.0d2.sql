-- 
-- Ancient version of PostgreSQL (most likely before pg8) had a
-- bug in the handling of referential integrities (sometimes referred
-- to as the RI bug) which made extra triggers necessary. AFIKT,
-- this bug is gone and now the triggers should be removed as well
-- and replaced by fk constraints (sometimes already done).
-- 
-- 
-- Some old installations (like openacs.org) have still the following
-- functions although the create script do not define this triggers.
-- It seems that an update script was missing.
-- 
DROP TRIGGER IF EXISTS cr_folder_del_ri_trg ON cr_items;
DROP FUNCTION IF EXISTS cr_folder_del_ri_trg();

DROP TRIGGER IF EXISTS cr_folder_ins_up_ri_trg ON cr_folders;
DROP FUNCTION IF EXISTS cr_folder_ins_up_ri_trg();

-- 
-- Handle latest_revision and live_revision via foreign keys
--
ALTER TABLE cr_items DROP CONSTRAINT IF EXISTS cr_items_latest_fk;
ALTER TABLE cr_items ADD CONSTRAINT cr_items_latest_fk
FOREIGN KEY (latest_revision) REFERENCES cr_revisions(revision_id);

ALTER TABLE cr_items DROP CONSTRAINT IF EXISTS cr_items_live_fk;
ALTER TABLE cr_items ADD CONSTRAINT cr_items_live_fk
FOREIGN KEY (live_revision) REFERENCES cr_revisions(revision_id);


DROP TRIGGER IF EXISTS cr_revision_del_ri_tr on cr_items;
DROP FUNCTION IF EXISTS cr_revision_del_ri_tr();

DROP TRIGGER IF EXISTS cr_revision_ins_ri_tr on cr_items;
DROP FUNCTION IF EXISTS cr_revision_ins_ri_tr();

DROP TRIGGER IF EXISTS cr_revision_up_ri_tr on cr_items;
DROP FUNCTION IF EXISTS cr_revision_up_ri_tr();

DROP TRIGGER IF EXISTS cr_revision_del_rev_ri_tr on cr_revisions;
DROP FUNCTION IF EXISTS cr_revision_del_rev_ri_tr();
