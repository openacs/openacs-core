-- 
-- 
-- 
-- @author Victor Guerra (guerra@galileo.edu)
-- @creation-date 2006-07-13
-- @arch-tag: 75450145-8d86-463e-8408-1c07d796f484
-- @cvs-id $Id$
--

-- renaming upgrade script, original script: upgrade-5.1.5-5.2.0a1.sql
-- Add support for merge member state

alter table membership_rels drop constraint membership_rel_mem_ck;

alter table membership_rels add constraint membership_rel_mem_ck check (member_state in ('approved','needs approval','banned','rejected','deleted','merged'));


create or replace package membership_rel
as

  function new (
    rel_id              in membership_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'membership_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default 'approved',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return membership_rels.rel_id%TYPE;

  procedure ban (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure approve (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure merge (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure reject (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure unapprove (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure deleted (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure del (
    rel_id      in membership_rels.rel_id%TYPE
  );

  function check_representation (
    rel_id      in membership_rels.rel_id%TYPE
  ) return char;

end membership_rel;
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

-- Add support for merge member state

alter table membership_rels drop constraint membership_rel_mem_ck;

alter table membership_rels add constraint membership_rel_mem_ck check (member_state in ('approved','needs approval','banned','rejected','deleted','merged'));


create or replace package membership_rel
as

  function new (
    rel_id              in membership_rels.rel_id%TYPE default null,
    rel_type            in acs_rels.rel_type%TYPE default 'membership_rel',
    object_id_one       in acs_rels.object_id_one%TYPE,
    object_id_two       in acs_rels.object_id_two%TYPE,
    member_state        in membership_rels.member_state%TYPE default 'approved',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return membership_rels.rel_id%TYPE;

  procedure ban (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure approve (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure merge (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure reject (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure unapprove (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure deleted (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure del (
    rel_id      in membership_rels.rel_id%TYPE
  );

  function check_representation (
    rel_id      in membership_rels.rel_id%TYPE
  ) return char;

end membership_rel;
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

