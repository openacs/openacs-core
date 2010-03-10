--
-- acs-kernel/sql/acs-permissions-create.sql
--
-- The ACS core permissioning system. The knowledge level of system
-- allows you to define a hierarchichal system of privilages.  The
-- operational level allows you to grant to any party a privilege on
-- any object.
--
-- @author Rafael Schloming (rhs@mit.edu)
--
-- @creation-date 2000-08-13
--
-- @cvs-id $Id$
--


---------------------------------------------
-- KNOWLEDGE LEVEL: PRIVILEGES AND ACTIONS --
---------------------------------------------

create table acs_privileges (
	privilege	varchar(100) not null constraint acs_privileges_privilege_pk
			primary key,
	pretty_name	varchar(100),
	pretty_plural	varchar(100)
);

create table acs_privilege_hierarchy (
	privilege	varchar(100) not null 
                        constraint acs_priv_hier_priv_fk
			references acs_privileges (privilege),
        child_privilege	varchar(100) not null 
                        constraint acs_priv_hier_child_priv_fk
			references acs_privileges (privilege),
	constraint acs_privilege_hierarchy_pk
	primary key (privilege, child_privilege)
);

create index acs_priv_hier_child_priv_idx on acs_privilege_hierarchy (child_privilege);

create table acs_privilege_hierarchy_index (
	privilege       varchar(100) not null 
                        constraint acs_priv_hier_priv_fk
			references acs_privileges (privilege),
        child_privilege varchar(100) not null 
                        constraint acs_priv_hier_child_priv_fk
			references acs_privileges (privilege),
        tree_sortkey    varbit
);

create index priv_hier_sortkey_idx on 
acs_privilege_hierarchy_index (tree_sortkey);

-- Added table to materialize view that previously used 
-- acs_privilege_descendant_map name
--
-- DanW (dcwickstrom@earthlink.net) 30 Jan, 2003

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

-- Gustaf (Jan 2009): interesting enough, the index above is never
-- used on openacs.org and can be most likely dropped. The index below
-- (together with acs_obj_ctx_idx_object_id_idx) makes real-world
-- applications more than a factor of 10 faster (openacs/download and
-- openacs/download/one-revision?revision_id=2089636)
create index acs_priv_desc_map_privilege_idx on acs_privilege_descendant_map (privilege);

-- This trigger is used to create a pseudo-tree hierarchy that
-- can be used to emulate tree queries on the acs_privilege_hierarchy table.
-- The acs_privilege_hierarchy table maintains the permissions structure, but 
-- it has a complication in that the same privileges can exist in more than one
-- path in the tree.  As such, tree queries cannot be represented by the 
-- usual tree query methods used for openacs.  

-- DCW, 2001-03-15.

-- usage: queries directly on acs_privilege_hierarchy don't seem to occur
--        in many places.  Rather it seems that acs_privilege_hierarchy is
--        used to build the view: acs_privilege_descendant_map.  I did however
--        find one tree query in content-perms.sql that looks like the 
--        following:

-- select privilege, child_privilege from acs_privilege_hierarchy
--           connect by prior privilege = child_privilege
--           start with child_privilege = 'cm_perm'

-- This query is used to find all of the ancestor permissions of 'cm_perm'. 
-- The equivalent query for the postgresql tree-query model would be:

-- select  h2.privilege 
--   from acs_privilege_hierarchy_index h1, 
--        acs_privilege_hierarchy_index h2
--  where h1.child_privilege = 'cm_perm'
--    and h1.tree_sortkey between h2.tree_sortkey and tree_right(h2.tree_sortkey)
--    and h2.tree_sortkey <> h1.tree_sortkey;

-- Also since acs_privilege_descendant_map is simply a path enumeration of
-- acs_privilege_hierarchy, we should be able to replace the above connect-by
-- with: 

-- select privilege 
-- from acs_privilege_descendant_map 
-- where descendant = 'cm_perm'

-- This would be better, since the same query could be used for both oracle
-- and postgresql.

create or replace function acs_priv_hier_ins_del_tr () returns trigger as '
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

create trigger acs_priv_hier_ins_del_tr after insert or delete
on acs_privilege_hierarchy for each row
execute procedure acs_priv_hier_ins_del_tr ();

