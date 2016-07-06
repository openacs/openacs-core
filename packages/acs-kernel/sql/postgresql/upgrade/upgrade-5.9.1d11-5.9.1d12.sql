--
-- procedure acs_permission.permissions_all/1
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

