--
-- acs-kernel/sql/postgresql/authentication-create.sql
--
-- The OpenACS core authentication system. 
--
-- @author Peter Marklund (peter@collaboraid.biz)
--
-- @creation-date 20003-08-21
--
-- @cvs-id $Id$
--

create table auth_authorities (
    authority_id             integer
                             constraint auth_authorities_auth_id_pk
                             primary key
                             constraint auth_authorities_auth_id_fk
                             references acs_objects(object_id)
                             on delete cascade,
    short_name               varchar(255)
                             constraint auth_authorities_short_name_un
                             unique,
    pretty_name              varchar(4000),
    help_contact_text        varchar(4000),
    help_contact_text_format varchar(200),
    enabled_p                boolean default 't' 
                             constraint auth_authorities_enbl_p_nn
                             not null,
    sort_order               integer not null,
    -- auth_authentication implementation
    -- (Cannot reference acs_sc_impls table as it doesn't exist yet)
    auth_impl_id             integer
                             constraint auth_authorities_auth_impl_fk
                             references acs_objects(object_id),
    -- auth_password implementation
    pwd_impl_id              integer
                             constraint auth_authorities_pwd_impl_fk
                             references acs_objects(object_id),
    forgotten_pwd_url        varchar(4000),
    change_pwd_url           varchar(4000),
    -- auth_registration implementation
    register_impl_id         integer
                             constraint auth_authorities_reg_impl_fk
                             references acs_objects(object_id),
    register_url             varchar(4000),
    -- auth_user_info implementation
    user_info_impl_id        integer
                             constraint auth_authorities_urinf_ipl_fk
                             references acs_objects(object_id),
    -- batch sync
    -- auth_sync_retrieve implementation
    get_doc_impl_id          integer 
                             constraint auth_authorities_getdoc_ipl_fk
                             references acs_objects(object_id),
    -- auth_sync_process implementation
    process_doc_impl_id      integer 
                             constraint auth_authorities_procdoc_ipl_fk
                             references acs_objects(object_id),
    batch_sync_enabled_p     boolean default 'f'
                             constraint auth_authorities_bsenabled_p_nn
                             not null
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
select acs_object_type__create_type (
    'authority',
    'Authority',
    'Authorities',
    'acs_object',
    'auth_authorities',
    'authority_id',
    null,
    'f',
    null,
    null
);

create table auth_driver_params(
    authority_id             integer
                             constraint auth_driver_params_aid_fk 
                             references auth_authorities(authority_id)
                             constraint auth_driver_params_aid_nn
                             not null,
    impl_id                  integer
                             constraint auth_driver_params_impl_id_fk
                             -- Cannot reference acs_sc_impls table as it doesn't exist yet
                             references acs_objects(object_id)
                             constraint auth_driver_params_impl_id_nn
                             not null,
    key                      varchar(200),
    value                    text,
    constraint auth_driver_params_pk
    primary key (authority_id, impl_id, key)
);

-- Create PLSQL package
\i authentication-package-create.sql
