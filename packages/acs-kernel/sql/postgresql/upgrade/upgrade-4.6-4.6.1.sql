-- acs-kernel/sql/postgresql/upgrade/upgrade-4.6-4.6.1.sql
--
-- @author Jeff Davis (davis@xarg.net)
-- @creation-date 2002-12-17
-- @cvs-id $Id$

-- Add two new datatypes (supported by templating already).
--

insert into acs_datatypes
  (datatype, max_n_values)
values
  ('url', null);

insert into acs_datatypes
  (datatype, max_n_values)
values
  ('email', null);

-- declaring this function isstrict,iscachable can make a significant
-- performance difference since this is used in some potentially
-- expensive queries

create or replace function acs__magic_object_id (varchar)
returns integer as '
declare
  magic_object_id__name                   alias for $1;  
  magic_object_id__object_id              acs_objects.object_id%TYPE;
begin
    select object_id
    into magic_object_id__object_id
    from acs_magic_objects
    where name = magic_object_id__name;

    return magic_object_id__object_id;
   
end;' language 'plpgsql' with(isstrict,iscachable);

--------------------------------------------------------------------------------
--
-- Tilmann Singer - delete direct permissions when deleting an object.
--
create or replace function acs_object__delete (integer)
returns integer as '
declare
  delete__object_id              alias for $1;  
  obj_type                       record;
begin
  
  -- Delete dynamic/generic attributes
  delete from acs_attribute_values where object_id = delete__object_id;

  -- Delete direct permissions records.
  delete from acs_permissions where object_id = delete__object_id;

  -- select table_name, id_column
  --  from acs_object_types
  --  start with object_type = (select object_type
  --                              from acs_objects o
  --                             where o.object_id = delete__object_id)
  --  connect by object_type = prior supertype

  -- There was a gratuitous join against the objects table here,
  -- probably a leftover from when this was a join, and not a subquery.
  -- Functionally, this was working, but time taken was O(n) where n is the 
  -- number of objects. OUCH. Fixed. (ben)
  for obj_type
  in select o2.table_name, o2.id_column
        from acs_object_types o1, acs_object_types o2
       where o1.object_type = (select object_type
                               from acs_objects o
                               where o.object_id = delete__object_id)
         and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
    order by o2.tree_sortkey desc
  loop
    -- Delete from the table.

    -- DRB: I removed the quote_ident calls that DanW originally included
    -- because the table names appear to be stored in upper case.  Quoting
    -- causes them to not match the actual lower or potentially mixed-case
    -- table names.  We will just forbid squirrely names that include quotes.
-- daveB
-- ETP is creating a new object, but not a table, although it does specify a
-- table name, so we need to check if the table exists. Wp-slim does this too

    if table_exists(obj_type.table_name) then
      execute ''delete from '' || obj_type.table_name ||
          '' where '' || obj_type.id_column || '' =  '' || delete__object_id;
    end if;
  end loop;

  return 0; 
end;' language 'plpgsql';


--------------------------------------------------------------------------------

-- DRB: Change security context to object -4

create or replace function acs_objects_context_id_in_tr () returns opaque as '
declare
        security_context_root integer;
begin
  insert into acs_object_context_index
   (object_id, ancestor_id, n_generations)
  values
   (new.object_id, new.object_id, 0);

  if new.context_id is not null and new.security_inherit_p = ''t'' then
    insert into acs_object_context_index
     (object_id, ancestor_id, n_generations)
    select
     new.object_id as object_id, ancestor_id,
     n_generations + 1 as n_generations
    from acs_object_context_index
    where object_id = new.context_id;
  else
    security_context_root = acs__magic_object_id(''security_context_root'');
    if new.object_id != security_context_root then
      insert into acs_object_context_index
        (object_id, ancestor_id, n_generations)
      values
        (new.object_id, security_context_root, 1);
    end if;
  end if;

  return new;

end;' language 'plpgsql';

