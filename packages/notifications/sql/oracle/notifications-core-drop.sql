
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

declare
begin

        acs_object_type.drop_type (
            object_type => 'notification_interval'
        );

        acs_object_type.drop_type (
            object_type => 'notification_delivery_method'
        );

        acs_object_type.drop_type (
            object_type => 'notification_type'
        );

        acs_object_type.drop_type (
            object_type => 'notification_request'
        );

        acs_object_type.drop_type (
            object_type => 'notification'
        );
end;
/
show errors
