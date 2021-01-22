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
-- KNOWLEDGE LEVEL: PRIVILEGES --
---------------------------------------------

create table acs_privileges (
	privilege	varchar2(100) 
			constraint acs_privileges_privilege_nn not null 
			constraint acs_privileges_privilege_pk
			primary key,
	pretty_name	varchar2(100),
	pretty_plural	varchar2(100)
);

create table acs_privilege_hierarchy (
	privilege	not null constraint acs_priv_hier_priv_fk
			references acs_privileges (privilege),
    child_privilege	not null constraint acs_priv_hier_child_priv_fk
			references acs_privileges (privilege),
	constraint acs_privilege_hierarchy_pk
	primary key (privilege, child_privilege)
);

-- create bitmap index acs_priv_hier_child_priv_idx on acs_privilege_hierarchy (child_privilege);
create index acs_priv_hier_child_priv_idx on acs_privilege_hierarchy (child_privilege);

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

create or replace package acs_privilege
as

  procedure create_privilege (
    privilege	in acs_privileges.privilege%TYPE,
    pretty_name   in acs_privileges.pretty_name%TYPE default null,
    pretty_plural in acs_privileges.pretty_plural%TYPE default null 
  );

  procedure drop_privilege (
    privilege	in acs_privileges.privilege%TYPE
  );

  procedure add_child (
    privilege		in acs_privileges.privilege%TYPE,
    child_privilege	in acs_privileges.privilege%TYPE
  );

  procedure remove_child (
    privilege		in acs_privileges.privilege%TYPE,
    child_privilege	in acs_privileges.privilege%TYPE
  );

end;
/
show errors

create or replace package body acs_privilege
as

  procedure create_privilege (
    privilege	  in acs_privileges.privilege%TYPE,
    pretty_name   in acs_privileges.pretty_name%TYPE default null,
    pretty_plural in acs_privileges.pretty_plural%TYPE default null 
  )
  is
  begin
    insert into acs_privileges
     (privilege, pretty_name, pretty_plural)
    values
     (create_privilege.privilege, 
      create_privilege.pretty_name, 
      create_privilege.pretty_plural);
  end;

  procedure drop_privilege (
    privilege	in acs_privileges.privilege%TYPE
  )
  is
  begin
    delete from acs_privileges
    where privilege = drop_privilege.privilege;
  end;

  procedure add_child (
    privilege		in acs_privileges.privilege%TYPE,
    child_privilege	in acs_privileges.privilege%TYPE
  )
  is
  begin
    insert into acs_privilege_hierarchy
     (privilege, child_privilege)
    values
     (add_child.privilege, add_child.child_privilege);
  end;

  procedure remove_child (
    privilege		in acs_privileges.privilege%TYPE,
    child_privilege	in acs_privileges.privilege%TYPE
  )
  is
  begin
    delete from acs_privilege_hierarchy
    where privilege = remove_child.privilege
    and child_privilege = remove_child.child_privilege;
  end;


end;
/
show errors


------------------------------------
-- OPERATIONAL LEVEL: PERMISSIONS --
------------------------------------

create table acs_permissions (
				constraint acs_permissions_object_id_fk
	object_id		integer 
				constraint acs_permissions_object_id_nn not null
				constraint acs_permissions_object_id_fk
				references acs_objects (object_id)
                                on delete cascade,
	grantee_id		integer 
				constraint acs_permissions_grantee_id_nn not null
				constraint acs_permissions_grantee_id_fk
				references parties (party_id)
                                on delete cascade,
	privilege		varchar(100) 
				constraint acs_permissions_privilege_nn not null 
                                constraint acs_permissions_privilege_fk
				references acs_privileges (privilege)
                                on delete cascade,
	constraint acs_permissions_pk
	primary key (object_id, grantee_id, privilege)
);

create index acs_permissions_grantee_idx on acs_permissions (grantee_id);
-- create bitmap index acs_permissions_privilege_idx on acs_permissions (privilege);
create index acs_permissions_privilege_idx on acs_permissions (privilege);
create index acs_permissions_object_id_idx on acs_permissions(object_id);

create or replace view acs_privilege_descendant_map
as select p1.privilege, p2.privilege as descendant
   from acs_privileges p1, acs_privileges p2
   where p2.privilege in (select child_privilege
			  from acs_privilege_hierarchy
			  start with privilege = p1.privilege
			  connect by prior child_privilege = privilege)
   or p2.privilege = p1.privilege;

create or replace view acs_permissions_all
as select op.object_id, p.grantee_id, p.privilege
   from acs_object_paths op, acs_permissions p
   where op.ancestor_id = p.object_id;

create or replace view acs_object_grantee_priv_map
as select a.object_id, a.grantee_id, m.descendant as privilege
   from acs_permissions_all a, acs_privilege_descendant_map m
   where a.privilege = m.privilege;

-- Fast new acs_object_party_privilege_map based on the denormalized
-- party_approved_member_map.  You may now use this map without fear.

create or replace view acs_object_party_privilege_map as
select c.object_id, pdm.descendant as privilege, pamm.member_id as party_id
from acs_object_context_index c, acs_permissions p, acs_privilege_descendant_map pdm,
  party_approved_member_map pamm
where c.ancestor_id = p.object_id
  and pdm.privilege = p.privilege
  and pamm.party_id = p.grantee_id;

--
-- Kept to avoid breaking existing code, should eventually go away.
-- Obsolete and deprecated view.
--
create or replace view all_object_party_privilege_map as
select * from acs_object_party_privilege_map;

create or replace package acs_permission
as

  procedure grant_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  );

  procedure revoke_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  );

  function permission_p (
    object_id	 acs_objects.object_id%TYPE,
    party_id	 parties.party_id%TYPE,
    privilege	 acs_privileges.privilege%TYPE
  ) return char;

end acs_permission;
/
show errors

create or replace package body acs_permission
as
  procedure grant_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  )
  as
  begin
    insert into acs_permissions
      (object_id, grantee_id, privilege)
    values
      (object_id, grantee_id, privilege);
  exception
    when dup_val_on_index then
      return;
  end grant_permission;
  --
  procedure revoke_permission (
    object_id	 acs_permissions.object_id%TYPE,
    grantee_id	 acs_permissions.grantee_id%TYPE,
    privilege	 acs_permissions.privilege%TYPE
  )
  as
  begin
    delete from acs_permissions
    where object_id = revoke_permission.object_id
    and grantee_id = revoke_permission.grantee_id
    and privilege = revoke_permission.privilege;
  end revoke_permission;

  function permission_p (
    object_id	 acs_objects.object_id%TYPE,
    party_id	 parties.party_id%TYPE,
    privilege	 acs_privileges.privilege%TYPE
  ) return char
  as
    exists_p char(1);
  begin

    select decode(count(*),0,'f','t') into exists_p
    from dual where exists
      (select 1
       from acs_permissions p, party_approved_member_map m,
         acs_object_context_index c, acs_privilege_descendant_map h
       where p.object_id = c.ancestor_id
         and h.descendant = permission_p.privilege
         and c.object_id = permission_p.object_id
         and m.member_id = permission_p.party_id
         and p.privilege = h.privilege
         and p.grantee_id = m.party_id);

    return exists_p;

  end permission_p;
  --
end acs_permission;
/
show errors
