--
-- packages/acs-kernel/sql/groups-body-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-08-22
-- @cvs-id $Id$
--

--------------
-- TRIGGERS --
--------------

-- The insert trigger was dummied up in groups-create.sql, so we just need
-- to replace the trigger function, not create the trigger.

-- However, PG 7.3 introduces a new type "trigger" for the return type
-- needed for functions called by triggers.  "create function" transmorgifies
-- the return type "opaque" to "trigger" so PG 7.2 dumps can be restored into
-- PG 7.3.  But "create or replace" doesn't do it.   We can't use "trigger"
-- because we currently are still supporting PG 7.2.  Isn't life a pleasure?

-- I'm leaving the triggers we aren't overriding as "create or replace" because
-- this will be the right thing to do if the PG folks fix this problem or when
-- we drop support of PG 7.2 and no longer need to declare these as type "opaque"

drop trigger membership_rels_in_tr on membership_rels;
drop function membership_rels_in_tr ();

create or replace function membership_rels_in_tr () returns opaque as '
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error         text;
  map             record;
begin
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint__violation(new.rel_id);
  if v_error is not null then
      raise EXCEPTION ''-20000: %'', v_error;
  end if;

  select object_id_one, object_id_two, rel_type
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels
  where rel_id = new.rel_id;

  -- Insert a row for me in the group_element_index.
  insert into group_element_index
   (group_id, element_id, rel_id, container_id, 
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, new.rel_id, v_object_id_one, 
    v_rel_type, ''membership_rel'');

  if new.member_state = ''approved'' then
    perform party_approved_member__add(v_object_id_one, v_object_id_two, new.rel_id, v_rel_type);
  end if;

  -- For all groups of which I am a component, insert a
  -- row in the group_element_index.
  for map in select distinct group_id
	      from group_component_map
	      where component_id = v_object_id_one 
  loop

    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    values
     (map.group_id, v_object_id_two, new.rel_id, v_object_id_one,
      v_rel_type, ''membership_rel'');

    if new.member_state = ''approved'' then
      perform party_approved_member__add(map.group_id, v_object_id_two, new.rel_id, v_rel_type);
    end if;

  end loop;

  return new;

end;' language 'plpgsql';

create trigger membership_rels_in_tr after insert on membership_rels
for each row execute procedure membership_rels_in_tr ();

create or replace function membership_rels_up_tr () returns opaque as '
declare
  map             record;
begin

  if new.member_state = old.member_state then
    return new;
  end if;

  for map in select group_id, element_id, rel_type
             from group_element_index
             where rel_id = new.rel_id
  loop
    if new.member_state = ''approved'' then
      perform party_approved_member__add(map.group_id, map.element_id, new.rel_id, map.rel_type);
    else
      perform party_approved_member__remove(map.group_id, map.element_id, new.rel_id, map.rel_type);
    end if;
  end loop;

  return new;

end;' language 'plpgsql';

create trigger membership_rels_up_tr before update on membership_rels
for each row execute procedure membership_rels_up_tr ();

create or replace function membership_rels_del_tr () returns opaque as '
declare
  v_error text;
  map             record;
begin
  -- First check if removing this relation would violate any relational constraints
  v_error := rel_constraint__violation_if_removed(old.rel_id);
  if v_error is not null then
      raise EXCEPTION ''-20000: %'', v_error;
  end if;

  for map in select group_id, element_id, rel_type
             from group_element_index
             where rel_id = old.rel_id
  loop
    perform party_approved_member__remove(map.group_id, map.element_id, old.rel_id, map.rel_type);
  end loop;

  delete from group_element_index
  where rel_id = old.rel_id;

  return old;

end;' language 'plpgsql';

create trigger membership_rels_del_tr before delete on membership_rels
for each row execute procedure membership_rels_del_tr ();

drop trigger composition_rels_in_tr on composition_rels;
drop function composition_rels_in_tr ();

