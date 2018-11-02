--
-- Delete from duplicated notification request entries, which are
-- entries having duplicate values in the columns (type_id, user_id,
-- object_id).
--
WITH dups AS (                                                                                                                     
   select n.* from notification_requests n, (
      select type_id, object_id, user_id, count(*) from notification_requests group by 1, 2, 3 HAVING count(*) > 1
      ) d where n.type_id = d.type_id and n.object_id = d.object_id and n.user_id = d.user_id
)
DELETE FROM notification_requests a USING dups b
WHERE a.request_id < b.request_id
and a.type_id = b.type_id and a.object_id = b.object_id and a.user_id = b.user_id;

--
-- Allow to run this script multiple times.
--
ALTER TABLE notification_requests DROP CONSTRAINT IF EXISTS notification_requests_un;

--
-- Add the real constraint.
--
ALTER TABLE notification_requests
ADD CONSTRAINT notification_requests_un
UNIQUE (type_id, user_id, object_id);
