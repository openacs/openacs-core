select define_function_args('application_group__new','group_id,object_type;application_group,creation_date;now(),creation_user,creation_ip,email,url,group_name,package_id,join_policy,context_id');

create or replace function application_group__new(integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,integer,varchar,integer)
returns integer as '
declare
  new__group_id              alias for $1;
  new__object_type           alias for $2; -- default ''application_group'',
  new__creation_date         alias for $3; -- default sysdate,
  new__creation_user         alias for $4; -- default null,
  new__creation_ip           alias for $5; -- default null,
  new__email                 alias for $6; -- default null,
  new__url                   alias for $7; -- default null,
  new__group_name            alias for $8;
  new__package_id            alias for $9;
  new__join_policy           alias for $10;
  new__context_id	     alias for $11; -- default null
  v_group_id		     application_groups.group_id%TYPE;
begin
  v_group_id := acs_group__new (
    new__group_id,
    new__object_type,
    new__creation_date,
    new__creation_user,
    new__creation_ip,
    new__email,
    new__url,
    new__group_name,
    new__join_policy,
    new__context_id
  );

  insert into application_groups (group_id, package_id) 
    values (v_group_id, new__package_id);

  return v_group_id;

end;' language 'plpgsql';

