-- Modernize SQL existence test: make these more readable and faster

--
-- procedure acs_user__new/16
--
CREATE OR REPLACE FUNCTION acs_user__new(
   p_user_id integer,           -- default null
   p_object_type varchar,       -- default 'user'
   p_creation_date timestamptz, -- default now()
   p_creation_user integer,     -- default null
   p_creation_ip varchar,       -- default null
   p_authority_id integer,      -- defaults to local authority
   p_username varchar, 
   p_email varchar,
   p_url varchar,               -- default null
   p_first_names varchar,
   p_last_name varchar,
   p_password char,
   p_salt char,
   p_screen_name varchar,       -- default null
   p_email_verified_p boolean,  -- default 't'
   p_context_id integer         -- default null

) RETURNS integer AS $$
DECLARE
    v_user_id                  users.user_id%TYPE;
    v_authority_id             auth_authorities.authority_id%TYPE;
    v_person_exists            integer;			
BEGIN
    v_user_id := p_user_id;

    select 1 from persons into v_person_exists where person_id = v_user_id;

    if NOT FOUND then
        v_user_id := person__new(
            v_user_id, 
            p_object_type,
            p_creation_date, 
            p_creation_user, 
            p_creation_ip,
            p_email, 
            p_url, 
            p_first_names, 
            p_last_name, 
            p_context_id
        );
    else
     update acs_objects set object_type = 'user' where object_id = v_user_id;
    end if;

    -- default to local authority
    if p_authority_id is null then
        select authority_id
        into   v_authority_id
        from   auth_authorities
        where  short_name = 'local';
    else
        v_authority_id := p_authority_id;
    end if;

    insert into users
       (user_id, authority_id, username, password, salt, screen_name, email_verified_p)
    values
       (v_user_id, v_authority_id, p_username, p_password, p_salt, p_screen_name, p_email_verified_p);

    insert into user_preferences
      (user_id)
      values
      (v_user_id);

    return v_user_id;
  
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION acs_user__receives_alerts_p(
   receives_alerts_p__user_id integer
) RETURNS boolean AS $$
DECLARE
  found_p boolean;       
BEGIN
  select EXISTS into found_p (
        select 1 from users
        where no_alerts_until >= now()
        and user_id = receives_alerts_p__user_id
  );

  return found_p;
END;
$$ LANGUAGE plpgsql stable;

