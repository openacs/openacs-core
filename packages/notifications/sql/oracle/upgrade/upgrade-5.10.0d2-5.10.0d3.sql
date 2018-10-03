
ALTER TABLE notification_requests
ADD CONSTRAINT notification_requests_un
UNIQUE (type_id, user_id, object_id);
