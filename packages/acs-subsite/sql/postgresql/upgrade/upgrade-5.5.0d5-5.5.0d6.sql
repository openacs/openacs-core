
-- old define_function_args('application_group__new','group_id,object_type;application_group,creation_date;now(),creation_user,creation_ip,email,url,group_name,package_id,join_policy,context_id')
-- new
select define_function_args('application_group__new','group_id,object_type;application_group,creation_date;now(),creation_user;null,creation_ip;null,email;null,url;null,group_name,package_id,join_policy,context_id;null');




--
-- procedure application_group__new/11
--
CREATE OR REPLACE FUNCTION application_group__new(
   new__group_id integer,
   new__object_type varchar,       -- default 'application_group',
   new__creation_date timestamptz, -- default sysdate, -- default 'now()'
   new__creation_user integer,     -- default null,
   new__creation_ip varchar,       -- default null,
   new__email varchar,             -- default null,
   new__url varchar,               -- default null,
   new__group_name varchar,
   new__package_id integer,
   new__join_policy varchar,
   new__context_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_group_id		     application_groups.group_id%TYPE;
BEGIN
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

END;
$$ LANGUAGE plpgsql;

