--
-- The Notifications Package
--
-- @author Ben Adida (ben@openforce.net)
-- @version $Id$
--
-- Copyright OpenForce, 2002.
--
-- GNU GPL v2
--

-- intervals should really be service contracts so other intervals can be
-- taken into account. For now we're going to make them just intervals
create table notification_intervals (
    interval_id                     constraint notif_interv_id_fk
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
    delivery_method_id              constraint notif_deliv_meth_fk
                                    references acs_objects (object_id)
                                    constraint notif_deliv_meth_pk
                                    primary key,
    short_name                      varchar(100)
                                    constraint notif_deliv_short_name_nn
                                    not null
                                    constraint notif_deliv_short_name_un
                                    unique,
    pretty_name                     varchar(200)
                                    not null
);

create table notification_types (
        type_id                     constraint notif_type_type_id_fk
                                    references acs_objects (object_id)
                                    constraint notif_type_type_id_pk
                                    primary key,
       short_name                   varchar(100)
                                    constraint notif_type_short_name_nn
                                    not null
                                    constraint notif_type_short_name_un
                                    unique,
       pretty_name                  varchar(200)
                                    constraint notif_type_pretty_name_nn
                                    not null,
       description                  varchar(2000)
);

-- what's allowed for a given notification type?
create table notification_types_intervals (
    type_id                         constraint notif_type_int_type_id_fk
                                    references notification_types (type_id),
    interval_id                     constraint notif_type_int_int_id_fk
                                    references notification_intervals (interval_id),
    constraint notif_type_int_pk
    primary key (type_id, interval_id)
);

-- allowed delivery methods
create table notification_types_del_methods (
    type_id                         constraint notif_type_del_type_id_fk
                                    references notification_types (type_id),
    delivery_method_id              constraint notif_type_del_meth_id_fk
                                    references notification_delivery_methods (delivery_method_id),
    constraint notif_type_deliv_pk
    primary key (type_id, delivery_method_id)
);

-- Requests for Notifications
create table notification_requests (
    request_id                      constraint notif_request_id_fk
                                    references acs_objects (object_id)
                                    constraint notif_request_id_pk
                                    primary key,
    type_id                         constraint notif_request_type_id_fk
                                    references notification_types (type_id),
    user_id                         constraint notif_request_user_id_fk
                                    references users (user_id)
                                    on delete cascade,
    -- The object this request pertains to
    object_id                       constraint notif_request_object_id_fk
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
                                    check (format in ('text', 'html'))
);

-- preferences
--
-- for preferences that apply to each request, we're using the
-- notification_requests table. For preferences that are notification-wide,
-- we use user-preferences

-- the actual stuff that has to go out
create table notifications (
    notification_id                 constraint notif_notif_id_fk
                                    references acs_objects (object_id)
                                    constraint notif_notif_id_pk
                                    primary key,
    type_id                         constraint notif_type_id_fk
                                    references notification_types(type_id),
    -- the object this notification pertains to
    object_id                       constraint notif_object_id_fk
                                    references acs_objects(object_id)
                                    on delete cascade,
    notif_date                      timestamp
                                    constraint notif_notif_date_nn
                                    not null,
    -- this is to allow responses to notifications
    response_id                     constraint notif_reponse_id_fk
                                    references acs_objects (object_id),
    notif_subject                   varchar(100),
    notif_text                      text,
    notif_html                      text
);

-- who has received this notification?
create table notification_user_map (
    notification_id                 constraint notif_user_map_notif_id_fk
                                    references notifications (notification_id)
                                    on delete cascade,
    user_id                         constraint notif_user_map_user_id_fk
                                    references users(user_id)
                                    on delete cascade,
    constraint notif_user_map_pk
    primary key (notification_id, user_id),
    sent_date                       timestamp
);

--
-- Object Types
--
begin

    select acs_object_type__create_type(
        'acs_object',
        'notification_interval',
        'Notification Interval',
        'Notification Intervals',
        'notification_intervals',
        'interval_id',
        'notification_interval',
        null,
        null
    );

    select acs_object_type__create_type(
        'acs_object',
        'notification_delivery_method',
        'Notification Delivery Method',
        'Notification Delivery Methods',
        'notification_delivery_methods',
        'delivery_method_id',
        'notification_delivery_method',
        null,
        null
    );

    select acs_object_type__create_type(
        'acs_object',
        'notification_type',
        'Notification Type',
        'Notification Types',
        'notification_types',
        'type_id',
        'notification_type',
        null,
        null
    );

    select acs_object_type__create_type(
        'acs_object',
        'notification_request',
        'Notification Request',
        'Notification Requests',
        'notification_requests',
        'request_id',
        'notification_request',
        null,
        null
    );

    select acs_object_type__create_type(
        'acs_object',
        'notification',
        'Notification',
        'Notifications',
        'notifications',
        'notification_id',
        'notification',
        null,
        null
    );

end;
