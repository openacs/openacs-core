-- Indexes for foreign key constraints.

-- the comment after is the referenced table.  

create index notifications_type_id_idx ON notifications(type_id); -- notification_types.type_id
create index notifications_response_id_idx ON notifications(response_id); -- acs_objects.object_id
create index notifications_object_id_idx ON notifications(object_id); -- acs_objects.object_id

create index notif_requests_typ_delmeth_ix ON notification_requests(type_id, delivery_method_id); -- notification_types_del_methods.type_id delivery_method_id
create index notif_requests_typ_intvl_idx ON notification_requests(type_id, interval_id); -- notification_types_intervals.type_id interval_id
create index notif_requests_object_id_idx ON notification_requests(object_id); -- acs_objects.object_id
create index notif_requests_user_id_idx ON notification_requests(user_id); -- users.user_id

create index notification_user_map_user_idx ON notification_user_map(user_id); -- users.user_id

-- We are not creating these even though they reference fks since the
-- table and the parent tables are static.  Might want to revist this though.

-- create index notification_delivery_methods_sc_impl_id_idx ON notification_delivery_methods(sc_impl_id); acs_sc_impls.impl_id
-- create index notification_types_sc_impl_id_idx ON notification_types(sc_impl_id); acs_sc_impls.impl_id
-- create index notification_types_del_methods_delivery_method_id_idx ON notification_types_del_methods(delivery_method_id); notification_delivery_methods.delivery_method_id
-- create index notification_types_intervals_interval_id_idx ON notification_types_intervals(interval_id); notification_intervals.interval_id

