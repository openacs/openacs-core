--
-- acs-kernel/sql/acs-permissions-create.sql
--
-- The ACS core permission system. The knowledge level of system
-- allows you to define a hierarchical system of privileges.  The
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

CREATE TABLE acs_privileges (
    privilege	    varchar(100) not null constraint acs_privileges_privilege_pk
    		    primary key,
    pretty_name	    varchar(100),
    pretty_plural   varchar(100)
);

COMMENT ON TABLE acs_privileges is '
 Privileges share a global namespace. This is to avoid a
 situation where granting the foo privilege on one type of object can
 have an entirely different meaning than granting the foo privilege on
 another type of object.
';

CREATE TABLE acs_privilege_hierarchy (
    privilege	    varchar(100) not null 
                    constraint acs_priv_hier_priv_fk
    		    references acs_privileges (privilege),
    child_privilege varchar(100) not null 
                    constraint acs_priv_hier_child_priv_fk
    		    references acs_privileges (privilege),
    constraint acs_privilege_hierarchy_pk
    primary key (privilege, child_privilege)
);

comment on table acs_privilege_hierarchy is '
 The acs_privilege_hierarchy gives us an easy way to say: The foo
 privilege is a superset of the bar privilege.
';

CREATE INDEX acs_priv_hier_child_priv_idx ON acs_privilege_hierarchy (child_privilege);


CREATE OR REPLACE VIEW acs_privilege_descendant_map AS
WITH RECURSIVE privilege_desc(parent, child) AS (
   SELECT child_privilege as parent, child_privilege as child FROM acs_privilege_hierarchy
UNION ALL
   SELECT privilege as parent, privilege as child FROM
   (SELECT privilege FROM acs_privilege_hierarchy
    EXCEPT
    SELECT child_privilege FROM acs_privilege_hierarchy) identity
UNION ALL
   SELECT h.privilege as parent, pd.child
   FROM acs_privilege_hierarchy h, privilege_desc pd
   WHERE pd.parent = h.child_privilege
) SELECT privilege_desc.parent, privilege_desc.child FROM privilege_desc;

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

-- This query is used to find all of the ancestor privileges of 'cm_perm'. 
-- The equivalent recursive query for PostgreSQL would be:

--     with recursive privilege_path AS (
--       select privilege, child_privilege from acs_privilege_hierarchy
--       where child_privilege = 'cm_perm'
--     UNION
--       select  ph.privilege, ph.child_privilege from acs_privilege_hierarchy ph, privilege_path pp
--       where ph.child_privilege = pp.privilege
--     ) select * from privilege_path;
--
-- Also since acs_privilege_descendant_map is simply a path enumeration of
-- acs_privilege_hierarchy, we should be able to replace the above connect-by
-- with: 

-- select privilege 
-- from acs_privilege_descendant_map 
-- where descendant = 'cm_perm'

-- This would be better, since the same query could be used for both oracle
-- and PostgreSQL.


select define_function_args('acs_privilege__create_privilege','privilege,pretty_name;null,pretty_plural;null');

--
-- procedure acs_privilege__create_privilege/3
--
CREATE OR REPLACE FUNCTION acs_privilege__create_privilege(
   create_privilege__privilege varchar,
   create_privilege__pretty_name varchar,  -- default null
   create_privilege__pretty_plural varchar -- default null

) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_privileges
     (privilege, pretty_name, pretty_plural)
    values
     (create_privilege__privilege, 
      create_privilege__pretty_name, 
      create_privilege__pretty_plural);
      
    return 0; 
END;
$$ LANGUAGE plpgsql;



