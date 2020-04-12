--
-- create index since column is used as foreign key
--
create index notification_requests_u_id_idx on notification_requests(user_id);
create index notification_requests_o_id_idx on notification_requests(object_id);
