alter table auth_authorities add allow_user_entered_info_p boolean;
update auth_authorities set allow_user_entered_info_p='f';
alter table auth_authorities alter allow_user_entered_info_p set default 'f';
alter table auth_authorities add constraint auth_authority_allow_user_i_p_nn (allow_user_entered_email_p) not null;
alter table auth_authorities add search_impl_id integer constraint auth_authorities_search_impl_id_fk references acs_objects(object_id);