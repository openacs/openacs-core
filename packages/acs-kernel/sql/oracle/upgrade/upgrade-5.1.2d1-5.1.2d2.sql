-- PATCH 267, BUG 775 Randy O'Meara
-- procedure delete
-- function acs_group_delete in file
-- acs-kernel/sql/postgresql/groups-body-create.sql attempts to delete
-- associated relational segments before removing any active relations on
-- those segments. The group delete request is not successful and the
-- following error is returned.
-- ERROR:  party_member_party_fk referential integrity violation - key in
--   parties still referenced from party_approved_member_map
--

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


  -- setup the permissible relationship types for this group
  insert into group_rels
  (group_rel_id, group_id, rel_type)
  select acs_object_id_seq.nextval, v_group_id, g.rel_type
    from group_type_rels g
   where g.group_type = new.object_type;

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
      from acs_rels rels, all_object_party_privilege_map perm
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
