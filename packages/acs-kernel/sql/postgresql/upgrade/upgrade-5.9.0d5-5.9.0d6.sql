
-- Antonio Pisano 2015-07-29: removed exclusive lock
-- for this procedures as it is sufficient to handle
-- exception/ignore the case. Locking esclusively
-- could cause deadlock in certain situations.

--
-- procedure acs_permission__grant_permission/3
--
DROP FUNCTION acs_permission__grant_permission(integer, integer, varchar);

CREATE OR REPLACE FUNCTION acs_permission__grant_permission(
   p_object_id integer,
   p_grantee_id integer,
   p_privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_permissions
      (object_id, grantee_id, privilege)
      values
      (p_object_id, p_grantee_id, 
      p_privilege);
    
    return 0;
EXCEPTION 
    when unique_violation then
      return 0;
END;
$$ LANGUAGE plpgsql;


--
-- procedure acs_permission__revoke_permission/3
--
DROP FUNCTION acs_permission__revoke_permission(integer, integer, varchar);

CREATE OR REPLACE FUNCTION acs_permission__revoke_permission(
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