create or replace function composition_rels_in_tr () returns opaque as '
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error         text;
  map             record;
begin
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint__violation(new.rel_id);

  if v_error is not null then
      raise EXCEPTION ''-20000: %'', v_error;
  end if;

  select object_id_one, object_id_two, rel_type
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels
  where rel_id = new.rel_id;

  -- Insert a row for me in group_element_index
  insert into group_element_index
   (group_id, element_id, rel_id, container_id,
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, new.rel_id, v_object_id_one,
    v_rel_type, ''composition_rel'');

  -- Add to the denormalized party_approved_member_map

  perform party_approved_member__add(v_object_id_one, member_id, rel_id, rel_type)
  from group_approved_member_map m
  where group_id = v_object_id_two
  and not exists (select 1
		  from group_element_map
		  where group_id = v_object_id_one
		  and element_id = m.member_id
		  and rel_id = m.rel_id);

  -- Make my elements be elements of my new composite group
  insert into group_element_index
   (group_id, element_id, rel_id, container_id,
    rel_type, ancestor_rel_type)
  select distinct
   v_object_id_one, element_id, rel_id, container_id,
   rel_type, ancestor_rel_type
  from group_element_map m
  where group_id = v_object_id_two
  and not exists (select 1
		  from group_element_map
		  where group_id = v_object_id_one
		  and element_id = m.element_id
		  and rel_id = m.rel_id);

  -- For all direct or indirect containers of my new composite group, 
  -- add me and add my elements
  for map in  select distinct group_id
	      from group_component_map
	      where component_id = v_object_id_one 
  LOOP

    -- Add a row for me

    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    values
     (map.group_id, v_object_id_two, new.rel_id, v_object_id_one,
      v_rel_type, ''composition_rel'');

    -- Add to party_approved_member_map

    perform party_approved_member__add(map.group_id, member_id, rel_id, rel_type)
    from group_approved_member_map m
    where group_id = v_object_id_two
    and not exists (select 1
		    from group_element_map
		    where group_id = map.group_id
		    and element_id = m.member_id
		    and rel_id = m.rel_id);

    -- Add rows for my elements

    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    select distinct
     map.group_id, element_id, rel_id, container_id,
     rel_type, ancestor_rel_type
    from group_element_map m
    where group_id = v_object_id_two
    and not exists (select 1
		    from group_element_map
		    where group_id = map.group_id
		    and element_id = m.element_id
		    and rel_id = m.rel_id);
  end loop;

  return new;

end;' language 'plpgsql';  

create trigger composition_rels_in_tr after insert on composition_rels
for each row execute procedure composition_rels_in_tr ();

--
-- TO DO: See if this can be optimized now that the member and component
-- mapping tables have been combined
--
create or replace function composition_rels_del_tr () returns opaque as '
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  n_rows          integer;
  v_error         text;
  map             record;
