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

create or replace trigger membership_rels_up_tr
before update on membership_rels
for each row
begin
  
  if :new.member_state = :old.member_state then
    return;
  end if;

  for map in (select group_id, element_id, rel_type
              from group_element_index
              where rel_id = :new.rel_id)
  loop
    if :new.member_state = 'approved' then
      party_approved_member.add(map.group_id, map.element_id, map.rel_type);
    else
      party_approved_member.remove(map.group_id, map.element_id, map.rel_type);
    end if;
  end loop;

end;
/
show errors

create or replace trigger membership_rels_in_tr
after insert on membership_rels
for each row
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error varchar2(4000);
begin
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint.violation(:new.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  select object_id_one, object_id_two, r.rel_type, composable_p
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels r
  join acs_rel_types t on (r.rel_type = t.rel_type)
  where rel_id = :new.rel_id;

  -- Insert a row for me in the group_member_index.
  insert into group_element_index
   (group_id, element_id, rel_id, container_id, 
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, :new.rel_id, v_object_id_one, 
    v_rel_type, 'membership_rel');

  if :new.member_state = 'approved' then
    party_approved_member.add(v_object_id_one, v_object_id_two, v_rel_type);
  end if;

  if v_composable_p = 't' then
    -- For all groups of which I am a component, insert a
    -- row in the group_member_index.
    for map in (select distinct group_id
	        from group_component_map
	        where component_id = v_object_id_one) loop
          insert into group_element_index
          (group_id, element_id, rel_id, container_id,
          rel_type, ancestor_rel_type)
          values
          (map.group_id, v_object_id_two, :new.rel_id, v_object_id_one,
          v_rel_type, 'membership_rel');

          if :new.member_state = 'approved' then
             party_approved_member.add(map.group_id, v_object_id_two, v_rel_type);
          end if;

    end loop;
  end if;
end;
/
show errors

--alter trigger membership_rels_in_tr disable;

create or replace trigger membership_rels_del_tr
before delete on membership_rels
for each row
declare 
  v_error varchar2(4000);
begin
  -- First check if removing this relation would violate any relational constraints
  v_error := rel_constraint.violation_if_removed(:old.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  for map in (select group_id, element_id, rel_type
              from group_element_index
              where rel_id = :old.rel_id)
  loop
    party_approved_member.remove(map.group_id, map.element_id, map.rel_type);
  end loop;

  delete from group_element_index
  where rel_id = :old.rel_id;

end;
/
show errors;

create or replace trigger composition_rels_in_tr
after insert on composition_rels
for each row
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  v_rel_type      acs_rels.rel_type%TYPE;
  v_error varchar2(4000);
begin
  
  -- First check if added this relation violated any relational constraints
  v_error := rel_constraint.violation(:new.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  select object_id_one, object_id_two, rel_type
  into v_object_id_one, v_object_id_two, v_rel_type
  from acs_rels
  where rel_id = :new.rel_id;

  -- Insert a row for me in group_element_index
  insert into group_element_index
   (group_id, element_id, rel_id, container_id,
    rel_type, ancestor_rel_type)
  values
   (v_object_id_one, v_object_id_two, :new.rel_id, v_object_id_one,
    v_rel_type, 'composition_rel');

  for members in (select distinct member_id, rel_type
               from group_approved_member_map m
               where group_id = v_object_id_two
                 and not exists (select 1
		                 from group_element_map
		                 where group_id = v_object_id_one
		                   and element_id = m.member_id
		                   and rel_id = m.rel_id))
  loop
    party_approved_member.add(v_object_id_one, members.member_id, members.rel_type);
  end loop;

  -- Make my composable elements be elements of my new composite group
  insert into group_element_index
   (group_id, element_id, rel_id, container_id,
    rel_type, ancestor_rel_type)
  select distinct
   v_object_id_one, element_id, rel_id, container_id,
   m.rel_type, ancestor_rel_type
  from group_element_map m
  join acs_rel_types t on (m.rel_type = t.rel_type)
  where group_id = v_object_id_two
  and t.composable_p = 't'
  and not exists (select 1
		  from group_element_map
		  where group_id = v_object_id_one
		  and element_id = m.element_id
		  and rel_id = m.rel_id);

  -- For all direct or indirect containers of my new composite group, 
  -- add me and add my composable elements
  for map in (select distinct group_id
	      from group_component_map
	      where component_id = v_object_id_one) loop

    -- Add a row for me
    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    values
     (map.group_id, v_object_id_two, :new.rel_id, v_object_id_one,
      v_rel_type, 'composition_rel');

    -- Add rows for my composable elements

    for members in (select distinct member_id, rel_type
                    from group_approved_member_map m
                     join acs_rel_types t on (m.rel_type = t.rel_type)
                    where group_id = v_object_id_two
                      and t.composable_p = 't'
                      and not exists (select 1
		                      from group_element_map
		                      where group_id = map.group_id
		                        and element_id = m.member_id
		                        and rel_id = m.rel_id))
    loop
      party_approved_member.add(map.group_id, members.member_id, members.rel_type);
    end loop;

    insert into group_element_index
     (group_id, element_id, rel_id, container_id,
      rel_type, ancestor_rel_type)
    select distinct
     map.group_id, element_id, rel_id, container_id,
     rel_type, ancestor_rel_type
    from group_element_map m
    join acs_rel_types t on (m.rel_type = t.rel_type)
    where group_id = v_object_id_two
    and t.composable_p = 't'
    and not exists (select 1
		    from group_element_map
		    where group_id = map.group_id
		    and element_id = m.element_id
		    and rel_id = m.rel_id);
  end loop;

end;
/
show errors

--alter trigger composition_rels_in_tr disable;

--
-- TO DO: See if this can be optimized now that the member and component
-- mapping tables have been combined
--
create or replace trigger composition_rels_del_tr
before delete on composition_rels
for each row
declare
  v_object_id_one acs_rels.object_id_one%TYPE;
  v_object_id_two acs_rels.object_id_two%TYPE;
  n_rows integer;
  v_error varchar2(4000);
begin
  -- First check if removing this relation would violate any relational constraints
  v_error := rel_constraint.violation_if_removed(:old.rel_id);
  if v_error is not null then
      raise_application_error(-20000,v_error);
  end if;

  select object_id_one, object_id_two into v_object_id_one, v_object_id_two
  from acs_rels
  where rel_id = :old.rel_id;

  for map in (select *
	      from group_component_map
	      where rel_id = :old.rel_id) loop

    delete from group_element_index
    where rel_id = :old.rel_id;

    select count(*) into n_rows
    from group_component_map
    where group_id = map.group_id
    and component_id = map.component_id;

    if n_rows = 0 then

      for members in (select member_id, rel_type
                      from group_approved_member_map
                      where group_id = map.group_id
                        and container_id = map.component_id)
      loop
        party_approved_member.remove(map.group_id, members.member_id, members.rel_type);
      end loop;

      delete from group_element_index
      where group_id = map.group_id
      and container_id = map.component_id
      and ancestor_rel_type = 'membership_rel';
    end if;

  end loop;

  for map in (select *
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
              and group_contains_p(group_id, component_id, rel_id) = 'f') loop

    delete from group_element_index
    where group_id = map.group_id
    and element_id = map.component_id
    and rel_id = map.rel_id;

    select count(*) into n_rows
    from group_component_map
    where group_id = map.group_id
    and component_id = map.component_id;

    if n_rows = 0 then

      for members in (select member_id, rel_type
                      from group_approved_member_map
                      where group_id = map.group_id
                        and container_id = map.component_id)
      loop
        party_approved_member.remove(map.group_id, members.member_id, members.rel_type);
      end loop;

      delete from group_element_index
      where group_id = map.group_id
      and container_id = map.component_id
      and ancestor_rel_type = 'membership_rel';

    end if;

  end loop;
end;
/
show errors

--------------------
-- PACKAGE BODIES --
--------------------

create or replace package body composition_rel
as

  function new (
    rel_id              in composition_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'composition_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return composition_rels.rel_id%TYPE
  is
    v_rel_id integer;
  begin
    v_rel_id := acs_rel.new (
      rel_id => rel_id,
      rel_type => rel_type,
      object_id_one => object_id_one,
      object_id_two => object_id_two,
      context_id => object_id_one,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into composition_rels
     (rel_id)
    values
     (v_rel_id);

    return v_rel_id;
  end;

  procedure del (
    rel_id      in composition_rels.rel_id%TYPE
  )
  is
  begin
    acs_rel.del(rel_id);
  end;

  function check_path_exists_p (
    component_id        in groups.group_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
  begin
    if component_id = container_id then
      return 't';
    end if;

    for row in (select r.object_id_one as parent_id
                from acs_rels r, composition_rels c
                where r.rel_id = c.rel_id
                and r.object_id_two = component_id) loop
      if check_path_exists_p(row.parent_id, container_id) = 't' then
        return 't';
      end if;
    end loop;

    return 'f';
  end;

  function check_index (
    component_id        in groups.group_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
    result char(1);
    n_rows integer;
  begin
    result := 't';

    -- Loop through all the direct containers (DC) of COMPONENT_ID
    -- that are also contained by CONTAINER_ID and verify that the
    -- GROUP_COMPONENT_INDEX contains the (GROUP_ID, DC.REL_ID,
    -- CONTAINER_ID) triple.
    for dc in (select r.rel_id, r.object_id_one as container_id
               from acs_rels r, composition_rels c
               where r.rel_id = c.rel_id
               and r.object_id_two = component_id) loop

      if check_path_exists_p(dc.container_id,
                             check_index.container_id) = 't' then
        select decode(count(*),0,0,1) into n_rows
        from group_component_index
        where group_id = check_index.container_id
        and component_id = check_index.component_id
        and rel_id = dc.rel_id;

        if n_rows = 0 then
          result := 'f';
          acs_log.error('composition_rel.check_representation',
                        'Row missing from group_component_index for (' ||
                        'group_id = ' || container_id || ', ' ||
                        'component_id = ' || component_id || ', ' ||
                        'rel_id = ' || dc.rel_id || ')');
        end if;

      end if;

    end loop;

    -- Loop through all the containers of CONTAINER_ID.
    for r1 in (select r.object_id_one as container_id
               from acs_rels r, composition_rels c
               where r.rel_id = c.rel_id
               and r.object_id_two = check_index.container_id
               union
               select check_index.container_id
               from dual) loop
      -- Loop through all the components of COMPONENT_ID and make a
      -- recursive call.
      for r2 in (select r.object_id_two as component_id
                 from acs_rels r, composition_rels c
                 where r.rel_id = c.rel_id
                 and r.object_id_one = check_index.component_id
                 union
                 select check_index.component_id
                 from dual) loop
        if (r1.container_id != check_index.container_id or
            r2.component_id != check_index.component_id) and
           check_index(r2.component_id, r1.container_id) = 'f' then
          result := 'f';
        end if;
      end loop;
    end loop;

    return result;
  end;

  function check_representation (
    rel_id      in composition_rels.rel_id%TYPE
  ) return char
  is
    container_id groups.group_id%TYPE;
    component_id groups.group_id%TYPE;
    result char(1);
  begin
    result := 't';

    if acs_object.check_representation(rel_id) = 'f' then
      result := 'f';
    end if;

    select object_id_one, object_id_two
    into container_id, component_id
    from acs_rels
    where rel_id = check_representation.rel_id;

    -- First let's check that the index has all the rows it should.
    if check_index(component_id, container_id) = 'f' then
      result := 'f';
    end if;

    -- Now let's check that the index doesn't have any extraneous rows
    -- relating to this relation.
    for row in (select *
                from group_component_index
                where rel_id = check_representation.rel_id) loop
      if check_path_exists_p(row.component_id, row.group_id) = 'f' then
        result := 'f';
        acs_log.error('composition_rel.check_representation',
                      'Extraneous row in group_component_index: ' ||
                      'group_id = ' || row.group_id || ', ' ||
                      'component_id = ' || row.component_id || ', ' ||
                      'rel_id = ' || row.rel_id || ', ' ||
                      'container_id = ' || row.container_id || '.');
      end if;
    end loop;

    return result;
  end;

end composition_rel;
/
show errors

create or replace package body membership_rel
as

  function new (
    rel_id              in membership_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'membership_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default 'approved',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return membership_rels.rel_id%TYPE
  is
    v_rel_id integer;
  begin
    v_rel_id := acs_rel.new (
      rel_id => rel_id,
      rel_type => rel_type,
      object_id_one => object_id_one,
      object_id_two => object_id_two,
      context_id => object_id_one,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into membership_rels
     (rel_id, member_state)
    values
     (v_rel_id, new.member_state);

    return v_rel_id;
  end;

  procedure ban (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'banned'
    where rel_id = ban.rel_id;
  end;

  procedure approve (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'approved'
    where rel_id = approve.rel_id;
  end;

  procedure merge (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'merged'
    where rel_id = merge.rel_id;
  end;

  procedure reject (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'rejected'
    where rel_id = reject.rel_id;
  end;

  procedure unapprove (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'needs approval'
    where rel_id = unapprove.rel_id;
  end;

  procedure deleted (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    update membership_rels
    set member_state = 'deleted'
    where rel_id = deleted.rel_id;
  end;

  procedure del (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    acs_rel.del(rel_id);
  end;

  function check_index (
    group_id            in groups.group_id%TYPE,
    member_id           in parties.party_id%TYPE,
    container_id        in groups.group_id%TYPE
  ) return char
  is
    result char(1);
    n_rows integer;
  begin

    select count(*) into n_rows
    from group_member_index
    where group_id = check_index.group_id
    and member_id = check_index.member_id
    and container_id = check_index.container_id;

    if n_rows = 0 then
      result := 'f';
      acs_log.error('membership_rel.check_representation',
                    'Row missing from group_member_index: ' ||
                    'group_id = ' || group_id || ', ' ||
                    'member_id = ' || member_id || ', ' ||
                    'container_id = ' || container_id || '.');
    end if;

    for row in (select r.object_id_one as container_id
                from acs_rels r, composition_rels c
                where r.rel_id = c.rel_id
                and r.object_id_two = group_id) loop
      if check_index(row.container_id, member_id, container_id) = 'f' then
        result := 'f';
      end if;
    end loop;

    return result;
  end;

  function check_representation (
    rel_id      in membership_rels.rel_id%TYPE
  ) return char
  is
    group_id  groups.group_id%TYPE;
    member_id parties.party_id%TYPE;
    result    char(1);
  begin
    result := 't';

    if acs_object.check_representation(rel_id) = 'f' then
      result := 'f';
    end if;

    select r.object_id_one, r.object_id_two
    into group_id, member_id
    from acs_rels r, membership_rels m
    where r.rel_id = m.rel_id
    and m.rel_id = check_representation.rel_id;

    if check_index(group_id, member_id, group_id) = 'f' then
      result := 'f';
    end if;

    for row in (select *
                from group_member_index
                where rel_id = check_representation.rel_id) loop
      if composition_rel.check_path_exists_p(row.container_id,
                                             row.group_id) = 'f' then
        result := 'f';
        acs_log.error('membership_rel.check_representation',
                      'Extra row in group_member_index: ' ||
                      'group_id = ' || row.group_id || ', ' ||
                      'member_id = ' || row.member_id || ', ' ||
                      'container_id = ' || row.container_id || '.');
      end if;
    end loop;

    return result;
  end;

end membership_rel;
/
show errors



create or replace package body admin_rel
as

  function new (
    rel_id              in admin_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'admin_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default 'approved',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return admin_rels.rel_id%TYPE
  is
    v_rel_id integer;
  begin
    v_rel_id := membership_rel.new (
      rel_id => rel_id,
      rel_type => rel_type,
      object_id_one => object_id_one,
      object_id_two => object_id_two,
      member_state => member_state,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into admin_rels
     (rel_id)
    values
     (v_rel_id);

    return v_rel_id;
  end;

  procedure del (
    rel_id      in admin_rels.rel_id%TYPE
  )
  is
  begin
    membership_rel.del(rel_id);
  end;

end admin_rel;
/
show errors



create or replace package body acs_group
is
 function new (
  group_id              in groups.group_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'group',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  group_name            in groups.group_name%TYPE,
  join_policy           in groups.join_policy%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null
 )
 return groups.group_id%TYPE
 is
  v_group_id groups.group_id%TYPE;
  v_group_type_exists_p integer;
  v_join_policy groups.join_policy%TYPE;
 begin
  v_group_id :=
   party.new(group_id, object_type, creation_date, creation_user,
             creation_ip, email, url, context_id);

  v_join_policy := join_policy;

  -- if join policy wasn't specified, select the default based on group type
  if v_join_policy is null then
      select count(*) into v_group_type_exists_p
      from group_types
      where group_type = object_type;

      if v_group_type_exists_p = 1 then
          select default_join_policy into v_join_policy
          from group_types
          where group_type = object_type;
      else
          v_join_policy := 'open';
      end if;
  end if;

  insert into groups
   (group_id, group_name, join_policy)
  values
   (v_group_id, group_name, v_join_policy);

  update acs_objects
  set title = group_name
  where object_id = v_group_id;


  -- setup the permissible relationship types for this group
  insert into group_rels
  (group_rel_id, group_id, rel_type)
  select acs_object_id_seq.nextval, v_group_id, rels.rel_type
    from
    ( select distinct g.rel_type
      from group_type_rels g,
      ( select object_type as parent_type
        from acs_object_types
        start with new.object_type = object_type
        connect by prior supertype = object_type
        ) types
     where g.group_type = types.parent_type
     and not exists
     ( select 1 from group_rels
       where group_rels.group_id = v_group_id
       and group_rels.rel_type = g.rel_type)
  ) rels;
  
  return v_group_id;
 end new;


 procedure del (
    group_id     in groups.group_id%TYPE
  )
  is
  begin
 
   -- Delete all the relations of any type to this group
   for row in (select r.rel_id, t.package_name
                 from acs_rels r, acs_object_types t
                where r.rel_type = t.object_type
                  and (r.object_id_one = acs_group.del.group_id
                       or r.object_id_two = acs_group.del.group_id)) loop
      execute immediate 'begin ' ||  row.package_name || '.del(' || row.rel_id || '); end;';
   end loop;
 
   -- Delete all segments defined for this group
   for row in (select segment_id 
                 from rel_segments 
                where group_id = acs_group.del.group_id) loop

       rel_segment.del(row.segment_id);

   end loop;

   party.del(group_id);
 end del;

 function name (
  group_id      in groups.group_id%TYPE
 )
 return varchar2
 is
  group_name varchar2(200);
 begin
  select group_name
  into group_name
  from groups
  where group_id = name.group_id;

  return group_name;
 end name;

 function member_p (
  party_id      in parties.party_id%TYPE,
  group_id	in groups.group_id%TYPE,
  cascade_membership char
 )
 return char
 is
 m_result integer;
 begin

  if cascade_membership = 't' then
    select count(*)
      into m_result
      from group_member_map
      where group_id = member_p.group_id and
            member_id = member_p.party_id;

    if m_result > 0 then
      return 't';
    end if;
  else
    select count(*)
      into m_result
      from acs_rels rels, acs_object_party_privilege_map perm
    where perm.object_id = rels.rel_id
           and perm.privilege = 'read'
           and rels.rel_type = 'membership_rel'
	   and rels.object_id_one = member_p.group_id
           and rels.object_id_two = member_p.party_id;

    if m_result > 0 then
      return 't';
    end if;
  end if;

  return 'f';
 end member_p;

 function check_representation (
  group_id      in groups.group_id%TYPE
 ) return char
 is
   result char(1);
 begin
   result := 't';
   acs_log.notice('acs_group.check_representation',
                  'Running check_representation on group ' || group_id);

   if acs_object.check_representation(group_id) = 'f' then
     result := 'f';
   end if;

   for c in (select c.rel_id
             from acs_rels r, composition_rels c
             where r.rel_id = c.rel_id
             and r.object_id_one = group_id) loop
     if composition_rel.check_representation(c.rel_id) = 'f' then
       result := 'f';
     end if;
   end loop;

   for m in (select m.rel_id
             from acs_rels r, membership_rels m
             where r.rel_id = m.rel_id
             and r.object_id_one = group_id) loop
     if membership_rel.check_representation(m.rel_id) = 'f' then
       result := 'f';
     end if;
   end loop;

   acs_log.notice('acs_group.check_representation',
                  'Done running check_representation on group ' || group_id);
   return result;
 end;

end acs_group;
/
show errors
