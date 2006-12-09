create or replace function acs_rel__new (integer,varchar,integer,integer,integer,integer,varchar)
returns integer as '
declare
  new__rel_id            alias for $1;  -- default null  
  new__rel_type          alias for $2;  -- default ''relationship''
  new__object_id_one     alias for $3;  
  new__object_id_two     alias for $4;  
  context_id             alias for $5;  -- default null
  creation_user          alias for $6;  -- default null
  creation_ip            alias for $7;  -- default null
  v_rel_id               acs_rels.rel_id%TYPE;
begin
    -- XXX This should check that object_id_one and object_id_two are
    -- of the appropriate types.

    LOCK TABLE acs_objects IN SHARE ROW EXCLUSIVE MODE;

    v_rel_id := acs_object__new (
      new__rel_id,
      new__rel_type,
      now(),
      creation_user,
      creation_ip,
      context_id,
      ''t'',
      new__rel_type || '': '' || new__object_id_one || '' - '' || new__object_id_two,
      null
    );

    insert into acs_rels
     (rel_id, rel_type, object_id_one, object_id_two)
    values
     (v_rel_id, new__rel_type, new__object_id_one, new__object_id_two);

    return v_rel_id;
   
end;' language 'plpgsql';

-- fix package instance names in acs_objects in case of renames
update acs_objects set title = s.instance_name from (select p.instance_name, p.package_id from acs_objects o, apm_packages p where o.object_id = p.package_id and p.instance_name <> o.title) as s where object_id = s.package_id;