begin
  -- First check if removing this relation would violate any relational constraints
  v_error := rel_constraint__violation_if_removed(old.rel_id);
  if v_error is not null then
      raise EXCEPTION ''-20000: %'', v_error;
  end if;

  select object_id_one, object_id_two into v_object_id_one, v_object_id_two
  from acs_rels
  where rel_id = old.rel_id;

  for map in  select *
	      from group_component_map
	      where rel_id = old.rel_id 
  LOOP

    delete from group_element_index
    where rel_id = old.rel_id;

    select count(*) into n_rows
    from group_component_map
    where group_id = map.group_id
    and component_id = map.component_id;

    if n_rows = 0 then

      perform party_approved_member__remove(map.group_id, member_id, rel_id, rel_type)
      from group_approved_member_map
      where group_id = map.group_id
      and container_id = map.component_id;

      delete from group_element_index
      where group_id = map.group_id
      and container_id = map.component_id
      and ancestor_rel_type = ''membership_rel'';
    end if;

  end loop;


  for map in  select *
              from group_component_map
	      where group_id in (select group_id
		               from group_component_map
		               where component_id = v_object_id_one
			       union
			       select v_object_id_one
			       from dual)
              and component_id in (select component_id
			           from group_component_map
			           where group_id = v_object_id_two
				   union
				   select v_object_id_two
				   from dual)
              and group_contains_p(group_id, component_id, rel_id) = ''f'' 
  LOOP

    delete from group_element_index
    where group_id = map.group_id
    and element_id = map.component_id
    and rel_id = map.rel_id;

    select count(*) into n_rows
    from group_component_map
    where group_id = map.group_id
    and component_id = map.component_id;

    if n_rows = 0 then
    end if;

      perform party_approved_member__remove(map.group_id, member_id, rel_id, rel_type)
      from group_approved_member_map
      where group_id = map.group_id
      and container_id = map.component_id;

      delete from group_element_index
      where group_id = map.group_id
      and container_id = map.component_id
      and ancestor_rel_type = ''membership_rel'';

  end loop;

  return old;

end;' language 'plpgsql';

create trigger composition_rels_del_tr before delete on composition_rels
for each row execute procedure composition_rels_del_tr ();

--------------------
-- PACKAGE BODIES --
--------------------

-- create or replace package body composition_rel
-- function new
select define_function_args('composition_rel__new','rel_id,rel_type;composition_rel,object_id_one,object_id_two,creation_user,creation_ip');

create or replace function composition_rel__new (integer,varchar,integer,integer,integer,varchar)
returns integer as '
declare
  new__rel_id            alias for $1;  -- default null  
  rel_type               alias for $2;  -- default ''composition_rel''
  object_id_one          alias for $3;  
  object_id_two          alias for $4;  
  creation_user          alias for $5;  -- default null
  creation_ip            alias for $6;  -- default null
  v_rel_id               integer;       
begin
    v_rel_id := acs_rel__new (
      new__rel_id,
      rel_type,
      object_id_one,
      object_id_two,
      object_id_one,
      creation_user,
      creation_ip
    );

    insert into composition_rels
     (rel_id)
    values
     (v_rel_id);

    return v_rel_id;
   
end;' language 'plpgsql';

-- function new
create or replace function composition_rel__new (integer,integer)
returns integer as '
declare
  object_id_one          alias for $1;  
  object_id_two          alias for $2;  
begin
        return composition_rel__new(null,
                                    ''composition_rel'',
                                    object_id_one,
                                    object_id_two,
                                    null,
                                    null);
end;' language 'plpgsql';

-- procedure delete
create or replace function composition_rel__delete (integer)
returns integer as '
declare
  rel_id                 alias for $1;  
begin
    PERFORM acs_rel__delete(rel_id);

    return 0; 
end;' language 'plpgsql';


-- function check_path_exists_p
create or replace function composition_rel__check_path_exists_p (integer,integer)
returns boolean as '
declare
  component_id           alias for $1;  
  container_id           alias for $2;  
  row                    record;
begin
    if component_id = container_id then
      return ''t'';
    end if;

    for row in  select r.object_id_one as parent_id
                from acs_rels r, composition_rels c
                where r.rel_id = c.rel_id
                and r.object_id_two = component_id 
    LOOP
      if composition_rel__check_path_exists_p(row.parent_id, container_id) = ''t'' then
        return ''t'';
      end if;
    end loop;

    return ''f'';
   
end;' language 'plpgsql';


-- function check_index
create or replace function composition_rel__check_index (integer,integer)
returns boolean as '
declare
  check_index__component_id           alias for $1;  
  check_index__container_id           alias for $2;  
  result                              boolean;       
  n_rows                              integer;       
  dc                                  record;
  r1                                  record;
  r2                                  record;
