--
-- acs-kernel/sql/acs-permissions-create.sql
--
-- The ACS core permissioning system. The knowledge level of system
-- allows you to define a hierarchichal system of privilages, and
-- associate them with low level operations on object types. The
-- operational level allows you to grant to any party a privilege on
-- any object.
--
-- @author Rafael Schloming (rhs@mit.edu)
--
-- @creation-date 2000-08-13
--
-- @cvs-id acs-permissions-create.sql,v 1.10.2.2 2001/01/12 22:59:20 oumi Exp
--


---------------------------------------------
-- KNOWLEDGE LEVEL: PRIVILEGES AND ACTIONS --
---------------------------------------------

-- suggestion: acs_methods, acs_operations, acs_transactions?
-- what about cross-type actions? new-stuff? site-wide search?

--create table acs_methods (
--	object_type	not null constraint acs_methods_object_type_fk
--			references acs_object_types (object_type),
--	method		varchar2(100) not null,
--	constraint acs_methods_pk
--	primary key (object_type, method)
--);

--comment on table acs_methods is '
-- Each row in the acs_methods table directly corresponds to a
-- transaction on an object. For example an sql statement that updates a
-- bboard message would require an entry in this table.
--'

create table acs_privileges (
	privilege	varchar(100) not null constraint acs_privileges_pk
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
        tree_sortkey    varchar(4000)
);

create index priv_hier_sortkey_idx on 
acs_privilege_hierarchy_index (tree_sortkey);


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
--    and h1.tree_sortkey like (h2.tree_sortkey || '%')
--    and h2.tree_sortkey < h1.tree_sortkey;

-- Also since acs_privilege_descendant_map is simply a path enumeration of
-- acs_privilege_hierarchy, we should be able to replace the above connect-by
-- with: 

-- select privilege 
-- from acs_privilege_descendant_map 
-- where descendant = 'cm_perm'

-- This would be better, since the same query could be used for both oracle
-- and postgresql.

create function acs_priv_hier_ins_del_tr () returns opaque as '
declare
        new_key         varchar;
        deleted_p       boolean;
        v_rec           record;
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

            select ''/'' || tree_next_key(max(tree_sortkey)) into new_key 
              from acs_privilege_hierarchy_index
             where tree_level(tree_sortkey) = 1;

             -- insert the new node

            insert into acs_privilege_hierarchy_index 
                        (privilege, child_privilege, tree_sortkey)
                        values
                        (v_rec.privilege, v_rec.child_privilege, new_key);

            -- now recurse down from this node

            PERFORM priv_recurse_subtree(new_key, v_rec.child_privilege);

        end LOOP;

        return new;

end;' language 'plpgsql';

create trigger acs_priv_hier_ins_del_tr after insert or delete
on acs_privilege_hierarchy for each row
execute procedure acs_priv_hier_ins_del_tr ();

create function priv_recurse_subtree(varchar, varchar) 
returns integer as '
declare
        nkey            alias for $1;
        child_priv      alias for $2;
        new_key         varchar;
        v_rec           record;
begin

        -- now iterate over all of the children of the 
        -- previous node.
        
        for v_rec in select privilege, child_privilege
                       from acs_privilege_hierarchy
                      where privilege = child_priv

        LOOP

            -- calculate the next key for this level and parent

            select tree_next_key(max(tree_sortkey)) into new_key
              from acs_privilege_hierarchy_index
             where tree_sortkey like nkey || ''/%''
               and tree_sortkey not like  nkey || ''/%/%'';

            new_key := nkey || ''/'' || new_key;

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
                       (child_priv, child_priv, nkey || ''/00'');
        end if;

        return null;

end;' language 'plpgsql';

--create table acs_privilege_method_rules (
--	privilege	not null constraint acs_priv_method_rules_priv_fk
--			references acs_privileges (privilege),
--	object_type	varchar2(100) not null,
--	method		varchar2(100) not null,
--	constraint acs_privilege_method_rules_pk
--	primary key (privilege, object_type, method),
--	constraint acs_priv_meth_rul_type_meth_fk
--	foreign key (object_type, method) references acs_methods
--);

comment on table acs_privileges is '
 The rows in this table correspond to aggregations of specific
 methods. Privileges share a global namespace. This is to avoid a
 situation where granting the foo privilege on one type of object can
 have an entirely different meaning than granting the foo privilege on
 another type of object.
';

comment on table acs_privilege_hierarchy is '
 The acs_privilege_hierarchy gives us an easy way to say: The foo
 privilege is a superset of the bar privilege.
';

--comment on table acs_privilege_method_rules is '
-- The privilege method map allows us to create rules that specify which
-- methods a certain privilege is allowed to invoke in the context of a
-- particular object_type. Note that the same privilege can have
-- different methods for different object_types. This is because each
-- method corresponds to a piece of code, and the code that displays an
-- instance of foo will be different than the code that displays an
-- instance of bar. If there are no methods defined for a particular
-- (privilege, object_type) pair, then that privilege is not relavent to
-- that object type, for example there is no way to moderate a user, so
-- there would be no additional methods that you could invoke if you
-- were granted moderate on a user.
--'

