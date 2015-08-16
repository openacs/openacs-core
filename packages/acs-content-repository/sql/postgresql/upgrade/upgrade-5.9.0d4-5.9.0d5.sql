alter table cr_items drop constraint cr_items_live_fk;
alter table cr_items drop constraint cr_items_latest_fk;

alter table cr_items add constraint cr_items_live_revision_fk 
      foreign key (live_revision) references cr_revisions(revision_id) on delete set null;

alter table cr_items add constraint cr_items_latest_revision_fk 
     foreign key (latest_revision) references cr_revisions(revision_id) on delete set null;
