--
-- Slightly faster (around 10%) versions for the base permission query functions.
-- In the new versions the lookup of acs__magic_object_id was moved out of the loop.
--

--
-- procedure acs_permission__permission_p/3
--
DROP FUNCTION IF EXISTS acs_permission__permission_p(integer, integer, varchar);
CREATE OR REPLACE FUNCTION acs_permission__permission_p(
       permission_p__object_id integer,
       permission_p__party_id  integer,
       permission_p__privilege varchar
) RETURNS boolean AS $$
DECLARE
    v_security_context_root   integer;
BEGIN
    v_security_context_root := acs__magic_object_id('security_context_root');

    RETURN EXISTS (WITH RECURSIVE
        object_context(object_id, context_id) AS (

            SELECT permission_p__object_id, permission_p__object_id 
            FROM acs_objects 
            WHERE object_id = permission_p__object_id

            UNION ALL

            SELECT ao.object_id,
                   CASE WHEN (ao.security_inherit_p = 'f' OR ao.context_id IS NULL) 
                   THEN v_security_context_root ELSE ao.context_id END
            FROM object_context oc, acs_objects ao
            WHERE ao.object_id = oc.context_id
            AND ao.object_id != v_security_context_root

        ), privilege_ancestors(privilege, child_privilege) AS (

            SELECT permission_p__privilege, permission_p__privilege 
   
            UNION ALL

            SELECT aph.privilege, aph.child_privilege
            FROM privilege_ancestors pa
            JOIN acs_privilege_hierarchy aph ON aph.child_privilege = pa.privilege

        )
        SELECT 1 FROM acs_permissions p
        JOIN  party_approved_member_map pap ON pap.party_id  =  p.grantee_id
        JOIN  privilege_ancestors pa        ON  pa.privilege =  p.privilege
        JOIN  object_context oc             ON  p.object_id  =  oc.context_id      
        WHERE pap.member_id = permission_p__party_id
    );
END;
$$ LANGUAGE plpgsql stable;


-- for tsearch
--
-- procedure acs_permission__permission_p_recursive_array/3
--
DROP FUNCTION IF EXISTS acs_permission__permission_p_recursive_array(integer[], integer, varchar);
CREATE OR REPLACE FUNCTION  acs_permission__permission_p_recursive_array(
       permission_p__objects   integer[],
       permission_p__party_id  integer, 
       permission_p__privilege varchar
) RETURNS table (object_id integer, orig_object_id integer) AS $$
DECLARE
    v_security_context_root  integer;
BEGIN
    v_security_context_root := acs__magic_object_id('security_context_root');

    RETURN QUERY WITH RECURSIVE
       object_context(obj_id, context_id, orig_obj_id) AS (

    	   SELECT unnest(permission_p__objects), unnest(permission_p__objects), unnest(permission_p__objects)

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

           SELECT permission_p__privilege, permission_p__privilege

           UNION ALL

           SELECT aph.privilege, aph.child_privilege
           FROM privilege_ancestors pa
           JOIN acs_privilege_hierarchy aph ON aph.child_privilege = pa.privilege

       )
       SELECT p.object_id, oc.orig_obj_id
       FROM  acs_permissions p
       JOIN  party_approved_member_map pap ON pap.party_id =  p.grantee_id
       JOIN  privilege_ancestors pa        ON pa.privilege =  p.privilege
       JOIN  object_context oc             ON p.object_id  =  oc.context_id
       WHERE pap.member_id = permission_p__party_id;
END; 
$$ LANGUAGE plpgsql stable;