begin
    result := ''t'';

    -- Loop through all the direct containers (DC) of COMPONENT_ID
    -- that are also contained by CONTAINER_ID and verify that the
    -- GROUP_COMPONENT_INDEX contains the (GROUP_ID, DC.REL_ID,
    -- CONTAINER_ID) triple.
    for dc in  select r.rel_id, r.object_id_one as container_id
               from acs_rels r, composition_rels c
               where r.rel_id = c.rel_id
               and r.object_id_two = check_index__component_id 
    LOOP

      if composition_rel__check_path_exists_p(dc.container_id,
                             check_index__container_id) = ''t'' then
        select case when count(*) = 0 then 0 else 1 end into n_rows
        from group_component_index
        where group_id = check_index__container_id
        and component_id = check_index__component_id
        and rel_id = dc.rel_id;

        if n_rows = 0 then
          result := ''f'';
          PERFORM acs_log__error(''composition_rel.check_representation'',
                        ''Row missing from group_component_index for ('' ||
                        ''group_id = '' || check_index__container_id || '', '' ||
                        ''component_id = '' || check_index__component_id || '', '' ||
                        ''rel_id = '' || dc.rel_id || '')'');
        end if;

      end if;

    end loop;

    -- Loop through all the containers of CONTAINER_ID.
    for r1 in  select r.object_id_one as container_id
               from acs_rels r, composition_rels c
               where r.rel_id = c.rel_id
               and r.object_id_two = check_index__container_id
               union
               select check_index__container_id as container_id
               from dual 
    LOOP
      -- Loop through all the components of COMPONENT_ID and make a
      -- recursive call.
      for r2 in  select r.object_id_two as component_id
                 from acs_rels r, composition_rels c
                 where r.rel_id = c.rel_id
                 and r.object_id_one = check_index__component_id
                 union
                 select check_index__component_id as component_id
                 from dual 
      LOOP
        if (r1.container_id != check_index__container_id or
            r2.component_id != check_index__component_id) and
           composition_rel__check_index(r2.component_id, r1.container_id) = ''f'' then
          result := ''f'';
        end if;
      end loop;
    end loop;

    return result;
   
end;' language 'plpgsql';


-- function check_representation
create or replace function composition_rel__check_representation (integer)
returns boolean as '
declare
  check_representation__rel_id                 alias for $1;  
  container_id                                 groups.group_id%TYPE;
  component_id                                 groups.group_id%TYPE;
  result                                       boolean;     
  row                                          record;  
begin
    result := ''t'';

    if acs_object__check_representation(check_representation__rel_id) = ''f'' then
      result := ''f'';
    end if;

    select object_id_one, object_id_two
    into container_id, component_id
    from acs_rels
    where rel_id = check_representation__rel_id;

    -- First let us check that the index has all the rows it should.
    if composition_rel__check_index(component_id, container_id) = ''f'' then
      result := ''f'';
    end if;

    -- Now let us check that the index doesn''t have any extraneous rows
    -- relating to this relation.
    for row in  select *
                from group_component_index
                where rel_id = check_representation__rel_id  
    LOOP
      if composition_rel__check_path_exists_p(row.component_id, row.group_id) = ''f'' then
        result := ''f'';
        PERFORM acs_log__error(''composition_rel.check_representation'',
                      ''Extraneous row in group_component_index: '' ||
                      ''group_id = '' || row.group_id || '', '' ||
                      ''component_id = '' || row.component_id || '', '' ||
                      ''rel_id = '' || row.rel_id || '', '' ||
                      ''container_id = '' || row.container_id || ''.'');
      end if;
    end loop;

    return result;
   
end;' language 'plpgsql';



-- show errors

-- create or replace package body membership_rel
-- function new
select define_function_args('membership_rel__new','rel_id,rel_type;membership_rel,object_id_one,object_id_two,member_state;approved,creation_user,creation_ip');

