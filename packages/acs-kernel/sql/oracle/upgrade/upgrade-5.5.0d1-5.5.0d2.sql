alter table auth_authorities add allow_user_entered_info_p char(1);
update auth_authorities set allow_user_entered_info_p = 'f';
alter table auth_authorities modify (allow_user_entered_info_p not null);
alter table auth_authorities add constraint auth_auth_allow_user_i_ck
                             check (allow_user_entered_info_p in ('t','f'));
alter table auth_authorities modify (allow_user_entered_info_p default 'f');
alter table auth_authorities add search_impl_id integer;
alter table auth_authorities add constraint auth_auth_search_impl_id_fk foreign key (search_impl_id) references acs_objects(object_id);
