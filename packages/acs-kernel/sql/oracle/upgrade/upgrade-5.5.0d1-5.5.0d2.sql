alter table auth_authorities add allow_user_entered_info_p;
update auth_authorities set allow_user_entered_info_p 'f';
alter table auth_authorities add constraint auth_authority_allow_user_i_p_nn (allow_user_entered_email_p) not null;
alter table auth_authorities add constraint auth_authority_allow_user_i_ck
                             check (allow_user_entered_info_p in ('t','f'))
alter table auth_authorities alter allow_user_entered_info_p set default 'f';
alter table auth_authorities add search_impl_id integer;
alter table auth_authorities add constraint foreign key auth_authorities_search_impl_id_fk (auth_authorities_search_impl_id) references acs_objects(object_id);
