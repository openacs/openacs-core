-- P/pgLSQL packages for the authentication datamodel
--
-- @author Peter Marklund
-- @creation-date 2003-08-21

create or replace function authority__new (
    integer, -- authority_id
    varchar, -- object_type
    varchar, -- short_name
    varchar, -- pretty_name
    boolean, -- enabled_p
    integer, -- sort_order
    integer, -- auth_impl_id
    integer, -- pwd_impl_id
    varchar, -- forgotten_pwd_url
    varchar, -- change_pwd_url
    integer, -- register_impl_id
    varchar, -- register_url
    varchar, -- help_contact_text
    integer, -- creation_user
    varchar, -- creation_ip
    integer  -- context_id
)
returns integer as '
declare
    p_authority_id alias for $1; -- default null,
    p_object_type alias for $2; -- default ''authority''
    p_short_name alias for $3;
    p_pretty_name alias for $4;
    p_enabled_p alias for $5; -- default ''t''
    p_sort_order alias for $6;
    p_auth_impl_id alias for $7; -- default null
    p_pwd_impl_id alias for $8; -- default null
    p_forgotten_pwd_url alias for $9; -- default null
    p_change_pwd_url alias for $10; -- default null
    p_register_impl_id alias for $11; -- default null
    p_register_url alias for $12; -- default null
    p_help_contact_text alias for $13; -- default null,
    p_creation_user alias for $14; -- default null
    p_creation_ip alias for $15; -- default null
    p_context_id alias for $16; -- default null
  
    v_authority_id           integer;
    v_object_type            varchar;    
    v_sort_order             integer;
  
begin
    if p_object_type is null then
        v_object_type := ''authority'';
    else
        v_object_type := p_object_type;
    end if;

    if p_sort_order is null then
          select into v_sort_order max(sort_order) + 1
                         from auth_authorities;
    else
        v_sort_order := p_sort_order;
    end if;

    -- Instantiate the ACS Object super type with auditing info
    v_authority_id  := acs_object__new(
        p_authority_id,
        v_object_type,
        now(),
        p_creation_user,
        p_creation_ip,
        p_context_id,
        ''t'',
        p_short_name,
        null
    );

    insert into auth_authorities (authority_id, short_name, pretty_name, enabled_p, 
                                  sort_order, auth_impl_id, pwd_impl_id, 
                                  forgotten_pwd_url, change_pwd_url, register_impl_id,
                                  help_contact_text)
    values (v_authority_id, p_short_name, p_pretty_name, p_enabled_p, 
                                  v_sort_order, p_auth_impl_id, p_pwd_impl_id, 
                                  p_forgotten_pwd_url, p_change_pwd_url, p_register_impl_id,
                                  p_help_contact_text);

   return v_authority_id;
end;
' language 'plpgsql';

create or replace function authority__del (integer)
returns integer as '
declare
  p_authority_id            alias for $1;
begin
  perform acs_object__delete(p_authority_id);

  return 0; 
end;' language 'plpgsql';
