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



-- DanW: eliminated hierarchy index in favor of using descendant map


create function acs_priv_hier_ins_tr() returns opaque as '
declare
        v_rec record;
        v_id  integer;
        v_lvl integer;
        v_cont boolean;
begin

        -- first insert the new child relation if it does not exist already
        insert into acs_privilege_descendant_map
        select new.privilege, new.child_privilege as descendant
         where not exists (select 1 
                             from acs_privilege_descendant_map
                            where privilege = new.privilege
                              and descendant = new.child_privilege);

        -- insert self-reference for privilege
        insert into acs_privilege_descendant_map
        select new.privilege, new.privilege as descendant
         where not exists (select 1 
                             from acs_privilege_descendant_map
                            where privilege = new.privilege
                              and descendant = new.privilege);

        -- insert self-reference for descendant
        insert into acs_privilege_descendant_map
        select new.child_privilege as privilege, new.child_privilege as descendant
         where not exists (select 1 
                             from acs_privilege_descendant_map
                            where privilege = new.child_privilege
                              and descendant = new.child_privilege);

        -- now look for existing children to add to
        for v_rec in select privilege, descendant
                       from acs_privilege_descendant_map
                      where descendant = new.privilege
        LOOP
                insert into acs_privilege_descendant_map
                select v_rec.privilege, new.child_privilege as descendant
                 where not exists (select 1
                                     from acs_privilege_descendant_map
                                    where privilege =  v_rec.privilege
                                      and descendant = new.child_privilege);
        end LOOP;

        -- now look for existing parents to add to
        for v_rec in select privilege, descendant
                       from acs_privilege_descendant_map
                      where privilege = new.child_privilege
        LOOP
                insert into acs_privilege_descendant_map
                select new.privilege, v_rec.descendant
                 where not exists (select 1
                                     from acs_privilege_descendant_map
                                    where privilege =  new.privilege
                                      and descendant = v_rec.descendant);
        end LOOP;


        return new;

end;' language 'plpgsql';


create trigger acs_priv_hier_ins_tr after insert
on acs_privilege_hierarchy for each row
execute procedure acs_priv_hier_ins_tr ();



create function recurse_del_priv_hier(varchar,varchar) 
returns varchar as '
declare
        parent  alias for $1;
        child   alias for $2;
        v_rec   record;
begin
        -- now look for more children of this child
        for v_rec in  select privilege, 
                             child_privilege 
                        from acs_privilege_hierarchy
                       where privilege = child
        LOOP
            -- insert the children
            insert into acs_privilege_descendant_map
            select parent as privilege, v_rec.child_privilege as descendant
             where not exists (select 1 
                                 from acs_privilege_descendant_map 
                                where privilege = parent 
                                  and descendant = v_rec.child_privilege);

            -- and recurse down ad-nauseum
            PERFORM recurse_del_priv_hier(parent,v_rec.child_privilege); 
        end loop;

        return null;
end;' language 'plpgsql';

create function acs_priv_hier_del_tr() returns opaque as '
declare
        v_rec record;
        v_id  integer;
begin
        -- rebuild from scratch
        delete from acs_privilege_descendant_map;

        -- loop through the top-level of privileges
        for v_rec in  select privilege, 
                             child_privilege 
                        from acs_privilege_hierarchy
        LOOP
                -- insert the top level privileges if they do not already exist
                insert into acs_privilege_descendant_map
                select v_rec.privilege, v_rec.child_privilege as descendant
                 where not exists (select 1 
                                     from acs_privilege_descendant_map 
                                    where privilege = v_rec.privilege 
                                      and descendant = v_rec.child_privilege);

                -- now recurse down to the next level                      
                PERFORM recurse_del_priv_hier(v_rec.privilege,v_rec.child_privilege);
        end LOOP;

        -- provide self-mapping
        for v_rec in select privilege, privilege as child_privilege 
                       from acs_privilege_descendant_map
                      
        LOOP

                insert into acs_privilege_descendant_map
                select v_rec.privilege, v_rec.child_privilege as descendant
                 where not exists (select 1 
                                     from acs_privilege_descendant_map 
                                    where privilege = v_rec.privilege 
                                      and descendant = v_rec.child_privilege);
        end loop;

        -- provide self-mapping
        for v_rec in select descendant as privilege, descendant as child_privilege 
                       from acs_privilege_descendant_map
                      
        LOOP

                insert into acs_privilege_descendant_map
                select v_rec.privilege, v_rec.child_privilege as descendant
                 where not exists (select 1 
                                     from acs_privilege_descendant_map 
                                    where privilege = v_rec.privilege 
                                      and descendant = v_rec.child_privilege);
        end loop;


        return new;