create or replace function acs_objects_context_id_up_tr () returns opaque as '
declare
        pair    record;
        security_context_root integer;
begin
  if new.object_id = old.object_id and
     new.context_id = old.context_id and
     new.security_inherit_p = old.security_inherit_p then
    return new;
  end if;

  -- Remove my old ancestors from my descendants.
  delete from acs_object_context_index
  where object_id in (select object_id
                      from acs_object_contexts
                      where ancestor_id = old.object_id)
  and ancestor_id in (select ancestor_id
		      from acs_object_contexts
		      where object_id = old.object_id);

  -- Kill all my old ancestors.
  delete from acs_object_context_index
  where object_id = old.object_id;

  insert into acs_object_context_index
   (object_id, ancestor_id, n_generations)
  values
   (new.object_id, new.object_id, 0);

  if new.context_id is not null and new.security_inherit_p = ''t'' then
     -- Now insert my new ancestors for my descendants.
    for pair in select *
		 from acs_object_context_index
		 where ancestor_id = new.object_id 
    LOOP
      insert into acs_object_context_index
       (object_id, ancestor_id, n_generations)
      select
       pair.object_id, ancestor_id,
       n_generations + pair.n_generations + 1 as n_generations
      from acs_object_context_index
      where object_id = new.context_id;
    end loop;
  else
    security_context_root = acs__magic_object_id(''security_context_root'');
    if new.object_id != security_context_root then
    -- We need to make sure that new.OBJECT_ID and all of its
    -- children have security_context_root as an ancestor.
    for pair in  select *
		 from acs_object_context_index
		 where ancestor_id = new.object_id 
      LOOP
        insert into acs_object_context_index
         (object_id, ancestor_id, n_generations)
        values
         (pair.object_id, security_context_root, pair.n_generations + 1);
      end loop;
    end if;
  end if;

  return new;

end;' language 'plpgsql';

-- DRB: This is the function that actually changes security_context_root
-- to -4 rather than 0

drop trigger acs_objects_context_id_in_tr on acs_objects;
drop trigger acs_objects_context_id_up_tr on acs_objects;

delete from acs_magic_objects
where name = 'security_context_root';

select acs_object__new (
  -4,
  'acs_object',
  now(),
  null,
  null,
  null
  );

insert into acs_magic_objects
 (name, object_id)
values
 ('security_context_root', -4);

update acs_object_context_index
set ancestor_id = -4
where ancestor_id = 0;

update acs_object_context_index
set object_id = -4
where object_id = 0;

update acs_permissions
set object_id = -4
where object_id = 0;

update acs_objects
set context_id = -4
where context_id = 0;

-- Content Repository sets parent_id to security_context_root
-- for content modules

update cr_items
set parent_id = -4
where parent_id = 0;

select acs_object__delete(0);

create trigger acs_objects_context_id_in_tr after insert on acs_objects
for each row execute procedure acs_objects_context_id_in_tr ();

create trigger acs_objects_context_id_up_tr after update on acs_objects
for each row execute procedure acs_objects_context_id_up_tr ();

-------------------------------------------------------------------------

-- DRB: We now will turn the magic -1 party into a group that contains
-- all registered users and a new unregistered visitor.  This will allow
-- us to do all permission checking on a materialized version of the
-- party_member_map.

-- Make our new "Unregistered Visitor" be object 0, which corresponds
-- with the user_id assigned throughout the toolkit Tcl code

insert into acs_objects
  (object_id, object_type)
values
  (0, 'person');

insert into parties
  (party_id)
values
  (0);

insert into persons
  (person_id, first_names, last_name)
values
  (0, 'Unregistered', 'Visitor');

insert into acs_magic_objects
  (name, object_id)
values
  ('unregistered_visitor', 0);

-- Now transform the old special -1 party into a legitimate group with
-- one user, our Unregistered Visitor

update acs_objects
set object_type = 'group'
where object_id = -1;
 
insert into groups
 (group_id, group_name, join_policy)