--create or replace view acs_privilege_method_map
--as select r1.privilege, pmr.object_type, pmr.method
--     from acs_privileges r1, acs_privileges r2, acs_privilege_method_rules pmr
--    where r2.privilege in (select distinct rh.child_privilege
--                           from acs_privilege_hierarchy rh
--                           start with privilege = r1.privilege
--                           connect by prior child_privilege = privilege
--                           union
--                           select r1.privilege
--                           from dual)
--      and r2.privilege = pmr.privilege;

-- create or replace package acs_privilege
-- as
-- 
--   procedure create_privilege (
--     privilege	in acs_privileges.privilege%TYPE,
--     pretty_name   in acs_privileges.pretty_name%TYPE default null,
--     pretty_plural in acs_privileges.pretty_plural%TYPE default null 
--   );
-- 
--   procedure drop_privilege (
--     privilege	in acs_privileges.privilege%TYPE
--   );
-- 
--   procedure add_child (
--     privilege		in acs_privileges.privilege%TYPE,
--     child_privilege	in acs_privileges.privilege%TYPE
--   );
-- 
--   procedure remove_child (
--     privilege		in acs_privileges.privilege%TYPE,
--     child_privilege	in acs_privileges.privilege%TYPE
--   );
-- 
-- end;

-- show errors

-- create or replace package body acs_privilege
-- procedure create_privilege
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


-- procedure drop_privilege
create function acs_privilege__drop_privilege (varchar)
returns integer as '
declare
  drop_privilege__privilege     alias for $1;  
begin
    delete from acs_privileges
    where privilege = drop_privilege__privilege;

    return 0; 
end;' language 'plpgsql';

-- procedure add_child
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

-- procedure remove_child
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



-- show errors


------------------------------------
-- OPERATIONAL LEVEL: PERMISSIONS --
------------------------------------

create table acs_permissions (
	object_id		integer not null
				constraint acs_permissions_on_what_id_fk
				references acs_objects (object_id),
	grantee_id		integer not null
				constraint acs_permissions_grantee_id_fk
				references parties (party_id),
	privilege		varchar(100) not null 
                                constraint acs_permissions_priv_fk
				references acs_privileges (privilege),
	constraint acs_permissions_pk
	primary key (object_id, grantee_id, privilege)
);

create index acs_permissions_grantee_idx on acs_permissions (grantee_id);
create index acs_permissions_privilege_idx on acs_permissions (privilege);

-- create view acs_privilege_descendant_map
-- as select p1.privilege, p2.privilege as descendant
--    from acs_privileges p1, acs_privileges p2
--    where p2.privilege in (select child_privilege
-- 			  from acs_privilege_hierarchy
-- 			  start with privilege = p1.privilege
-- 			  connect by prior child_privilege = privilege)
--    or p2.privilege = p1.privilege;

create view acs_privilege_descendant_map
as select p1.privilege, p2.privilege as descendant
   from acs_privileges p1, acs_privileges p2
   where exists (select h2.child_privilege
                   from
                     acs_privilege_hierarchy_index h1,
                     acs_privilege_hierarchy_index h2
                   where
                     h1.privilege = p1.privilege
                     and h2.privilege = p2.privilege
                     and h2.tree_sortkey like h1.tree_sortkey || '%');

create view acs_permissions_all
as select op.object_id, p.grantee_id, p.privilege
   from acs_object_paths op, acs_permissions p
   where op.ancestor_id = p.object_id;

create view acs_object_grantee_priv_map
as select a.object_id, a.grantee_id, m.descendant as privilege
   from acs_permissions_all a, acs_privilege_descendant_map m
   where a.privilege = m.privilege;

-- The last two unions make sure that the_public gets expaned to all
-- users plus 0 (the default user_id) we should probably figure out a
-- better way to handle this eventually since this view is getting
-- pretty freaking hairy. I'd love to be able to move this stuff into
-- a Java middle tier.

create view acs_object_party_privilege_map
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

----------------------------------------------------
-- ALTERNATE VIEW: ALL_OBJECT_PARTY_PRIVILEGE_MAP --
----------------------------------------------------

-- This view is a helper for all_object_party_privilege_map
create view acs_grantee_party_map as
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

-- create view all_object_party_privilege_map as
-- select /*+ ORDERED */ 
--                op.object_id,
--                pdm.descendant as privilege,
--                gpm.party_id as party_id
--         from acs_object_paths op, 
--              acs_permissions p, 
--              acs_privilege_descendant_map pdm,
--              acs_grantee_party_map gpm
--         where op.ancestor_id = p.object_id 
--          and pdm.privilege = p.privilege
--           and gpm.grantee_id = p.grantee_id;