end;' language 'plpgsql';

create trigger acs_priv_hier_del_tr after delete
on acs_privilege_hierarchy for each row
execute procedure acs_priv_hier_del_tr ();



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

-- DRB: This view does seem to be quite fast in Postgres as well as Oracle.

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

create function acs_permissions_lock_tr () returns opaque as '
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
create function acs_permission__revoke_permission (integer, integer, varchar)
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

-- Speedy version of permission_p from Matthew Avalos
-- Further improved to a minor degree by Don Baccus

create function acs_permission__permission_p (integer,integer,varchar)
returns boolean as '
declare
    permission_p__object_id           alias for $1;
    permission_p__party_id            alias for $2;
    permission_p__privilege           alias for $3;
    exists_p                          boolean;
begin
    --
    -- Check public-like permissions
    if (0 = permission_p__party_id or
        exists (select 1 from users where user_id = permission_p__party_id)) and
        exists (select 1
                from acs_object_grantee_priv_map
                where object_id = permission_p__object_id
                  and privilege = permission_p__privilege
                  and grantee_id = -1)
    --
    then
       return ''t'';
    end if;
    --
    -- Check direct permissions
    if exists (
        select 1
          from acs_object_grantee_priv_map
         where object_id = permission_p__object_id
           and grantee_id = permission_p__party_id
           and privilege = permission_p__privilege)
    then
        return ''t'';
    end if;
    --
    -- Check group permmissions
    if exists (
          select 1
          from acs_object_grantee_priv_map ogpm,
               group_approved_member_map gmm
         where object_id = permission_p__object_id
           and gmm.member_id = permission_p__party_id
           and privilege = permission_p__privilege
           and ogpm.grantee_id = gmm.group_id)
    then
        return ''t'';
    end if;
    --
    -- relational segment approved group
    if exists (
        select 1
          from acs_object_grantee_priv_map ogpm,
               rel_seg_approved_member_map rsmm
         where object_id = permission_p__object_id
           and rsmm.member_id = permission_p__party_id
           and privilege = permission_p__privilege
           and ogpm.grantee_id = rsmm.segment_id)
    then
        return ''t'';
    end if;
    return ''f'';
end;' language 'plpgsql';

-- Returns true if at least one user exists with the given permission.  Used
-- to avoid some queries on acs_object_party_privilege_map.

create function acs_permission__user_with_perm_exists_p (integer,varchar)
returns boolean as '
declare
    permission_p__object_id           alias for $1;
    permission_p__privilege           alias for $2;
begin
    --
    -- Check public-like permissions
    if exists (select 1
               from acs_object_grantee_priv_map
                where object_id = permission_p__object_id
                  and privilege = permission_p__privilege
                  and grantee_id = -1)
    --
    then
       return ''t'';
    end if;
    --
    -- Check direct user permissions
    if exists (
        select 1
          from acs_object_grantee_priv_map, users
         where object_id = permission_p__object_id
           and grantee_id = user_id
           and privilege = permission_p__privilege)
    then
        return ''t'';
    end if;
    --
    -- Check group permmissions
    if exists (
          select 1
          from acs_object_grantee_priv_map ogpm,
               group_approved_member_map gmm
         where object_id = permission_p__object_id
           and privilege = permission_p__privilege
           and ogpm.grantee_id = gmm.group_id)
    then
        return ''t'';
    end if;
    --
    -- relational segment approved group
    if exists (
        select 1
          from acs_object_grantee_priv_map ogpm,
               rel_seg_approved_member_map rsmm
         where object_id = permission_p__object_id
           and privilege = permission_p__privilege
           and ogpm.grantee_id = rsmm.segment_id)
    then
        return ''t'';
    end if;
    return ''f'';
end;' language 'plpgsql';
