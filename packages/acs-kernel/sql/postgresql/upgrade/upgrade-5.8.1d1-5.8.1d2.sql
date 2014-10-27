--
-- procedure acs_object__new/9
--
CREATE OR REPLACE FUNCTION acs_object__new(
   new__object_id integer,          -- default null
   new__object_type varchar,        -- default 'acs_object'
   new__creation_date timestamptz,  -- default now()
   new__creation_user integer,      -- default null
   new__creation_ip varchar,        -- default null
   new__context_id integer,         -- default null
   new__security_inherit_p boolean, -- default 't'
   new__title varchar,              -- default null
   new__package_id integer          -- default null

) RETURNS integer AS $$
DECLARE
  v_object_id                 acs_objects.object_id%TYPE;
  v_creation_date	      timestamptz;
  v_title                     acs_objects.title%TYPE;
  v_object_type_pretty_name   acs_object_types.pretty_name%TYPE;
BEGIN
  if new__object_id is null then
    select nextval('t_acs_object_id_seq') into v_object_id;
  else
    v_object_id := new__object_id;
  end if;

  if new__title is null then
   select pretty_name
   into v_object_type_pretty_name
   from acs_object_types
   where object_type = new__object_type;

    v_title := v_object_type_pretty_name || ' ' || v_object_id;
  else
    v_title := new__title;
  end if;

  if new__creation_date is null then
   v_creation_date:= now();
  else
   v_creation_date := new__creation_date;
  end if;

  insert into acs_objects
   (object_id, object_type, title, package_id, context_id,
    creation_date, creation_user, creation_ip, security_inherit_p)
  values
   (v_object_id, new__object_type, v_title, new__package_id, new__context_id,
    v_creation_date, new__creation_user, new__creation_ip, 
    new__security_inherit_p);

  PERFORM acs_object__initialize_attributes(v_object_id);

  return v_object_id;
  
END;
$$ LANGUAGE plpgsql;
