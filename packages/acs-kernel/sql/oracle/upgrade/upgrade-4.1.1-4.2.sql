create or replace package site_node
as

  -- Create a new site node. If you set directory_p to be 'f' then you
  -- cannot create nodes that have this node as their parent.

  function new (
    node_id             in site_nodes.node_id%TYPE default null,
    parent_id           in site_nodes.node_id%TYPE default null,
    name                in site_nodes.name%TYPE,
    object_id           in site_nodes.object_id%TYPE default null,
    directory_p         in site_nodes.directory_p%TYPE,
    pattern_p           in site_nodes.pattern_p%TYPE default 'f',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return site_nodes.node_id%TYPE;

  -- Delete a site node.

  procedure delete (
    node_id             in site_nodes.node_id%TYPE
  );

  -- Return the node_id of a url. If the url begins with '/' then the
  -- parent_id must be null. This will raise the no_data_found
  -- exception if there is no mathing node in the site_nodes table.
  -- This will match directories even if no trailing slash is included
  -- in the url.

  function node_id (
    url                 in varchar2,
    parent_id   in site_nodes.node_id%TYPE default null
  ) return site_nodes.node_id%TYPE;

  -- Return the url of a node_id.

  function url (
    node_id             in site_nodes.node_id%TYPE
  ) return varchar2;

end;
/
show errors

create or replace package body site_node
as

  function new (
    node_id             in site_nodes.node_id%TYPE default null,
    parent_id           in site_nodes.node_id%TYPE default null,
    name                in site_nodes.name%TYPE,
    object_id           in site_nodes.object_id%TYPE default null,
    directory_p         in site_nodes.directory_p%TYPE,
    pattern_p           in site_nodes.pattern_p%TYPE default 'f',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return site_nodes.node_id%TYPE
  is
    v_node_id           site_nodes.node_id%TYPE;
    v_directory_p       site_nodes.directory_p%TYPE;
  begin
    if parent_id is not null then
      select directory_p into v_directory_p
      from site_nodes
      where node_id = new.parent_id;

      if v_directory_p = 'f' then
        raise_application_error (
          -20000,
          'Node ' || parent_id || ' is not a directory'
        );
      end if;
    end if;

    v_node_id := acs_object.new (
      object_id => node_id,
      object_type => 'site_node',
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into site_nodes
     (node_id, parent_id, name, object_id, directory_p, pattern_p)
    values
     (v_node_id, new.parent_id, new.name, new.object_id,
      new.directory_p, new.pattern_p);

     return v_node_id;
  end;

  procedure delete (
    node_id             in site_nodes.node_id%TYPE
  )
  is
  begin
    delete from site_nodes
    where node_id = site_node.delete.node_id;

    acs_object.delete(node_id);
  end;

  function find_pattern (
    node_id     in site_nodes.node_id%TYPE
  ) return site_nodes.node_id%TYPE
  is
    v_pattern_p site_nodes.pattern_p%TYPE;
    v_parent_id site_nodes.node_id%TYPE;
  begin
    if node_id is null then
      raise no_data_found;
    end if;

    select pattern_p, parent_id into v_pattern_p, v_parent_id
    from site_nodes
    where node_id = find_pattern.node_id;

    if v_pattern_p = 't' then
      return node_id;
    else
      return find_pattern(v_parent_id);
    end if;
  end;

  function node_id (
    url                 in varchar2,
    parent_id           in site_nodes.node_id%TYPE default null
  ) return site_nodes.node_id%TYPE
  is
    v_pos               integer;
    v_first             site_nodes.name%TYPE;
    v_rest              varchar2(4000);
    v_node_id           integer;
    v_pattern_p         site_nodes.pattern_p%TYPE;
    v_url               varchar2(4000);
    v_directory_p       site_nodes.directory_p%TYPE;
    v_trailing_slash_p  char(1);
  begin
    v_url := url;

    if substr(v_url, length(v_url), 1) = '/' then
      -- It ends with a / so it must be a directory.
      v_trailing_slash_p := 't';
      v_url := substr(v_url, 1, length(v_url) - 1);
    end if;

    v_pos := 1;

    while v_pos <= length(v_url) and substr(v_url, v_pos, 1) != '/' loop
      v_pos := v_pos + 1;
    end loop;

    if v_pos = length(v_url) then
      v_first := v_url;
      v_rest := null;
    else
      v_first := substr(v_url, 1, v_pos - 1);
      v_rest := substr(v_url, v_pos + 1);
    end if;

    begin
      -- Is there a better way to do these freaking null compares?
      select node_id, directory_p into v_node_id, v_directory_p
      from site_nodes
      where nvl(parent_id, 3.14) = nvl(site_node.node_id.parent_id, 3.14)
      and nvl(name, chr(10)) = nvl(v_first, chr(10));
    exception
      when no_data_found then
        return find_pattern(parent_id);
    end;

    if v_rest is null then
      if v_trailing_slash_p = 't' and v_directory_p = 'f' then
        return find_pattern(parent_id);
      else
        return v_node_id;
      end if;
    else
      return node_id(v_rest, v_node_id);
    end if;
  end;

  function url (
    node_id             in site_nodes.node_id%TYPE
  ) return varchar2
  is
    v_parent_id site_nodes.node_id%TYPE;
    v_name              site_nodes.name%TYPE;
    v_directory_p       site_nodes.directory_p%TYPE;
  begin
    if node_id is null then
      return '';
    end if;

    select parent_id, name, directory_p into
           v_parent_id, v_name, v_directory_p
    from site_nodes
    where node_id = url.node_id;

    if v_directory_p = 't' then
      return url(v_parent_id) || v_name || '/';
    else
      return url(v_parent_id) || v_name;
    end if;
  end;

end;
/
show errors

--------------------------------------------------------------
-- Relational Segments Views
-- oumi@arsdigita.com
-- 2/13/2001
--
-- CHANGES
-- Optimization improvement of rel_segment_party_map.
-- Added rel_segment_group_rel_type_map.  This view simplifies
-- the logic in other queries and views.
--------------------------------------------------------------

create or replace view rel_segment_party_map
as select rs.segment_id, gem.element_id as party_id, gem.rel_id, gem.rel_type, 
          gem.group_id, gem.container_id, gem.ancestor_rel_type
   from rel_segments rs, 
        group_element_map gem 
   where gem.group_id = rs.group_id
     and rs.rel_type in (select object_type 
                         from acs_object_types 
                         start with object_type = gem.rel_type 
                         connect by prior supertype = object_type);

create or replace view rel_seg_approved_member_map
as select /*+ ordered */ 
          rs.segment_id, gem.element_id as member_id, gem.rel_id, gem.rel_type, 
          gem.group_id, gem.container_id
    from membership_rels mr, group_element_map gem, rel_segments rs
   where rs.group_id = gem.group_id 
     and rs.rel_type in (select object_type 
                         from acs_object_types 
                         start with object_type = gem.rel_type 
                         connect by prior supertype = object_type)
     and mr.rel_id = gem.rel_id and mr.member_state = 'approved';


-- View: rel_segment_group_rel_type_map
--
-- Result Set: the set of triples (:segment_id, :group_id, :rel_type) such that
--
--             IF a party were to be in :group_id 
--                through a relation of type :rel_type,
--             THEN the party would necessarily be in segment :segemnt_id.    
--
--
create or replace view rel_segment_group_rel_type_map as
select s.segment_id, 
       gcm.component_id as group_id, 
       acs_rel_types.rel_type as rel_type
from rel_segments s,
     (select group_id, component_id
      from group_component_map
      UNION ALL
      select group_id, group_id as component_id
      from groups) gcm,
     acs_rel_types
where s.group_id = gcm.group_id
  and s.rel_type in (select object_type from acs_object_types
                     start with object_type = acs_rel_types.rel_type
                     connect by prior supertype = object_type);


--------------------------------------------------------------
-- Relational Constraints Views
-- oumi@arsdigita.com
-- 2/9/2001 - 2/13/2001
--
-- CHANGES
--
-- Added rc_segment_required_segment_map and 
-- rc_dependency_levels (these views save us from having to
-- write, tune, and comment connect by queries on 
-- rel_constraints in our application code).

-- Rewrote rc_all_constraints to use the new 
-- rel_segment_group_rel_type_map view. More importantly, the
-- rc_all_constraints view now avoids returning circular 
-- constraints (see comments on the rc_all_constraints view).
--
-- Fixed rc_valid_rel_types.  The query under "UNION ALL"
-- wasn't limiting the all_constraints view to side one 
-- constraints.  The result was that fewer rows were returned 
-- than what you might expect.
--------------------------------------------------------------

-- View: rc_all_constraints
--
-- Question: Given group :group_id and rel_type :rel_type . . .
--
--           What segments must a party be in 
--           if the party were to be on side :rel_side of a relation of 
--           type :rel_type to group :group_id ?
--
-- Answer:   select required_rel_segment
--           from rc_all_constraints
--           where group_id = :group_id
--             and rel_type = :rel_type
--             and rel_side = :rel_side
--
-- Notes: we take special care not to get identity rows, where group_id and 
-- rel_type are equivalent to segment_id.  This can happen if there are some 
-- funky constraints in the system, such as membership to Arsdigita requires 
-- user_profile to Arsdigita. Then you could get rows from the 
-- rc_all_constraints view saying that:
--     user_profile to Arsdigita 
--     requires being in the segment of Arsdigita Users.
--
-- This happens because user_profile is a type of memebrship, and there's a 
-- constraint saying that membership to Arsdigita requires being in the
-- Arsdigita Users segment.  We eliminate such rows from the rc_all_constraints
-- view with the "not (...)" clause below.
--
create or replace view rc_all_constraints as
select group_rel_types.group_id, 
       group_rel_types.rel_type,
       rel_constraints.rel_segment,
       rel_constraints.rel_side,
       required_rel_segment
  from rel_constraints,
       rel_segment_group_rel_type_map group_rel_types,
       rel_segments req_seg
 where rel_constraints.rel_segment = group_rel_types.segment_id
   and rel_constraints.required_rel_segment = req_seg.segment_id
   and not (req_seg.group_id = group_rel_types.group_id and
            req_seg.rel_type = group_rel_types.rel_type);

create or replace view rc_valid_rel_types as
select side_one_constraints.group_id, 
       side_one_constraints.rel_type
  from (select required_segs.group_id, 
               required_segs.rel_type, 
               count(*) as num_satisfied
          from rc_all_constraints required_segs,
               rel_segment_party_map map
         where required_segs.rel_side = 'one'
           and required_segs.required_rel_segment = map.segment_id
           and required_segs.group_id = map.party_id
        group by required_segs.group_id, 
                 required_segs.rel_type) side_one_constraints,
       (select group_id, rel_type, count(*) as total
          from rc_all_constraints
         where rel_side = 'one'
        group by group_id, rel_type) total_side_one_constraints
 where side_one_constraints.group_id = total_side_one_constraints.group_id
   and side_one_constraints.rel_type = total_side_one_constraints.rel_type
   and side_one_constraints.num_satisfied = total_side_one_constraints.total
UNION ALL
select group_rel_type_combos.group_id,
       group_rel_type_combos.rel_type
from (select * from rc_all_constraints where rel_side='one') rc_all_constraints, 
     (select groups.group_id, comp_or_member_rel_types.rel_type
      from groups, 
           (select object_type as rel_type from acs_object_types
            start with object_type = 'membership_rel'
                    or object_type = 'composition_rel'
            connect by supertype = prior object_type) comp_or_member_rel_types
     ) group_rel_type_combos
where rc_all_constraints.group_id(+) = group_rel_type_combos.group_id
  and rc_all_constraints.rel_type(+) = group_rel_type_combos.rel_type
  and rc_all_constraints.group_id is null;


-- View: rc_segment_required_seg_map
--
-- Question: Given a relational segment :rel_segment . . .
--
--           What are all the segments in the system that a party has to 
--           be in if the party were to be on side :rel_side of a relation
--           in segement :rel_segment?  
--
--           We want not only the direct required_segments (which we could
--           get from the rel_constraints table directly), but also the 
--           indirect ones (i.e., the segments that are required by the 
--           required segments, and so on).
--
-- Answer:   select required_rel_segment
--           from rc_segment_required_seg_map
--           where rel_segment = :rel_segment
--             and rel_side = :rel_side
--
--
create or replace view rc_segment_required_seg_map as
select rc.rel_segment, rc.rel_side, rc_required.required_rel_segment
from rel_constraints rc, rel_constraints rc_required 
where rc.rel_segment in (
          select rel_segment
          from rel_constraints
          start with rel_segment = rc_required.rel_segment
          connect by required_rel_segment = prior rel_segment
                 and prior rel_side = 'two'
      );

-- View: rc_segment_dependency_levels
--
-- This view is designed to determine what order of segments is safe
-- to use when adding a party to multiple segments.
--
-- Question: Given a table or view called segments_I_want_to_be_in,
--           which segments can I add a party to first, without violating
--           any relational constraints?
--
-- Answer:   select segment_id
--           from segments_I_want_to_be_in s,
--                rc_segment_dependency_levels dl
--           where s.segment_id = dl.segment_id(+)
--           order by nvl(dl.dependency_level, 0)
--
-- Note: dependency_level = 1 is the minimum dependency level.
--       dependency_level = N means that you cannot add a party to the
--                          segment until you first add the party to some
--                          segment of dependency_level N-1 (this view doesn't
--                          tell you which segment -- you can get that info
--                          from rel_constraints table or other views.
--
-- Another Note: not all segemnts in rel_segemnts are returned by this view.
-- This view only returns segments S that have at least one rel_constraints row
-- where rel_segment = S.  Segments that have no constraints defined on them
-- can be said to have dependency_level=0, hence the outer join and nvl in the
-- example query above (see "Answer:").  I could have embeded that logic into
-- this view, but that would unnecessarily degrade performance.
--
create or replace view rc_segment_dependency_levels as
      select rel_segment as segment_id,
             max(tree_level) as dependency_level
      from (select rel_segment, level as tree_level
            from rel_constraints
            connect by required_rel_segment = prior rel_segment
                and prior rel_side = 'two')
      group by rel_segment
;

--------------------------------------------------------------
-- Relationship Type Views
-- oumi@arsdigita.com
-- 2/9/2001
--
-- created in acs-relationships-create.sql
--------------------------------------------------------------

-- These views are handy for metadata driven UI

-- View: rel_types_valid_obj_one_types
--
-- Question: Given rel_type :rel_type,
--
--           What are all the valid object_types for object_id_one of 
--           a relation of type :rel_type
--
-- Answer:   select object_type
--           from rel_types_valid_obj__one_types
--           where rel_type = :rel_type
--
create or replace view rel_types_valid_obj_one_types as
select rt.rel_type, th.object_type
from acs_rel_types rt,
     (select object_type, ancestor_type
      from acs_object_type_supertype_map
      UNION ALL
      select object_type, object_type as ancestor_type 
      from acs_object_types) th
where rt.object_type_one = th.ancestor_type;


-- View: rel_types_valid_obj_two_types
--
-- Question: Given rel_type :rel_type,
--
--           What are all the valid object_types for object_id_two of 
--           a relation of type :rel_type
--
-- Answer:   select object_type
--           from rel_types_valid_obj_two_types
--           where rel_type = :rel_type
--
create or replace view rel_types_valid_obj_two_types as
select rt.rel_type, th.object_type
from acs_rel_types rt,
     (select object_type, ancestor_type
      from acs_object_type_supertype_map
      UNION ALL
      select object_type, object_type as ancestor_type 
      from acs_object_types) th
where rt.object_type_two = th.ancestor_type;


--------------------------------------------------------------
-- community-core.sql
-- oumi@arsdigita.com
-- 2/13/2001
--
-- CHANGES
-- Added first_names and last_name as attributes of a person.
-- The subsite pages use this metadata to generate forms for
-- adding parties to a subsite. 
--------------------------------------------------------------

declare
  attr_id integer;
begin

 attr_id := acs_attribute.create_attribute (
        object_type => 'person',
        attribute_name => 'first_names',
        datatype => 'string',
        pretty_name => 'First Names',
        pretty_plural => 'First Names',
	min_n_values => 0,
	max_n_values => 1
      );

 attr_id := acs_attribute.create_attribute (
        object_type => 'person',
        attribute_name => 'last_name',
        datatype => 'string',
        pretty_name => 'Last Name',
        pretty_plural => 'Last Names',
	min_n_values => 0,
	max_n_values => 1
      );

end;
/
show errors


--------------------------------------------------------------
-- groups-create.sql
-- oumi@arsdigita.com
-- 2/22/2001
--
-- Changes:
-- Added rel_type to the group_approved_member_map view.
-- Fixed the approval policy / default new member policy stuff
--------------------------------------------------------------

/* Restrict membership to persons.  Previously, a group could be a member
 * of another group.  Now, only a person can be a member of a group.
 * A group can still be a component of another group through a composition 
 * relation
 */
update acs_rel_types
set object_type_two='person'
where rel_type = 'membership_rel';

create or replace view group_approved_member_map
as select gm.group_id, gm.member_id, gm.rel_id, gm.container_id, gm.rel_type
   from group_member_map gm, membership_rels mr
   where gm.rel_id = mr.rel_id
   and mr.member_state = 'approved';


-- Replace approval_policy and default_new_member_policy with join_policy,
-- because the original columns didn't make much sense, had no check 
-- constraints, weren't used by any code, etc.
alter table group_types add (
    default_join_policy  varchar2(30) default 'open' not null
                         constraint group_types_join_policy_ck
                         check (default_join_policy in 
                                ('open', 'needs approval', 'closed'))
);
alter table group_types drop column approval_policy;
alter table group_types drop column default_new_member_policy;

alter table groups add (
   join_policy           varchar2(30) default 'open' not null
                         constraint groups_join_policy_ck
                         check (join_policy in 
                                ('open', 'needs approval', 'closed'))
);

alter table membership_rels drop constraint membership_rel_mem_ck;
alter table membership_rels add constraint membership_rel_mem_ck
    check (member_state in ('approved', 'needs approval', 'banned', 'rejected', 'deleted'));

update membership_rels 
    set member_state = 'needs approval' 
where member_state is null;

commit;

alter table membership_rels modify
    member_state not null;


-- Now we change the default member_state value in the pl/sql packages

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

  procedure reject (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure unapprove (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure deleted (
    rel_id      in membership_rels.rel_id%TYPE
  );

  procedure delete (
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

  procedure delete (
    rel_id      in membership_rels.rel_id%TYPE
  )
  is
  begin
    acs_rel.delete(rel_id);
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

-- Next, we add join_policy to the acs_group pl/sql package

create or replace package acs_group
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
 ) return groups.group_id%TYPE;

 procedure delete (
   group_id     in groups.group_id%TYPE
 );

 function name (
  group_id      in groups.group_id%TYPE
 ) return varchar2;

 function member_p (
  party_id      in parties.party_id%TYPE
 ) return char;

 function check_representation (
  group_id      in groups.group_id%TYPE
 ) return char;

end acs_group;
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


  -- setup the permissible relationship types for this group
  insert into group_rels
  (group_rel_id, group_id, rel_type)
  select acs_object_id_seq.nextval, v_group_id, g.rel_type
    from group_type_rels g
   where g.group_type = new.object_type;

  return v_group_id;
 end new;


 procedure delete (
    group_id     in groups.group_id%TYPE
  )
  is
  begin
 
   -- Delete all segments defined for this group
   for row in (select segment_id 
                 from rel_segments 
                where group_id = acs_group.delete.group_id) loop

       rel_segment.delete(row.segment_id);

   end loop;

   -- Delete all the relations of any type to this group
   for row in (select r.rel_id, t.package_name
                 from acs_rels r, acs_object_types t
                where r.rel_type = t.object_type
                  and (r.object_id_one = acs_group.delete.group_id
                       or r.object_id_two = acs_group.delete.group_id)) loop
      execute immediate 'begin ' ||  row.package_name || '.delete(' || row.rel_id || '); end;';
   end loop;
 
   party.delete(group_id);
 end delete;

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
  party_id      in parties.party_id%TYPE
 )
 return char
 is
 begin
  -- TO DO: implement this for real
  return 't';
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

--------------------------------------------------------------
-- acs-permissions-create.sql
-- oumi@arsdigita.com
-- 2/21/2001
--
-- CHANGES
--
-- Modified acs_object_party_privilege_map to only map permissions on to
-- approved members of groups and segments, rather than all members.
--
-- Added views to provide an alternative to 
-- acs_object_party_privilege_map that may be faster in many
-- cases. 
--------------------------------------------------------------

create or replace view acs_object_party_privilege_map
as select ogpm.object_id, gmm.member_id as party_id, ogpm.privilege
   from acs_object_grantee_priv_map ogpm, group_approved_member_map gmm
   where ogpm.grantee_id = gmm.group_id
   union
   select ogpm.object_id, rsmm.member_id as party_id, ogpm.privilege
   from acs_object_grantee_priv_map ogpm, rel_seg_approved_member_map rsmm
   where ogpm.grantee_id = rsmm.segment_id
   union
   select object_id, grantee_id as party_id, privilege
   from acs_object_grantee_priv_map
   union
   select object_id, u.user_id as party_id, privilege
   from acs_object_grantee_priv_map m, users u
   where m.grantee_id = -1
   union
   select object_id, 0 as party_id, privilege
   from acs_object_grantee_priv_map
   where grantee_id = -1;

create or replace view acs_grantee_party_map as
   select -1 as grantee_id, 0 as party_id from dual
   union all
   select -1 as grantee_id, user_id as party_id
   from users
   union all
   select party_id as grantee_id, party_id
   from parties
   union all
   select segment_id as grantee_id, member_id
   from rel_seg_approved_member_map
   union all
   select group_id as grantee_id, member_id as party_id
   from group_approved_member_map;


-- This view is like acs_object_party_privilege_map, but does not 
-- necessarily return distinct rows.  It may be *much* faster to join
-- against this view instead of acs_object_party_privilege_map, and is
-- usually not much slower.  The tradeoff for the performance boost is
-- increased complexity in your usage of the view.  Example usage that I've
-- found works well is:
--
--    select DISTINCT 
--           my_table.*
--    from my_table,
--         (select object_id
--          from all_object_party_privilege_map 
--          where party_id = :user_id and privilege = :privilege) oppm
--    where oppm.object_id = my_table.my_id;
--

create or replace view all_object_party_privilege_map as
select /*+ ORDERED */ 
               op.object_id,
               pdm.descendant as privilege,
               gpm.party_id as party_id
        from acs_object_paths op, 
             acs_permissions p, 
             acs_privilege_descendant_map pdm,
             acs_grantee_party_map gpm
        where op.ancestor_id = p.object_id 
          and pdm.privilege = p.privilege
          and gpm.grantee_id = p.grantee_id;