create view all_object_party_privilege_map as
select         op.object_id,
               pdm.descendant as privilege,
               gpm.party_id as party_id
        from acs_object_paths op, 
             acs_permissions p, 
             acs_privilege_descendant_map pdm,
             acs_grantee_party_map gpm
        where op.ancestor_id = p.object_id 
          and pdm.privilege = p.privilege
          and gpm.grantee_id = p.grantee_id;


--create or replace view acs_object_party_method_map
--as select opp.object_id, opp.party_id, pm.object_type, pm.method
--   from acs_object_party_privilege_map opp, acs_privilege_method_map pm
--   where opp.privilege = pm.privilege;

-- create or replace package acs_permission
-- as
-- 
--   procedure grant_permission (
--     object_id	 acs_permissions.object_id%TYPE,
--     grantee_id	 acs_permissions.grantee_id%TYPE,
--     privilege	 acs_permissions.privilege%TYPE
--   );
-- 
--   procedure revoke_permission (
--     object_id	 acs_permissions.object_id%TYPE,
--     grantee_id	 acs_permissions.grantee_id%TYPE,
--     privilege	 acs_permissions.privilege%TYPE
--   );
-- 
--   function permission_p (
--     object_id	 acs_objects.object_id%TYPE,
--     party_id	 parties.party_id%TYPE,
--     privilege	 acs_privileges.privilege%TYPE
--   ) return char;
-- 
-- end acs_permission;

-- show errors

-- create or replace package body acs_permission
-- procedure grant_permission
create function acs_permission__grant_permission (integer, integer, varchar)
returns integer as '
declare
    grant_permission__object_id         alias for $1;
    grant_permission__grantee_id        alias for $2;
    grant_permission__privilege         alias for $3;
begin
    insert into acs_permissions
      (object_id, grantee_id, privilege)
    values
      (grant_permission__object_id, grant_permission__grantee_id, 
       grant_permission__privilege);

  -- FIXME: find out what this means?
  -- exception
  --  when dup_val_on_index then
  --    return;
  return 0; 
end;' language 'plpgsql';


-- procedure revoke_permission
create function acs_permission__revoke_permission (integer, integer, varchar)
returns integer as '
declare
    revoke_permission__object_id         alias for $1;
    revoke_permission__grantee_id        alias for $2;
    revoke_permission__privilege         alias for $3;
begin
    delete from acs_permissions
    where object_id = revoke_permission__object_id
    and grantee_id = revoke_permission__grantee_id
    and privilege = revoke_permission__privilege;

    return 0; 
end;' language 'plpgsql';


-- Speedy version of permission_p from Matthew Avalos
create function acs_permission__permission_p (integer,integer,varchar)
returns boolean as '
declare
    permission_p__object_id           alias for $1;
    permission_p__party_id            alias for $2;
    permission_p__privilege           alias for $3;
    exists_p                          boolean;
begin
    --
    -- Check group permmissions
    select 1 into exists_p
     where exists (
          select 1
          from acs_object_grantee_priv_map ogpm,
               group_approved_member_map gmm
         where object_id = permission_p__object_id
           and gmm.member_id = permission_p__party_id
           and privilege = permission_p__privilege
           and ogpm.grantee_id = gmm.group_id);
    if FOUND then
        return ''t'';
    end if;
    --
    -- relational segment approved group
    select 1 into exists_p
     where exists (
        select 1
          from acs_object_grantee_priv_map ogpm,
               rel_seg_approved_member_map rsmm
         where object_id = permission_p__object_id
           and rsmm.member_id = permission_p__party_id
           and privilege = permission_p__privilege
           and ogpm.grantee_id = rsmm.segment_id);
    if FOUND then
        return ''t'';
    end if;
    --
    -- Check direct permissions
    select 1 into exists_p
     where exists (
        select 1
          from acs_object_grantee_priv_map
         where object_id = permission_p__object_id
           and grantee_id = permission_p__party_id
           and privilege = permission_p__privilege);
    if FOUND then
        return ''t'';
    end if;
    --
    -- Check public permissions
    select 1 into exists_p
     where exists (
        select 1
          from acs_object_grantee_priv_map m, users u
         where object_id = permission_p__object_id
           and u.user_id = permission_p__party_id
           and privilege = permission_p__privilege
           and m.grantee_id = -1);
    if FOUND then
        return ''t'';
    end if;
    --
    -- Check public-like permissions
    select 1 into exists_p
     where exists (
        select 1
          from acs_object_grantee_priv_map
         where object_id = permission_p__object_id
           and 0 = permission_p__party_id
           and privilege = permission_p__privilege
           and grantee_id = -1);
    --
    if FOUND then
       return ''t'';
    else
       return ''f'';
    end if;
end;' language 'plpgsql';



-- show errors