values
 (-1, 'The Public', 'closed');

-- Add our only user, the Unregistered Visitor

select membership_rel__new (
  null,
  'membership_rel',
  acs__magic_object_id('the_public'),      
  0,
  'approved',
  null,
  null);

-- Now declare "The Public" to be composed of itself and the "Registered
-- Users" group

select composition_rel__new (
  null,
  'composition_rel',
  acs__magic_object_id('the_public'),
  acs__magic_object_id('registered_users'),
  null,
  null);

-------------------------------------------------------------------------------

-- DRB: Replace the old party_emmber_map and party_approved_member_map views
-- (they were both the same and very slow) with a table containing the same
-- information.  This can be used to greatly speed permissions checking.

drop view party_member_map;
drop view party_approved_member_map;

-- Though for permission checking we only really need to map parties to
-- member users, the old view included identity entries for all parties
-- in the system.  It doesn't cost all that much to maintain the extra
-- rows so we will, just in case some overly clever programmer out there
-- depends on it.

-- This represents a large amount of redundant data which is separately
-- stored in the group_element_index table.   We might want to clean this
-- up in the future but time constraints on 4.6.1 require I keep this 
-- relatively simple.  Implementing a real "subgroup_rel" would help a
-- lot by in itself reducing the number of redundant rows in the two
-- tables.

create table party_approved_member_map (
    party_id        integer
                    constraint party_member_party_nn
                    not null
                    constraint party_member_party_fk
                    references parties,
    member_id       integer
                    constraint party_member_member_nn
                    not null
                    constraint party_member_member_fk
                    references parties,
    tag             integer
                    constraint party_member_tag_nn
                    not null,
    constraint party_approved_member_map_pk
    primary key (party_id, member_id, tag)
);

-- Need this to speed referential integrity 
create index party_member_member_idx on party_approved_member_map(member_id);

-- Every person is a member of itself

insert into party_approved_member_map
  (party_id, member_id, tag)
select party_id, party_id, 0
from parties;

-- Every party is a member if it is an approved member of
-- some sort of membership_rel

insert into party_approved_member_map
  (party_id, member_id, tag)
select group_id, member_id, rel_id
from group_approved_member_map;

-- Every party is a member if it is an approved member of
-- some sort of relation segment

insert into party_approved_member_map
  (party_id, member_id, tag)
select segment_id, member_id, rel_id
from rel_seg_approved_member_map;

analyze party_approved_member_map;

-- Helper functions to maintain the materialized party_approved_member_map. 

create or replace function party_approved_member__add_one(integer, integer, integer) returns integer as '
declare
  p_party_id alias for $1;
  p_member_id alias for $2;
  p_rel_id alias for $3;
begin

  insert into party_approved_member_map
    (party_id, member_id, tag)
  values
    (p_party_id, p_member_id, p_rel_id);

  return 1;

end;' language 'plpgsql';

create or replace function party_approved_member__add(integer, integer, integer, varchar) returns integer as '
declare
  p_party_id alias for $1;
  p_member_id alias for $2;
  p_rel_id alias for $3;
  p_rel_type alias for $4;
  v_segments record;
begin

  perform party_approved_member__add_one(p_party_id, p_member_id, p_rel_id);

  -- if the relation type is mapped to relational segments unmap them too

  for v_segments in select segment_id
                  from rel_segments s, acs_object_types o1, acs_object_types o2
                  where 
                    o1.object_type = p_rel_type
                    and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
                    and s.rel_type = o2.object_type
                    and s.group_id = p_party_id
  loop
    perform party_approved_member__add_one(v_segments.segment_id, p_member_id, p_rel_id);
  end loop;

  return 1;

end;' language 'plpgsql';

create or replace function party_approved_member__remove_one(integer, integer, integer) returns integer as '
declare
  p_party_id alias for $1;
  p_member_id alias for $2;
  p_rel_id alias for $3;
