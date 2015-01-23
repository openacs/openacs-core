-- content_revision__del() uses cr_item_publish_audit.old_revision and
-- cr_item_publish_audit.new_revision to delete entries from
-- cr_item_publish_audit. This takes forever on non-toy databases.

create index cr_item_publish_audit_orev_idx on cr_item_publish_audit(old_revision);
create index cr_item_publish_audit_nrev_idx on cr_item_publish_audit(new_revision);

-- make sure, we can add the foreign keys
DELETE FROM cr_item_publish_audit a WHERE NOT EXISTS (SELECT 1 FROM cr_items i WHERE a.item_id = i.item_id);
DELETE FROM cr_item_publish_audit a WHERE NOT EXISTS (SELECT 1 FROM cr_revisions r WHERE a.old_revision = r.revision_id);
DELETE FROM cr_item_publish_audit a WHERE NOT EXISTS (SELECT 1 FROM cr_revisions r WHERE a.new_revision = r.revision_id);


-- add the foreign keys
alter table cr_item_publish_audit add constraint cr_item_publish_audit_item_fk foreign key (item_id) references cr_items (item_id);
alter table cr_item_publish_audit add constraint cr_item_publish_audit_orev_fk foreign key (old_revision) references cr_revisions (revision_id);
alter table cr_item_publish_audit add constraint cr_item_publish_audit_nrev_fk foreign key (new_revision) references cr_revisions (revision_id);
