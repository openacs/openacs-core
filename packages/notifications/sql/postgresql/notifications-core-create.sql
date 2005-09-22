--
-- The Notifications Package
--
-- @author Ben Adida (ben@openforce.net)
-- @version $Id$
--
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--

-- intervals should really be service contracts so other intervals can be
-- taken into account. For now we're going to make them just intervals
create table notification_intervals (
    interval_id                     integer
                                    constraint notif_interv_id_fk
                                    references acs_objects (object_id)
                                    constraint notif_interv_id_pk
                                    primary key,
    name                            varchar(200)
                                    constraint notif_interv_name_nn
                                    not null
                                    constraint notif_interv_name_un
                                    unique,
    -- how to schedule this
    n_seconds                       integer
                                    constraint notif_interv_n_seconds_nn
                                    not null
);

-- delivery methods should be service contracts, too.
create table notification_delivery_methods (
    delivery_method_id              integer
                                    constraint notif_deliv_meth_fk
                                    references acs_objects (object_id)
                                    constraint notif_deliv_meth_pk
                                    primary key,
    sc_impl_id                      integer not null
                                    constraint notif_deliv_meth_impl_id_fk
                                    references acs_sc_impls(impl_id),
    short_name                      varchar(100)
                                    constraint notif_deliv_short_name_nn
                                    not null
                                    constraint notif_deliv_short_name_un
                                    unique,
    pretty_name                     varchar(200)
                                    not null
);

create table notification_types (
    type_id                         integer
                                    constraint notif_type_type_id_fk
                                    references acs_objects (object_id)
                                    constraint notif_type_type_id_pk
                                    primary key,
    sc_impl_id                      integer not null
                                    constraint notif_deliv_meth_impl_id_fk
                                    references acs_sc_impls(impl_id),
    short_name                      varchar(100)
                                    constraint notif_type_short_name_nn
                                    not null
                                    constraint notif_type_short_name_un
                                    unique,
    pretty_name                     varchar(200)
                                    constraint notif_type_pretty_name_nn
                                    not null,
    description                     varchar(2000)
);

-- what's allowed for a given notification type?
create table notification_types_intervals (
    type_id                         integer
                                    constraint notif_type_int_type_id_fk
                                    references notification_types (type_id)
                                    on delete cascade,
    interval_id                     integer
                                    constraint notif_type_int_int_id_fk
                                    references notification_intervals (interval_id)
                                    on delete cascade,
    constraint notif_type_int_pk
    primary key (type_id, interval_id)
);

-- allowed delivery methods
create table notification_types_del_methods (
    type_id                         integer
                                    constraint notif_type_del_type_id_fk
                                    references notification_types (type_id)
                                    on delete cascade,
    delivery_method_id              integer
                                    constraint notif_type_del_meth_id_fk
                                    references notification_delivery_methods (delivery_method_id)
                                    on delete cascade,
    constraint notif_type_deliv_pk
    primary key (type_id, delivery_method_id)
);

-- Requests for Notifications
create table notification_requests (
    request_id                      integer
                                    constraint notif_request_id_fk
                                    references acs_objects (object_id)
                                    on delete cascade
                                    constraint notif_request_id_pk
                                    primary key,
    type_id                         integer
                                    constraint notif_request_type_id_fk
                                    references notification_types (type_id)
                                    on delete cascade,
    user_id                         integer
                                    constraint notif_request_user_id_fk
                                    references users (user_id)
                                    on delete cascade,
    -- The object this request pertains to
    object_id                       integer
                                    constraint notif_request_object_id_fk
                                    references acs_objects (object_id)
                                    on delete cascade,
    -- the interval must be allowed for this type
    interval_id                     integer
                                    constraint notif_request_interv_id_nn
                                    not null,
    constraint notif_request_interv_fk
    foreign key (type_id, interval_id)
    references notification_types_intervals (type_id, interval_id),
    -- the delivery method must be allowed for this type
    delivery_method_id              integer
                                    constraint notif_request_delivery_meth_nn
                                    not null,
    constraint notif_request_deliv_fk
    foreign key (type_id, delivery_method_id)
    references notification_types_del_methods (type_id, delivery_method_id),
    -- the format of the notification should be...
    format                          varchar(100)
                                    default 'text'
                                    constraint notif_request_format_ch
                                    check (format in ('text', 'html')),
    dynamic_p                       bool default 'f'
);

create index notification_requests_t_o_idx on notification_requests(type_id, object_id);

-- preferences
--
-- for preferences that apply to each request, we're using the
-- notification_requests table. For preferences that are notification-wide,
-- we use user-preferences

-- the actual stuff that has to go out
create table notifications (
    notification_id                 integer
                                    constraint notif_notif_id_fk
                                    references acs_objects (object_id)
                                    on delete cascade
                                    constraint notif_notif_id_pk
                                    primary key,
    type_id                         integer
                                    constraint notif_type_id_fk
                                    references notification_types(type_id),
    -- the object this notification pertains to
    object_id                       integer
                                    constraint notif_object_id_fk
                                    references acs_objects(object_id)
                                    on delete cascade,
    notif_date                      timestamptz
                                    constraint notif_notif_date_nn
                                    not null,
    -- this is to allow responses to notifications
    response_id                     integer
                                    constraint notif_reponse_id_fk
                                    references acs_objects (object_id)
                                    on delete cascade,
    -- this is the user that caused the notification to go out
    notif_user                      integer
                                    constraint notif_user_id_fk
                                    references users(user_id),
    notif_subject                   varchar(1000),
    notif_text                      text,
    notif_html                      text
);

-- RI indexes 
create index notifications_type_id_idx ON notifications(type_id);
create index notifications_response_id_idx ON notifications(response_id);
create index notifications_object_id_idx ON notifications(object_id);

-- who has received this notification?
create table notification_user_map (
    notification_id                 integer
                                    constraint notif_user_map_notif_id_fk
                                    references notifications (notification_id)
                                    on delete cascade,
    user_id                         integer
                                    constraint notif_user_map_user_id_fk
                                    references users(user_id)
                                    on delete cascade,
    constraint notif_user_map_pk
    primary key (notification_id, user_id),
    sent_date                       timestamptz
);

-- RI Indexes 
create index notification_user_map_user_idx ON notification_user_map(user_id);


--
-- Object Types
--
select acs_object_type__create_type(
    'notification_interval',
    '#notifications.lt_Notification_Interval#',
    '#notifications.lt_Notification_Interval_1#',
    'acs_object',
    'notification_intervals',
    'interval_id',
    'notification_interval',
    'f',
    null,
    null
);

select acs_object_type__create_type(
    'notification_delivery_method',
    '#notifications.lt_Notification_Delivery#',
    '#notifications.lt_Notification_Delivery_1#',
    'acs_object',
    'notification_delivery_methods',
    'delivery_method_id',
    'notification_delivery_method',
    'f',
    null,
    null
);

select acs_object_type__create_type(
    'notification_type',
    '#notifications.Notification_Type#',
    '#notifications.Notification_Types#',
    'acs_object',
    'notification_types',
    'type_id',
    'notification_type',
    'f',
    null,
    null
);

select acs_object_type__create_type(
    'notification_request',
    '#notifications.Notification_Request#',
    '#notifications.lt_Notification_Requests#',
    'acs_object',
    'notification_requests',
    'request_id',
    'notification_request',
    'f',
    null,
    null
);

select acs_object_type__create_type(
    'notification',
    '#notifications.Notification#',
    '#notifications.Notifications#',
    'acs_object',
    'notifications',
    'notification_id',
    'notification',
    'f',
    null,
    null
);

