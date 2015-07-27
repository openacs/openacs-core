
-- Antonio Pisano 2015-07-29: removed exclusive lock
-- for this procedures as it is sufficient to handle
-- exception/ignore the case. Locking esclusively
-- could cause deadlock in certain situations.

--
-- procedure acs_permission__grant_permission/3
--
CREATE OR REPLACE FUNCTION acs_permission__grant_permission(
   grant_permission__object_id integer,
   grant_permission__grantee_id integer,
   grant_permission__privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_permissions
      (object_id, grantee_id, privilege)
      values
      (grant_permission__object_id, grant_permission__grantee_id, 
      grant_permission__privilege);
    
    return 0;
EXCEPTION 
    when unique_violation then
      return 0;
END;
$$ LANGUAGE plpgsql;


--
-- procedure acs_permission__revoke_permission/3
--
CREATE OR REPLACE FUNCTION acs_permission__revoke_permission(
   revoke_permission__object_id integer,
   revoke_permission__grantee_id integer,
   revoke_permission__privilege varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from acs_permissions
    where object_id = revoke_permission__object_id
    and grantee_id = revoke_permission__grantee_id
    and privilege = revoke_permission__privilege;

    return 0; 
END;
$$ LANGUAGE plpgsql;
