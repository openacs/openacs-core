--
-- create index since column is used as foreign key
--
create index if not exists notification_requests_user_id_idx on notification_requests(user_id);
create index if not exists notification_requests_object_id_idx on notification_requests(object_id);
