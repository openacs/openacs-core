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
                             constraint auth_authorities_pk
                             primary key
                             constraint auth_authorities_aid_fk
                             references acs_objects(object_id)
                             on delete cascade,
    short_name               varchar(255)
                             constraint auth_authority_short_name_un
                             unique,
    pretty_name              varchar(4000),
    help_contact_text        varchar(4000),
    enabled_p                boolean default 't' 
                             constraint auth_authority_enabled_p_nn
                             not null,
    sort_order               integer not null,
    -- Id of the authentication service contract implementation
    -- Cannot reference acs_sc_impls table as it doesn't exist yet
    auth_impl_id             integer
                             constraint auth_authority_auth_impl_fk
                             references acs_objects(object_id),
    -- Id of the password management service contact implementation
    pwd_impl_id              integer
                             constraint auth_authority_pwd_impl_fk
                             references acs_objects(object_id),
    forgotten_pwd_url        varchar(4000),
    change_pwd_url           varchar(4000),
    -- Id of the registration service contract implementation
    register_impl_id         integer
                             constraint auth_authority_reg_impl_fk
                             references acs_objects(object_id),
    register_url             varchar(4000)
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

-- Create PLSQL package
\i authentication-package-create.sql

-- Create the local authority
select authority__new(
    null,              -- authority_id
    null,              -- object_type
    'local',           -- short_name
    'OpenACS Local',   -- pretty_name 
    't',               -- enabled_p
    1,                 -- sort_order
    null,              -- auth_impl_id
    null,              -- pwd_impl_id
    null,              -- forgotten_pwd_url
    null,              -- change_pwd_url
    null,              -- register_impl_id
    null,              -- register_url
    null,              -- help_contact_text
    null,              -- creation_user
    null,              -- creation_ip
    null               -- context_id
);
