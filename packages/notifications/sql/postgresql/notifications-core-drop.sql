
--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright OpenForce, 2002.
--
-- GNU GPL v2
--

-- drop script

drop table notification_user_map;

drop table notifications;

drop table notification_requests;

drop table notification_types_del_methods;

drop table notification_types_intervals;

drop table notification_types;

drop table notification_intervals;

drop table notification_delivery_methods;




--
-- Object Types
--

begin

        select acs_object_type__drop_type (
            'notification_interval', 'f'
        );

        select acs_object_type__drop_type (
            'notification_delivery_method', 'f'
        );

        select acs_object_type__drop_type (
            'notification_type', 'f'
        );

        select acs_object_type__drop_type (
            'notification_request', 'f'
        );

        select acs_object_type__drop_type (
            'notification', 'f'
        );
end;
