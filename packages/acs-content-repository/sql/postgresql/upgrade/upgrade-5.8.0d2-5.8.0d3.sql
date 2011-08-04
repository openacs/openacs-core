-- content_revision__del() uses cr_item_publish_audit.old_revision and
-- cr_item_publish_audit.new_revision to delete entries from
-- cr_item_publish_audit. This takes forever on non-toy databases.

create index cr_item_publish_audit_orev_idx on cr_item_publish_audit(old_revision);
create index cr_item_publish_audit_nrev_idx on cr_item_publish_audit(new_revision);

-- make sure, we can add the foreign keys
delete from cr_item_publish_audit where item_id not in (select item_id from cr_items);
delete from cr_item_publish_audit where old_revision not in (select revision_id from cr_revisions);
delete from cr_item_publish_audit where new_revision not in (select revision_id from cr_revisions);

-- add the foreign keys
alter table cr_item_publish_audit add constraint cr_item_publish_audit_item_fk foreign key (item_id) references cr_items (item_id);
alter table cr_item_publish_audit add constraint cr_item_publish_audit_orev_fk foreign key (old_revision) references cr_revisions (revision_id);
alter table cr_item_publish_audit add constraint cr_item_publish_audit_nrev_fk foreign key (new_revision) references cr_revisions (revision_id);