create or replace function acs_priv_del_tr () returns trigger as '
begin

  delete from acs_privilege_descendant_map
  where privilege = old.privilege;

  return old;

end;' language 'plpgsql';

create trigger acs_priv_del_tr before delete
on acs_privileges for each row
execute procedure acs_priv_del_tr ();

create function priv_recurse_subtree(varbit, varchar) 
returns integer as '
declare
        nkey            alias for $1;
        child_priv      alias for $2;
        new_value       integer;
        v_rec           record;
        new_key         varbit;
begin

        -- now iterate over all of the children of the 
        -- previous node.
        
        for v_rec in select privilege, child_privilege
                       from acs_privilege_hierarchy
                      where privilege = child_priv

        LOOP

            -- calculate the next key for this level and parent

            select max(tree_leaf_key_to_int(tree_sortkey)) into new_value
              from acs_privilege_hierarchy_index
             where tree_sortkey between nkey and tree_right(nkey)
               and tree_level(tree_sortkey) = tree_level(nkey) + 1;

            new_key := tree_next_key(nkey, new_value);

            -- insert the new child node.

            insert into acs_privilege_hierarchy_index
                        (privilege, child_privilege, tree_sortkey)
                        values
                        (v_rec.privilege, v_rec.child_privilege, new_key);

            -- keep recursing down until no more children are found

            PERFORM priv_recurse_subtree(new_key, v_rec.child_privilege);

        end LOOP;

        -- no children found, so insert the child node as its own separate 
        -- node.

        if NOT FOUND then
           insert into acs_privilege_hierarchy_index
                       (privilege, child_privilege, tree_sortkey)
                       values 
                       (child_priv, child_priv, tree_next_key(nkey, null));
        end if;

        return null;

end;' language 'plpgsql';

comment on table acs_privileges is '
 Privileges share a global namespace. This is to avoid a
 situation where granting the foo privilege on one type of object can
 have an entirely different meaning than granting the foo privilege on
 another type of object.
';

comment on table acs_privilege_hierarchy is '
 The acs_privilege_hierarchy gives us an easy way to say: The foo
 privilege is a superset of the bar privilege.
';

create function acs_privilege__create_privilege (varchar,varchar,varchar)
returns integer as '
declare
  create_privilege__privilege              alias for $1;  
  create_privilege__pretty_name            alias for $2;  -- default null  
  create_privilege__pretty_plural          alias for $3;  -- default null
begin
    insert into acs_privileges
     (privilege, pretty_name, pretty_plural)
    values
     (create_privilege__privilege, 
      create_privilege__pretty_name, 
      create_privilege__pretty_plural);
      
    return 0; 
end;' language 'plpgsql';

create function acs_privilege__create_privilege (varchar)
returns integer as '
declare
  create_privilege__privilege              alias for $1;
begin
    return acs_privilege__create_privilege(create_privilege__privilege, null, null);
end;' language 'plpgsql';


create function acs_privilege__drop_privilege (varchar)
returns integer as '
declare
  drop_privilege__privilege     alias for $1;  
begin
    delete from acs_privileges
    where privilege = drop_privilege__privilege;

    return 0; 
end;' language 'plpgsql';

create function acs_privilege__add_child (varchar,varchar)
returns integer as '
declare
  add_child__privilege              alias for $1;  
  add_child__child_privilege        alias for $2;  
begin
    insert into acs_privilege_hierarchy
     (privilege, child_privilege)
    values
     (add_child__privilege, add_child__child_privilege);

    return 0; 
end;' language 'plpgsql';

create function acs_privilege__remove_child (varchar,varchar)
returns integer as '
declare
  remove_child__privilege              alias for $1;  
  remove_child__child_privilege        alias for $2;  
begin
    delete from acs_privilege_hierarchy
    where privilege = remove_child__privilege
    and child_privilege = remove_child__child_privilege;

    return 0; 
end;' language 'plpgsql';


------------------------------------
-- OPERATIONAL LEVEL: PERMISSIONS --
------------------------------------

create table acs_permissions (
	object_id		integer not null
				constraint acs_permissions_object_id_fk
				references acs_objects (object_id)
                                on delete cascade,
	grantee_id		integer not null
				constraint acs_permissions_grantee_id_fk
				references parties (party_id)
                                on delete cascade,
	privilege		varchar(100) not null 
                                constraint acs_permissions_privilege_fk
				references acs_privileges (privilege)
                                on delete cascade,
	constraint acs_permissions_pk
	primary key (object_id, grantee_id, privilege)
);