create or replace function membership_rel__new (integer,varchar,integer,integer,varchar,integer,varchar)
returns integer as '
declare
  new__rel_id            alias for $1;  -- default null  
  rel_type               alias for $2;  -- default ''membership_rel''
  object_id_one          alias for $3;  
  object_id_two          alias for $4;  
  new__member_state      alias for $5;  -- default ''approved''
  creation_user          alias for $6;  -- default null
  creation_ip            alias for $7;  -- default null
  v_rel_id               integer;       
begin
    v_rel_id := acs_rel__new (
      new__rel_id,
      rel_type,
      object_id_one,
      object_id_two,
      object_id_one,
      creation_user,
      creation_ip
    );

    insert into membership_rels
     (rel_id, member_state)
    values
     (v_rel_id, new__member_state);

    return v_rel_id;
   
end;' language 'plpgsql';

-- function new
create or replace function membership_rel__new (integer,integer)
returns integer as '
declare
  object_id_one          alias for $1;  
  object_id_two          alias for $2;  
begin
        return membership_rel__new(null,
                                   ''membership_rel'',
                                   object_id_one,
                                   object_id_two,
                                   ''approved'',
                                   null,
                                   null);
end;' language 'plpgsql';

-- procedure ban
create or replace function membership_rel__ban (integer)
returns integer as '
declare
  ban__rel_id           alias for $1;  
begin
    update membership_rels
    set member_state = ''banned''
    where rel_id = ban__rel_id;

    return 0; 
end;' language 'plpgsql';


-- procedure approve
create or replace function membership_rel__approve (integer)
returns integer as '
declare
  approve__rel_id               alias for $1;  
begin
    update membership_rels
    set member_state = ''approved''
    where rel_id = approve__rel_id;

    return 0; 
end;' language 'plpgsql';


-- procedure reject
create or replace function membership_rel__reject (integer)
returns integer as '
declare
  reject__rel_id                alias for $1;  
begin
    update membership_rels
    set member_state = ''rejected''
    where rel_id = reject__rel_id;

    return 0; 
end;' language 'plpgsql';


-- procedure unapprove
create or replace function membership_rel__unapprove (integer)
returns integer as '
declare
  unapprove__rel_id             alias for $1;  
begin
    update membership_rels
    set member_state = ''needs approval''
    where rel_id = unapprove__rel_id;

    return 0; 
end;' language 'plpgsql';


-- procedure deleted
create or replace function membership_rel__deleted (integer)
returns integer as '
declare
  deleted__rel_id               alias for $1;  
begin
    update membership_rels
    set member_state = ''deleted''
    where rel_id = deleted__rel_id;

    return 0; 
end;' language 'plpgsql';


-- procedure delete
create or replace function membership_rel__delete (integer)
returns integer as '
declare
  rel_id                 alias for $1;  
begin
    PERFORM acs_rel__delete(rel_id);

    return 0; 
end;' language 'plpgsql';

-- procedure merge
create or replace function membership_rel__merge (integer)
returns integer as '
declare
  merge__rel_id                alias for $1;  
begin
    update membership_rels
    set member_state = ''merged''
    where rel_id = merge__rel_id;

    return 0; 
end;' language 'plpgsql';

-- function check_index
create or replace function membership_rel__check_index (integer,integer,integer)
returns boolean as '
declare
  check_index__group_id               alias for $1;  
  check_index__member_id              alias for $2;  
  check_index__container_id           alias for $3;  
  result                              boolean;       
  n_rows                              integer;       
  row                                 record;
begin

    select count(*) into n_rows
    from group_element_index
    where group_id = check_index__group_id
    and member_id = check_index__member_id
    and container_id = check_index__container_id;

    if n_rows = 0 then
      result := ''f'';
      PERFORM acs_log__error(''membership_rel.check_representation'',
                    ''Row missing from group_element_index: '' ||
                    ''group_id = '' || check_index__group_id || '', '' ||
                    ''member_id = '' || check_index__member_id || '', '' ||
                    ''container_id = '' || check_index__container_id || ''.'');
    end if;

    for row in  select r.object_id_one as container_id
                from acs_rels r, composition_rels c
                where r.rel_id = c.rel_id
                and r.object_id_two = check_index__group_id  
    LOOP
      if membership_rel__check_index(row.container_id, check_index__member_id, check_index__container_id) = ''f'' then
        result := ''f'';
      end if;
    end loop;

    return result;
   
