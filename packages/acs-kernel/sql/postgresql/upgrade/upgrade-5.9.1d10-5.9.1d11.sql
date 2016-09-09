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

DO $$
DECLARE
	v_found boolean;
BEGIN
	SELECT exists(select schema_name FROM information_schema.schemata WHERE schema_name = 'acs_permission')
	INTO v_found;

	if v_found IS FALSE then
	
	   CREATE SCHEMA acs_permission;

	end if;
END$$;

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

    RETURN QUERY WITH RECURSIVE
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