create index acs_permissions_grantee_idx on acs_permissions (grantee_id);
create index acs_permissions_privilege_idx on acs_permissions (privilege);
create index acs_permissions_object_id_idx on acs_permissions(object_id);

-- Added table to materialize view that previously used 
-- acs_privilege_descendant_map name
--
-- DanW (dcwickstrom@earthlink.net) 30 Jan, 2003

-- DRB: I switched this to UNION form because the old view was incredibly
-- slow and caused installation of packages to take exponentially increasing
-- time.   No code should be querying against this view other than the
-- trigger that recreates the denormalized map anyway ...

create view acs_privilege_descendant_map_view
as select distinct h1.privilege, h2.child_privilege as descendant
   from acs_privilege_hierarchy_index h1, acs_privilege_hierarchy_index h2
   where h2.tree_sortkey between h1.tree_sortkey and tree_right(h1.tree_sortkey)
   union
   select privilege, privilege
   from acs_privileges;

create view acs_permissions_all
as select op.object_id, p.grantee_id, p.privilege
   from acs_object_paths op, acs_permissions p
   where op.ancestor_id = p.object_id;

create view acs_object_grantee_priv_map
as select a.object_id, a.grantee_id, m.descendant as privilege
   from acs_permissions_all a, acs_privilege_descendant_map m
   where a.privilege = m.privilege;

-- New fast version of acs_object_party_privilege_map

create view acs_object_party_privilege_map as
select c.object_id, pdm.descendant as privilege, pamm.member_id as party_id
from acs_object_context_index c, acs_permissions p, acs_privilege_descendant_map pdm,
  party_approved_member_map pamm
where c.ancestor_id = p.object_id
  and pdm.privilege = p.privilege
  and pamm.party_id = p.grantee_id;

create view all_object_party_privilege_map as
select * from acs_object_party_privilege_map;


-- This table acts as a mutex for inserts/deletes from acs_permissions.
-- This is used since postgresql's exception handing mechanism is non-
-- existant.  A dup insert on acs_permissions will roll-back the 
-- transaction and give an error, which is not what we want.  Using a 
-- separate table for locking allows us exclusive access for 
-- inserts/deletes, but does not block readers.  That way we don't 
-- slow down permissions-checking which is known to have performance 
-- problems already.

-- (OpenACS - DanW)

create table acs_permissions_lock (
       lck  integer
);

create function acs_permissions_lock_tr () returns trigger as '
begin
        raise EXCEPTION ''FOR LOCKING ONLY, NO DML STATEMENTS ALLOWED'';
        return null;
end;' language 'plpgsql';

create trigger acs_permissions_lock_tr 
before insert or update or delete on acs_permissions_lock
for each row execute procedure acs_permissions_lock_tr();

create function acs_permission__grant_permission (integer, integer, varchar)
returns integer as '
declare
    grant_permission__object_id         alias for $1;
    grant_permission__grantee_id        alias for $2;
    grant_permission__privilege         alias for $3;
    exists_p                            boolean;
begin
    lock table acs_permissions_lock;

    select count(*) > 0 into exists_p
      from acs_permissions
     where object_id = grant_permission__object_id
       and grantee_id = grant_permission__grantee_id
       and privilege = grant_permission__privilege;

    if not exists_p then

        insert into acs_permissions
          (object_id, grantee_id, privilege)
          values
          (grant_permission__object_id, grant_permission__grantee_id, 
          grant_permission__privilege);

    end if;

    -- exception
    --  when dup_val_on_index then
    --    return;

    return 0; 
end;' language 'plpgsql';


-- procedure revoke_permission
create or replace function acs_permission__revoke_permission (integer, integer, varchar)
returns integer as '
declare
    revoke_permission__object_id         alias for $1;
    revoke_permission__grantee_id        alias for $2;
    revoke_permission__privilege         alias for $3;
begin
    lock table acs_permissions_lock;

    delete from acs_permissions
    where object_id = revoke_permission__object_id
    and grantee_id = revoke_permission__grantee_id
    and privilege = revoke_permission__privilege;

    return 0; 
end;' language 'plpgsql';

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
end;' language 'plpgsql' stable;
