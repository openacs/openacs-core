alter table cr_revisions
drop constraint cr_revisions_lob_fk;

alter table cr_revisions
add constraint cr_revisions_lob_fk
foreign key (lob) references lobs on delete set null;