begin

  delete from party_approved_member_map
  where party_id = p_party_id
    and member_id = p_member_id
    and tag = p_rel_id;

  return 1;

end;' language 'plpgsql';

create or replace function party_approved_member__remove(integer, integer, integer, varchar) returns integer as '
declare
  p_party_id alias for $1;
  p_member_id alias for $2;
  p_rel_id alias for $3;
  p_rel_type alias for $4;
  v_segments record;
begin

  perform party_approved_member__remove_one(p_party_id, p_member_id, p_rel_id);

  -- if the relation type is mapped to relational segments unmap them too

  for v_segments in select segment_id
                  from rel_segments s, acs_object_types o1, acs_object_types o2
                  where 
                    o1.object_type = p_rel_type
                    and o1.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey)
                    and s.rel_type = o2.object_type
                    and s.group_id = p_party_id
  loop
    perform party_approved_member__remove_one(v_segments.segment_id, p_member_id, p_rel_id);
  end loop;

  return 1;

end;' language 'plpgsql';

-- Triggers to maintain party_approved_member_map when parties are created or
-- destroyed.

create or replace function parties_in_tr () returns opaque as '
begin

  insert into party_approved_member_map
    (party_id, member_id, tag)
  values
    (new.party_id, new.party_id, 0);

  return new;

end;' language 'plpgsql';

create trigger parties_in_tr after insert on parties
for each row execute procedure parties_in_tr ();

create or replace function parties_del_tr () returns opaque as '
begin

  delete from party_approved_member_map
  where party_id = old.party_id
    and member_id = old.party_id;

  return old;

end;' language 'plpgsql';

create trigger parties_del_tr before delete on parties
for each row execute procedure parties_del_tr ();

-- Triggers to maintain party_approved_member_map when relational segments are
-- created or destroyed.   We only remove the (segment_id, member_id) rows as
-- removing the relational segment itself does not remove members from the
-- group with that rel_type.  This was intentional on the part of the aD folks
-- who added relational segments to ACS 4.2.

create or replace function rel_segments_in_tr () returns opaque as '
begin

  insert into party_approved_member_map
    (party_id, member_id, tag)
  select new.segment_id, element_id, rel_id
    from group_element_index
    where group_id = new.group_id
      and rel_type = new.rel_type;

  return new;

end;' language 'plpgsql';

create trigger rel_segments_in_tr before insert on rel_segments
for each row execute procedure rel_segments_in_tr ();

create or replace function rel_segments_del_tr () returns opaque as '
begin

  delete from party_approved_member_map
  where party_id = old.segment_id
    and member_id in (select element_id
                      from group_element_index
                      where group_id = old.group_id
                        and rel_type = old.rel_type);

  return old;

end;' language 'plpgsql';

create trigger rel_segments_del_tr before delete on rel_segments
for each row execute procedure rel_segments_del_tr ();

-- The insert trigger was dummied up in groups-create.sql, so we just need
-- to replace the trigger function, not create the trigger

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

------------------------------------------------------------------------------------

-- DRB: upgrade to Dan Wickstrom's version of acs-permissions which materializes the
-- acs_privilege_descendant_map view.

drop view acs_privilege_descendant_map;
create table acs_privilege_descendant_map (
	privilege       varchar(100) not null 
                        constraint acs_priv_hier_priv_fk
			references acs_privileges (privilege),
        descendant      varchar(100) not null 
                        constraint acs_priv_hier_child_priv_fk
			references acs_privileges (privilege)

);

-- DRB: Empirical testing showed that even with just 61 entries in the new table
-- this index sped things up by roughly 15%

create index acs_priv_desc_map_idx on acs_privilege_descendant_map(descendant);

create view acs_privilege_descendant_map_view
as select p1.privilege, p2.privilege as descendant
   from acs_privileges p1, acs_privileges p2
   where exists (select h2.child_privilege
                   from
                     acs_privilege_hierarchy_index h1,
                     acs_privilege_hierarchy_index h2
                   where
                     h1.privilege = p1.privilege
                     and h2.privilege = p2.privilege
                     and h2.tree_sortkey between h1.tree_sortkey and tree_right(h1.tree_sortkey)) or
     p1.privilege = p2.privilege;

