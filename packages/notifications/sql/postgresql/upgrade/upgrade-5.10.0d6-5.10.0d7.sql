
-- Delete leftover acs_objects referring to notification requests that
-- do not exist anymore
select acs_object__delete(o.object_id)
from acs_objects o
     left join notification_requests r on r.request_id = o.object_id
where object_type = 'notification_request'
  and r.request_id is null;
