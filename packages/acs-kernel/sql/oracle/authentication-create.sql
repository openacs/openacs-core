--
-- acs-kernel/sql/oracle/authentication-create.sql
--
-- The OpenACS core authentication system. 
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @creation-date 20003-05-13
--
-- @cvs-id $Id$
--

create table auth_authorities (
    authority_id             integer
                             constraint auth_authorities_pk
                             primary key
                             constraint auth_authorities_aid_fk
                             references acs_objects(object_id)
                             on delete cascade,
    short_name               varchar2(255)
                             constraint auth_authority_short_name_un
                             unique,
    pretty_name              varchar2(4000),
    help_contact_text        varchar2(4000),
    help_contact_text_format varchar(200),
    enabled_p                char(1) default 't' 
                             constraint auth_authority_enabled_p_nn
                             not null 
                             constraint auth_authority_enabled_p_ck
                             check (enabled_p in ('t','f')),
    sort_order               integer not null,
    -- auth_authentication implementation
    -- (Cannot reference acs_sc_impls table as it doesn't exist yet)
    auth_impl_id             integer
                             constraint auth_authority_auth_impl_fk
                             references acs_objects(object_id),
    -- auth_password implementation
    pwd_impl_id              integer
                             constraint auth_authority_pwd_impl_fk
                             references acs_objects(object_id),
    forgotten_pwd_url        varchar2(4000),
    change_pwd_url           varchar2(4000),
    -- auth_registration implementation
    register_impl_id         integer
                             constraint auth_authority_reg_impl_fk
                             references acs_objects(object_id),
    register_url             varchar2(4000),
    -- auth_user_info implementation
    user_info_impl_id        integer
                             constraint auth_authority_userinf_impl_fk
                             references acs_objects(object_id),
    -- batch sync
    -- auth_sync_retrieve implementation
    get_doc_impl_id          integer references acs_objects(object_id),
    -- auth_sync_process implementation
    process_doc_impl_id      integer references acs_objects(object_id),
    batch_sync_enabled_p     char(1) default 'f' 
                             constraint auth_authority_bs_enabled_p_nn
                             not null 
                             constraint auth_authority_bs_enabled_p_ck
                             check (batch_sync_enabled_p in ('t','f'))
);

comment on column auth_authorities.help_contact_text is '
    Contact information (phone, email, etc.) to be displayed
    as a last resort when people are having problems with an authority.
';

comment on column auth_authorities.forgotten_pwd_url is '
    Any username in this url must be on the syntax foo={username}
    and {username} will be replaced with the real username
';

comment on column auth_authorities.change_pwd_url is '
    Any username in this url must be on the syntax foo={username}
    and {username} will be replaced with the real username
';

-- Define the acs object type
begin
  acs_object_type.create_type (
    object_type => 'authority',
    pretty_name => 'Authority',
    pretty_plural => 'Authorities',
    supertype => 'acs_object',
    table_name => 'auth_authorities',
    id_column => 'authority_id',
    package_name => null,
    abstract_p => 'f',
    type_extension_table => null,
    name_method => null
  );
end;
/
show errors

create table auth_driver_params(
      authority_id    integer
                      constraint auth_driver_params_aid_fk 
                      references auth_authorities(authority_id)
                      constraint auth_driver_params_aid_nn
                      not null,
      impl_id         integer
                      constraint auth_driver_params_iid_fk
                      -- Cannot reference acs_sc_impls table as it doesn't exist yet
                      references acs_objects(object_id)
                      constraint auth_driver_params_iid_nn
                      not null,
      key             varchar2(200),
      value           clob,
      constraint auth_driver_params_pk
      primary key (authority_id, impl_id, key)
);

-- Create PLSQL package
@@ authentication-package-create