insert into acs_privilege_descendant_map (privilege, descendant) 
select privilege, descendant from acs_privilege_descendant_map_view;

drop view acs_object_grantee_priv_map;
create view acs_object_grantee_priv_map as
select a.object_id, a.grantee_id, m.descendant as privilege
   from acs_permissions_all a, acs_privilege_descendant_map m
   where a.privilege = m.privilege;

create or replace function acs_priv_hier_ins_del_tr () returns opaque as '
declare
        new_value       integer;
        new_key         varbit default null;
        v_rec           record;
        deleted_p       boolean;
begin
        -- if more than one node was deleted the second trigger call
        -- will error out.  This check avoids that problem.

        if TG_OP = ''DELETE'' then 
            select count(*) = 0 into deleted_p
              from acs_privilege_hierarchy_index 
             where old.privilege = privilege
               and old.child_privilege = child_privilege;     
       
            if deleted_p then

                return new;

            end if;
        end if;

        -- recalculate the table from scratch.

        delete from acs_privilege_hierarchy_index;

        -- first find the top nodes of the tree

        for v_rec in select privilege, child_privilege
                       from acs_privilege_hierarchy
                      where privilege 
                            NOT in (select distinct child_privilege
                                      from acs_privilege_hierarchy)
                                           
        LOOP

            -- top level node, so find the next key at this level.

            select max(tree_leaf_key_to_int(tree_sortkey)) into new_value 
              from acs_privilege_hierarchy_index
             where tree_level(tree_sortkey) = 1;

             -- insert the new node

            insert into acs_privilege_hierarchy_index 
                        (privilege, child_privilege, tree_sortkey)
                        values
                        (v_rec.privilege, v_rec.child_privilege, tree_next_key(null, new_value));

            -- now recurse down from this node

            PERFORM priv_recurse_subtree(tree_next_key(null, new_value), v_rec.child_privilege);

        end LOOP;

        -- materialize the map view to speed up queries
        -- DanW (dcwickstrom@earthlink.net) 30 Jan, 2003
        delete from acs_privilege_descendant_map;

        insert into acs_privilege_descendant_map (privilege, descendant) 
        select privilege, descendant from acs_privilege_descendant_map_view;

        return new;

end;' language 'plpgsql';


-- New fast version of acs_object_party_privilege_map

drop view acs_object_party_privilege_map;
create view acs_object_party_privilege_map as
select c.object_id, pdm.descendant as privilege, pamm.member_id as party_id
from acs_object_context_index c, acs_permissions p, acs_privilege_descendant_map pdm,
  party_approved_member_map pamm
where c.ancestor_id = p.object_id
  and pdm.privilege = p.privilege
  and pamm.party_id = p.grantee_id;

drop view all_object_party_privilege_map;
create view all_object_party_privilege_map as
select * from acs_object_party_privilege_map;

-- Really speedy version of permission_p written by Don Baccus

create or replace function acs_permission__permission_p (integer,integer,varchar)
returns boolean as '
declare
    permission_p__object_id           alias for $1;
    permission_p__party_id            alias for $2;
    permission_p__privilege           alias for $3;
    exists_p                          boolean;
begin
  return exists (select 1
                 from acs_permissions p, party_approved_member_map m,
                   acs_object_context_index c, acs_privilege_descendant_map h
                 where p.object_id = c.ancestor_id
                   and h.descendant = permission_p__privilege
                   and c.object_id = permission_p__object_id
                   and m.member_id = permission_p__party_id
                   and p.privilege = h.privilege
                   and p.grantee_id = m.party_id);
end;' language 'plpgsql';

-- No longer needed with fast acs_object_party_privilege_map
drop function acs_permission__user_with_perm_exists_p (integer,varchar);


