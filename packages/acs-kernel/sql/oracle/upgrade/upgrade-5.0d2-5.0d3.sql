-- 
-- Upgrade script from 5.0d2 to 5.0d3
--
-- @author Peter Marklund (peter@collaboraid.biz)
--
-- @cvs-id $Id$
--

-- ****** New authentication datamodel

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
create or replace package authority
as 
    function new(
        authority_id in auth_authorities.authority_id%TYPE default null,
        object_type acs_object_types.object_type%TYPE default 'authority',
        short_name in auth_authorities.short_name%TYPE,
        pretty_name in auth_authorities.pretty_name%TYPE,
        enabled_p in auth_authorities.enabled_p%TYPE default 't',
        sort_order in auth_authorities.sort_order%TYPE,
        auth_impl_id in auth_authorities.auth_impl_id%TYPE default null,
        pwd_impl_id in auth_authorities.pwd_impl_id%TYPE default null,
        forgotten_pwd_url in auth_authorities.forgotten_pwd_url%TYPE default null,
        change_pwd_url in auth_authorities.change_pwd_url%TYPE default null,
        register_impl_id in auth_authorities.register_impl_id%TYPE default null,
        register_url in auth_authorities.register_url%TYPE default null,
        help_contact_text in auth_authorities.help_contact_text%TYPE default null,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    ) return integer;

    function del(
        delete_authority_id in auth_authorities.authority_id%TYPE
    ) return integer;

end authority;
/
show errors

create or replace package body authority
as 
    function new(
        authority_id in auth_authorities.authority_id%TYPE default null,
        object_type acs_object_types.object_type%TYPE default 'authority',
        short_name in auth_authorities.short_name%TYPE,
        pretty_name in auth_authorities.pretty_name%TYPE,
        enabled_p in auth_authorities.enabled_p%TYPE default 't',
        sort_order in auth_authorities.sort_order%TYPE,
        auth_impl_id in auth_authorities.auth_impl_id%TYPE default null,
        pwd_impl_id in auth_authorities.pwd_impl_id%TYPE default null,
        forgotten_pwd_url in auth_authorities.forgotten_pwd_url%TYPE default null,
        change_pwd_url in auth_authorities.change_pwd_url%TYPE default null,
        register_impl_id in auth_authorities.register_impl_id%TYPE default null,
        register_url in auth_authorities.register_url%TYPE default null,
        help_contact_text in auth_authorities.help_contact_text%TYPE default null,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip in acs_objects.creation_ip%TYPE default null,
        context_id in acs_objects.context_id%TYPE default null
    )
    return integer
    is
        v_authority_id integer; 
        v_sort_order integer;        
    begin
        if sort_order is null then
          select max(sort_order) + 1
                 into v_sort_order
                 from auth_authorities;
        else
           v_sort_order := sort_order;
        end if;


        v_authority_id  := acs_object.new(
            object_id     => new.authority_id,
            object_type   => new.object_type,
            creation_date => sysdate(),
            creation_user => new.creation_user,
            creation_ip   => new.creation_ip,
            context_id    => new.context_id
        );

        insert into auth_authorities (authority_id, short_name, pretty_name, enabled_p, 
                                      sort_order, auth_impl_id, pwd_impl_id, 
                                      forgotten_pwd_url, change_pwd_url, register_impl_id,
                                      help_contact_text)
        values (v_authority_id, new.short_name, new.pretty_name, new.enabled_p, 
                                      v_sort_order, new.auth_impl_id, new.pwd_impl_id, 
                                      new.forgotten_pwd_url, new.change_pwd_url, new.register_impl_id, 
                                      new.help_contact_text);

        return v_authority_id;
    end new;

    function del(
        delete_authority_id in auth_authorities.authority_id%TYPE
    )
    return integer
    is
    begin
        acs_object.del(delete_authority_id);

        return 0;
    end del;

end authority;
/
show errors


-- Create the local authority
declare
  v_authority_id integer;
begin 
    v_authority_id := authority.new(
        short_name  => 'local',
        pretty_name => 'OpenACS Local',
        sort_order  => '1'
    );
end;
/
show errors


-- ****** Changes to the users table

alter table users add authority_id            integer
                                constraint users_auth_authorities_fk
                                references auth_authorities(authority_id);

alter table users add username  varchar2(100) default '-'
                                constraint users_username_nn 
                                not null;

-- set all current users' username to equal their email
-- and their authority to be the local authority
-- Exclude the unregistered visitor as he/she has a null email
update users 
set    username = (select email 
                   from parties 
                   where party_id = user_id),
       authority_id = (select authority_id from auth_authorities where short_name = 'local')
where user_id <> 0;

-- add a unique constraint
alter table users add constraint users_authority_username_un unique (authority_id, username);

-- Need to recreate the cc_users view
create or replace view cc_users
as
select o.*, pa.*, pe.*, u.*, mr.member_state, mr.rel_id
from acs_objects o, parties pa, persons pe, users u, group_member_map m, membership_rels mr
where o.object_id = pa.party_id
and pa.party_id = pe.person_id
and pe.person_id = u.user_id
and u.user_id = m.member_id
and m.group_id = acs.magic_object_id('registered_users')
and m.rel_id = mr.rel_id
and m.container_id = m.group_id;

