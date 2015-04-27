alter table application_groups drop constraint application_groups_group_id_fk;
alter table application_groups add constraint application_groups_group_id_fk foreign key (group_id) references groups(group_id) on delete cascade;
