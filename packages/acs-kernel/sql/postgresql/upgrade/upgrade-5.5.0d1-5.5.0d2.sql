alter table auth_authorities add allow_user_entered_info_p boolean;
update auth_authorities set allow_user_entered_info_p='f';
alter table auth_authorities alter allow_user_entered_info_p set default 'f';
alter table auth_authorities alter column  allow_user_entered_info_p set not null;
alter table auth_authorities add search_impl_id integer;
alter table auth_authorities add constraint auth_authorities_search_impl_id_fk foreign key (search_impl_id) references acs_objects(object_id);