end;' language 'plpgsql';


-- function check_representation
create or replace function membership_rel__check_representation (integer)
returns boolean as '
declare
  check_representation__rel_id  alias for $1;  
  group_id                      groups.group_id%TYPE;
  member_id                     parties.party_id%TYPE;
  result                        boolean;  
  row                           record;     
begin
    result := ''t'';

    if acs_object__check_representation(check_representation__rel_id) = ''f'' then
      result := ''f'';
    end if;

    select r.object_id_one, r.object_id_two
    into group_id, member_id
    from acs_rels r, membership_rels m
    where r.rel_id = m.rel_id
    and m.rel_id = check_representation__rel_id;

    if membership_rel__check_index(group_id, member_id, group_id) = ''f'' then
      result := ''f'';
    end if;

    for row in  select *
                from group_member_index
                where rel_id = check_representation__rel_id 
    LOOP
      if composition_rel__check_path_exists_p(row.container_id,
                                             row.group_id) = ''f'' then
        result := ''f'';
        PERFORM acs_log__error(''membership_rel.check_representation'',
                      ''Extra row in group_member_index: '' ||
                      ''group_id = '' || row.group_id || '', '' ||
                      ''member_id = '' || row.member_id || '', '' ||
                      ''container_id = '' || row.container_id || ''.'');
      end if;
    end loop;

    return result;
   
end;' language 'plpgsql';

    
-- create or replace package body acs_group
-- function new
select define_function_args('acs_group__new','group_id,object_type;group,creation_date;now(),creation_user,creation_ip,email,url,group_name,join_policy,context_id');

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
  select nextval(''t_acs_object_id_seq''), v_group_id, g.rel_type
    from group_type_rels g
   where g.group_type = new__object_type;

  return v_group_id;
  
end;' language 'plpgsql';

-- function new
create or replace function acs_group__new (varchar) returns integer as '
declare
        gname   alias for $1;
begin
        return acs_group__new(null,
                              ''group'',
                              now(),
                              null,
                              null,
                              null,
                              null,
                              gname,
                              null,
                              null);
end;' language 'plpgsql';

-- procedure delete
create or replace function acs_group__delete (integer)
returns integer as '
declare
  delete__group_id              alias for $1;  
  row                           record;
begin
 
   -- Delete all the relations of any type to this group
   for row in select r.rel_id, t.package_name
                 from acs_rels r, acs_object_types t
                where r.rel_type = t.object_type
                  and (r.object_id_one = delete__group_id
                       or r.object_id_two = delete__group_id) 
   LOOP
      execute ''select '' ||  row.package_name || ''__delete('' || row.rel_id || '')'';
   end loop;
 
   -- Delete all segments defined for this group
   for row in  select segment_id 
                 from rel_segments 
                where group_id = delete__group_id 
   LOOP
       PERFORM rel_segment__delete(row.segment_id);
   end loop;

   PERFORM party__delete(delete__group_id);

   return 0; 
end;' language 'plpgsql';


-- function name
create or replace function acs_group__name (integer)
returns varchar as '
declare
  name__group_id         alias for $1;  
  name__group_name       varchar(200);  
begin
  select group_name
  into name__group_name
  from groups
  where group_id = name__group_id;

  return name__group_name;
  
end;' language 'plpgsql' stable strict;

create or replace function acs_group__member_p (integer, integer, boolean)
returns boolean as '
declare
  p_party_id               alias for $1;  
  p_group_id               alias for $2;
  p_cascade_membership     alias for $3;
