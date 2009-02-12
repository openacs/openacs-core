-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2009-02-11
-- @cvs-id $Id$
--


create or replace function acs_group__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__group_id              alias for $1;  -- default null  
  new__object_type           alias for $2;  -- default ''group''
  new__creation_date         alias for $3;  -- default now()
  new__creation_user         alias for $4;  -- default null
  new__creation_ip           alias for $5;  -- default null
  new__email                 alias for $6;  -- default null
  new__url                   alias for $7;  -- default null
  new__group_name            alias for $8;  
  new__join_policy           alias for $9;  -- default null
  new__context_id            alias for $10; -- default null
  v_group_id                 groups.group_id%TYPE;
  v_group_type_exists_p      integer;
  v_join_policy              groups.join_policy%TYPE;
begin
  v_group_id :=
   party__new(new__group_id, new__object_type, new__creation_date, 
              new__creation_user, new__creation_ip, new__email, 
              new__url, new__context_id);

  v_join_policy := new__join_policy;

  -- if join policy was not specified, select the default based on group type
  if v_join_policy is null or v_join_policy = '''' then
      select count(*) into v_group_type_exists_p
      from group_types
      where group_type = new__object_type;

      if v_group_type_exists_p = 1 then
          select default_join_policy into v_join_policy
          from group_types
          where group_type = new__object_type;
      else
          v_join_policy := ''open'';
      end if;
  end if;

  update acs_objects
  set title = new__group_name
  where object_id = v_group_id;

  insert into groups
   (group_id, group_name, join_policy)
  values
   (v_group_id, new__group_name, v_join_policy);

  -- setup the permissible relationship types for this group

  -- DRB: we have to call nextval() directly because the select may
  -- return more than one row.  The sequence hack will only compute
  -- one nextval value causing the insert to fail ("may" in PG, which
  -- is actually broken.  It should ALWAYS return exactly one value for
  -- the view.  In PG it may or may not depending on the optimizer''s
  -- mood.  PG group seems uninterested in acknowledging the fact that
  -- this is a bug)

  insert into group_rels
  (group_rel_id, group_id, rel_type)
  select nextval(''t_acs_object_id_seq''), v_group_id, rels.rel_type
    from
    ( select distinct g.rel_type
      from group_type_rels g,
      ( select parent.object_type as parent_type
        from acs_object_types child, acs_object_types parent
        where child.object_type <> parent.object_type
        and child.tree_sortkey between parent.tree_sortkey
        and tree_right(parent.tree_sortkey)
        and child.object_type = new__object_type
        order by parent.tree_sortkey desc) types
     where g.group_type = types.parent_type
     and not exists
     ( select 1 from group_rels
       where group_rels.group_id = v_group_id
       and group_rels.rel_type = g.rel_type)
  ) rels;
  
  return v_group_id;
  
end;' language 'plpgsql';