--
-- procedure acs_privilege__create_privilege/1
--
CREATE OR REPLACE FUNCTION acs_privilege__create_privilege(
   create_privilege__privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    return acs_privilege__create_privilege(create_privilege__privilege, null, null);
END;
$$ LANGUAGE plpgsql;




select define_function_args('acs_privilege__drop_privilege','privilege');

--
-- procedure acs_privilege__drop_privilege/1
--
CREATE OR REPLACE FUNCTION acs_privilege__drop_privilege(
   drop_privilege__privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from acs_privileges
    where privilege = drop_privilege__privilege;

    return 0; 
END;
$$ LANGUAGE plpgsql;



select define_function_args('acs_privilege__add_child','privilege,child_privilege');

--
-- procedure acs_privilege__add_child/2
--
CREATE OR REPLACE FUNCTION acs_privilege__add_child(
   add_child__privilege varchar,
   add_child__child_privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_privilege_hierarchy
     (privilege, child_privilege)
    values
     (add_child__privilege, add_child__child_privilege);

    return 0; 
END;
$$ LANGUAGE plpgsql;



select define_function_args('acs_privilege__remove_child','privilege,child_privilege');

--
-- procedure acs_privilege__remove_child/2
--
CREATE OR REPLACE FUNCTION acs_privilege__remove_child(
   remove_child__privilege varchar,
   remove_child__child_privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from acs_privilege_hierarchy
    where privilege = remove_child__privilege
    and child_privilege = remove_child__child_privilege;

    return 0; 
END;
$$ LANGUAGE plpgsql;


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

--
-- The following view was replaced by acs_permission.permissions_all()
-- in Jul 6, 2016
--
-- create view acs_permissions_all
-- as select op.object_id, p.grantee_id, p.privilege
--   from acs_object_paths op, acs_permissions p
--   where op.ancestor_id = p.object_id;

-- create view acs_object_grantee_priv_map
-- as select a.object_id, a.grantee_id, m.descendant as privilege
--    from acs_permissions_all a, acs_privilege_descendant_map m
--    where a.privilege = m.privilege;

--
-- Obsolete and deprecated view.
--
-- create view all_object_party_privilege_map as
-- select * from acs_object_party_privilege_map;


-- This table acts as a mutex for inserts/deletes from acs_permissions.
-- This is used since postgresql's exception handing mechanism is non-
-- existent.  A dup insert on acs_permissions will roll-back the 
-- transaction and give an error, which is not what we want.  Using a 
-- separate table for locking allows us exclusive access for 
-- inserts/deletes, but does not block readers.  That way we don't 
-- slow down permissions-checking which is known to have performance 
-- problems already.

-- (OpenACS - DanW)

create table acs_permissions_lock (
       lck  integer
);

CREATE OR REPLACE FUNCTION acs_permissions_lock_tr () RETURNS trigger AS $$
BEGIN
        raise EXCEPTION 'FOR LOCKING ONLY, NO DML STATEMENTS ALLOWED';
        return null;
END;
$$ LANGUAGE plpgsql;

create trigger acs_permissions_lock_tr 
before insert or update or delete on acs_permissions_lock
for each row execute procedure acs_permissions_lock_tr();




--
-- Create an SQL schema to allow the same dot notation as in
-- Oracle. The advantage of this notation is that the function can be
-- called identically for PostgreSQL and Oracle, so much duplicated
-- code can be removed.
--
-- Actually, at least all permission functions should be defined this
-- way, keeping the old "__" notation around for backwards
-- compatibility for custom packages.
--
-- TODO: handling of schema names in define_function_args
--
CREATE SCHEMA acs_permission;


--
-- procedure acs_permission.permission_p/3
--
CREATE OR REPLACE FUNCTION acs_permission.permission_p(
       p_object_id integer,
       p_party_id  integer,
       p_privilege varchar
) RETURNS boolean AS $$
DECLARE
    v_security_context_root   integer;
BEGIN
    v_security_context_root := acs__magic_object_id('security_context_root');

    RETURN EXISTS (WITH RECURSIVE
        object_context(object_id, context_id) AS (

            SELECT p_object_id, p_object_id 
            FROM acs_objects 
            WHERE object_id = p_object_id

            UNION ALL

            SELECT ao.object_id,
                   CASE WHEN (ao.security_inherit_p = 'f' OR ao.context_id IS NULL) 
                   THEN v_security_context_root ELSE ao.context_id END
            FROM object_context oc, acs_objects ao
            WHERE ao.object_id = oc.context_id
            AND ao.object_id != v_security_context_root

        ), privilege_ancestors(privilege, child_privilege) AS (

            SELECT p_privilege, p_privilege 
   
            UNION ALL

            SELECT aph.privilege, aph.child_privilege
            FROM privilege_ancestors pa
            JOIN acs_privilege_hierarchy aph ON aph.child_privilege = pa.privilege

        )
        SELECT 1 FROM acs_permissions p
        JOIN  party_approved_member_map pap ON pap.party_id  =  p.grantee_id
        JOIN  privilege_ancestors pa        ON  pa.privilege =  p.privilege
        JOIN  object_context oc             ON  p.object_id  =  oc.context_id      
        WHERE pap.member_id = p_party_id
    );
END;
$$ LANGUAGE plpgsql stable;


--
-- procedure acs_permission.permission_p_recursive_array/3
--
--      Return for a an array of objects a set of objects where the
--      specified user has the specified rights.

CREATE OR REPLACE FUNCTION  acs_permission.permission_p_recursive_array(
       p_objects   integer[],
       p_party_id  integer, 
       p_privilege varchar
) RETURNS table (object_id integer, orig_object_id integer) AS $$
DECLARE
    v_security_context_root  integer;
BEGIN
    v_security_context_root := acs__magic_object_id('security_context_root');

    RETURN QUERY WITH RECURSIVE
       object_context(obj_id, context_id, orig_obj_id) AS (

           SELECT unnest(p_objects), unnest(p_objects), unnest(p_objects)
           UNION ALL
           SELECT
              ao.object_id,
              CASE WHEN (ao.security_inherit_p = 'f' OR ao.context_id IS NULL) 
              THEN v_security_context_root ELSE ao.context_id END, 
              oc.orig_obj_id
           FROM  object_context oc, acs_objects ao
           WHERE ao.object_id = oc.context_id
           AND   ao.object_id != v_security_context_root

       ), privilege_ancestors(privilege, child_privilege) AS (

           SELECT p_privilege, p_privilege
           UNION ALL
           SELECT aph.privilege, aph.child_privilege
           FROM   privilege_ancestors pa
           JOIN   acs_privilege_hierarchy aph ON aph.child_privilege = pa.privilege

       )
       SELECT p.object_id, oc.orig_obj_id
       FROM  acs_permissions p
       JOIN  party_approved_member_map pap ON pap.party_id =  p.grantee_id
       JOIN  privilege_ancestors pa        ON pa.privilege =  p.privilege
       JOIN  object_context oc             ON p.object_id  =  oc.context_id
       WHERE pap.member_id = p_party_id;
END; 
$$ LANGUAGE plpgsql stable;


--
-- procedure acs_permission.parties_with_object_privilege/2
--
--     Find all party_ids which have a given privilege on a given
--     object. The function is equivalent to an SQL query on the
--     deprecated acs_object_party_privilege_map such as e.g.:
--
--   select p.party_id
--   from acs_object_party_privilege_map p
--   where p.object_id = :object_id
--   and p.privilege = 'admin';
--

CREATE OR REPLACE FUNCTION acs_permission.parties_with_object_privilege(
       p_object_id integer, 
       p_privilege varchar
) RETURNS table (party_id integer) AS $$
DECLARE
    v_security_context_root  integer;
BEGIN
    v_security_context_root := acs__magic_object_id('security_context_root');

    RETURN QUERY
    WITH RECURSIVE
       object_context(obj_id, context_id, orig_obj_id) AS (
           SELECT p_object_id, p_object_id, p_object_id
           UNION ALL
           SELECT
              ao.object_id,
              CASE WHEN (ao.security_inherit_p = 'f' OR ao.context_id IS NULL) 
              THEN v_security_context_root ELSE ao.context_id END, 
              oc.orig_obj_id
           FROM  object_context oc, acs_objects ao
           WHERE ao.object_id = oc.context_id
           AND   ao.object_id != v_security_context_root
           
       ), privilege_ancestors(privilege, child_privilege) AS (
           SELECT p_privilege, p_privilege
           UNION ALL
           SELECT aph.privilege, aph.child_privilege
           FROM privilege_ancestors pa
           JOIN acs_privilege_hierarchy aph ON aph.child_privilege = pa.privilege
       )
       SELECT pap.member_id
       FROM  acs_permissions p
       JOIN  party_approved_member_map pap ON pap.party_id =  p.grantee_id
       JOIN  privilege_ancestors pa        ON pa.privilege =  p.privilege
       JOIN  object_context oc             ON p.object_id  =  oc.context_id;
END; 
$$ LANGUAGE plpgsql stable;

--
-- procedure acs_permission.permissions_all/1
--
--    Return the permissions for an object from the object context
--    hierarchy. The call
--
--         select * from acs_permission.permissions_all(:object_id)
--
--    is compatible with the old/Oracle call
--
--         select * from acs_permission_all where where object_id = :object_id
--
--
CREATE OR REPLACE FUNCTION acs_permission.permissions_all(
       p_object_id integer
) RETURNS table (object_id integer, grantee_id integer, privilege varchar) AS $$
DECLARE
    v_security_context_root  integer;
BEGIN
    v_security_context_root := acs__magic_object_id('security_context_root');

    RETURN QUERY
    WITH RECURSIVE object_context(obj_id, context_id, orig_obj_id) AS (
           SELECT p_object_id, p_object_id, p_object_id
           UNION ALL
           SELECT
              ao.object_id,
              CASE WHEN (ao.security_inherit_p = 'f' OR ao.context_id IS NULL) 
              THEN v_security_context_root ELSE ao.context_id END, 
              oc.orig_obj_id
           FROM  object_context oc, acs_objects ao
           WHERE ao.object_id = oc.context_id
           AND   ao.object_id != v_security_context_root
    )
    select p_object_id, p.grantee_id, p.privilege
    from object_context oc, acs_permissions p where p.object_id = oc.context_id;
END;
$$ LANGUAGE plpgsql stable;

--
-- procedure acs_permission.grant_permission/3
--
CREATE OR REPLACE FUNCTION acs_permission.grant_permission(
   p_object_id integer,
   p_grantee_id integer,
   p_privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_permissions
      (object_id, grantee_id, privilege)
    values
      (p_object_id, p_grantee_id, p_privilege);
    
    return 0;
EXCEPTION 
    when unique_violation then
      return 0;
END;
$$ LANGUAGE plpgsql;


--
-- procedure acs_permission.revoke_permission/3
--
CREATE OR REPLACE FUNCTION acs_permission.revoke_permission(
   p_object_id integer,
   p_grantee_id integer,
   p_privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from acs_permissions
    where object_id = p_object_id
    and grantee_id = p_grantee_id
    and privilege = p_privilege;

    return 0; 
END;
$$ LANGUAGE plpgsql;




---
--- Functions for backwards compatibility
---
select define_function_args('acs_permission__permission_p','object_id,party_id,privilege');
DROP FUNCTION IF EXISTS acs_permission__permission_p(integer, integer, varchar);
CREATE OR REPLACE FUNCTION acs_permission__permission_p(
       p_object_id integer,
       p_party_id  integer,
       p_privilege varchar
) RETURNS boolean AS $$
BEGIN
  RETURN acs_permission.permission_p(p_object_id, p_party_id, p_privilege);
END; 
$$ LANGUAGE plpgsql stable;


select define_function_args('acs_permission__permission_p_recursive_array','objects,party_id,privilege');
DROP FUNCTION IF EXISTS acs_permission__permission_p_recursive_array(integer[], integer, varchar);
CREATE OR REPLACE FUNCTION acs_permission__permission_p_recursive_array(
       p_objects   integer[],
       p_party_id  integer, 
       p_privilege varchar
) RETURNS table (object_id integer, orig_object_id integer) AS $$
  SELECT acs_permission.permission_p_recursive_array($1, $2, $3);
$$ LANGUAGE sql stable;


select define_function_args('acs_permission__grant_permission','object_id,grantee_id,privilege');
DROP FUNCTION IF EXISTS acs_permission__grant_permission(integer, integer, varchar);
CREATE OR REPLACE FUNCTION acs_permission__grant_permission(
   p_object_id integer,
   p_grantee_id integer,
   p_privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
  RETURN acs_permission.grant_permission(p_object_id, p_grantee_id, p_privilege);
END; 
$$ LANGUAGE plpgsql;


select define_function_args('acs_permission__revoke_permission','object_id,grantee_id,privilege');
DROP FUNCTION IF EXISTS acs_permission__revoke_permission(integer, integer, varchar);
CREATE OR REPLACE FUNCTION acs_permission__revoke_permission(
   p_object_id integer,
   p_grantee_id integer,
   p_privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    RETURN acs_permission.revoke_permission(p_object_id, p_grantee_id, p_privilege);
END;
$$ LANGUAGE plpgsql;



--
-- Local variables:
--   mode: sql
--   indent-tabs-mode: nil
-- End:
