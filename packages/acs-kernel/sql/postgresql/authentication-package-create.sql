-- P/pgLSQL packages for the authentication datamodel
--
-- @author Peter Marklund
-- @creation-date 2003-08-21



-- added
select define_function_args('authority__new','authority_id;null,object_type;authority,short_name,pretty_name,enabled_p;t,sort_order,auth_impl_id;null,pwd_impl_id;null,forgotten_pwd_url;null,change_pwd_url;null,register_impl_id;null,register_url;null,help_contact_text;null,creation_user;null,creation_ip;null,context_id;null');

--
-- procedure authority__new/16
--
CREATE OR REPLACE FUNCTION authority__new(
   p_authority_id integer,      -- default null,
   p_object_type varchar,       -- default 'authority'
   p_short_name varchar,
   p_pretty_name varchar,
   p_enabled_p boolean,         -- default 't'
   p_sort_order integer,
   p_auth_impl_id integer,      -- default null
   p_pwd_impl_id integer,       -- default null
   p_forgotten_pwd_url varchar, -- default null
   p_change_pwd_url varchar,    -- default null
   p_register_impl_id integer,  -- default null
   p_register_url varchar,      -- default null
   p_help_contact_text varchar, -- default null,
   p_creation_user integer,     -- default null
   p_creation_ip varchar,       -- default null
   p_context_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  
    v_authority_id           integer;
    v_object_type            varchar;    
    v_sort_order             integer;
  
BEGIN
    if p_object_type is null then
        v_object_type := 'authority';
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
        't',
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
END;

$$ LANGUAGE plpgsql;



-- added
select define_function_args('authority__del','authority_id');

--
-- procedure authority__del/1
--
CREATE OR REPLACE FUNCTION authority__del(
   p_authority_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
  perform acs_object__delete(p_authority_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;