begin
  if p_cascade_membership  then
    return count(*) > 0
      from group_member_map
      where group_id = p_group_id and
            member_id = p_party_id;
  else
    return count(*) > 0
      from acs_rels rels, all_object_party_privilege_map perm
    where perm.object_id = rels.rel_id
           and perm.privilege = ''read''
           and rels.rel_type = ''membership_rel''
	   and rels.object_id_one = p_group_id
           and rels.object_id_two = p_party_id;
  end if;
end;' language 'plpgsql' stable;



-- function check_representation
create or replace function acs_group__check_representation (integer)
returns boolean as '
declare
  group_id               alias for $1;  
  res                    boolean; 
  comp                   record;
  memb                   record;      
begin
   if group_id is null then 
        --maybe we should just return ''f'' instead?
	raise exception ''acs_group__check_representation called with null group_id'';
   end if;

   res := ''t'';
   PERFORM acs_log__notice(''acs_group.check_representation'',
                  ''Running check_representation on group '' || group_id);

   if acs_object__check_representation(group_id) = ''f'' then
     res := ''f'';
   end if;

   for comp in select c.rel_id
             from acs_rels r, composition_rels c
             where r.rel_id = c.rel_id
             and r.object_id_one = group_id 
   LOOP
     if composition_rel__check_representation(comp.rel_id) = ''f'' then
       res := ''f'';
     end if;
   end loop;

   for memb in  select m.rel_id
             from acs_rels r, membership_rels m
             where r.rel_id = m.rel_id
             and r.object_id_one = group_id 
   LOOP
     if membership_rel__check_representation(memb.rel_id) = ''f'' then
       res := ''f'';
     end if;
   end loop;

   PERFORM acs_log__notice(''acs_group.check_representation'',
                  ''Done running check_representation on group '' || group_id);

   return res;
  
end;' language 'plpgsql';



-- show errors


-- create or replace package body admin_rel
-- function new
select define_function_args('admin_rel__new','rel_id,rel_type;admin_rel,object_id_one,object_id_two,member_state;approved,creation_user,creation_ip');

create or replace function admin_rel__new (integer,varchar,integer,integer,varchar,integer,varchar)
returns integer as '
declare
  p_rel_id               alias for $1;  -- default null  
  p_rel_type             alias for $2;  -- default ''admin_rel''
  p_object_id_one        alias for $3;  
  p_object_id_two        alias for $4;  
  p_member_state      alias for $5;  -- default ''approved''
  p_creation_user        alias for $6;  -- default null
  p_creation_ip          alias for $7;  -- default null
  v_rel_id               integer;       
begin
    v_rel_id := membership_rel__new (
      p_rel_id,           -- rel_id
      p_rel_type,         -- rel_type
      p_object_id_one,    -- object_id_one
      p_object_id_two,    -- object_id_two
      p_member_state,     -- member_state
      p_creation_user,    -- creation_usre
      p_creation_ip       -- creation_ip
    );

    insert into admin_rels
     (rel_id)
    values
     (v_rel_id);

    return v_rel_id;
   
end;' language 'plpgsql';

-- function new
create or replace function admin_rel__new (integer,integer)
returns integer as '
declare
  object_id_one          alias for $1;  
  object_id_two          alias for $2;  
begin
    return membership_rel__new(
        null,                  -- rel_id
        ''admin_rel'',         -- rel_type
        object_id_one,         -- object_id_one
        object_id_two,         -- object_id_two
        ''approved'',          -- member_state
        null,                  -- creation_user
        null                   -- creation_ip
    );
end;' language 'plpgsql';

-- procedure delete
create or replace function admin_rel__delete (integer)
returns integer as '
declare
  rel_id                 alias for $1;  
begin
    PERFORM membership_rel__delete(rel_id);

    return 0; 
end;' language 'plpgsql';


