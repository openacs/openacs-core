--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--

drop table notification_user_map;
drop table notifications;
drop table notification_requests;
drop table notification_types_del_methods;
drop table notification_types_intervals;
drop table notification_types;
drop table notification_intervals;
drop table notification_delivery_methods;

create function inline_0 ()
returns integer as '
begin

    perform acs_object_type__drop_type(
        ''notification_interval'', ''f''
    );

    perform acs_object_type__drop_type(
        ''notification_delivery_method'', ''f''
    );

    perform acs_object_type__drop_type(
        ''notification_type'', ''f''
    );

    perform acs_object_type__drop_type(
        ''notification_request'', ''f''
    );

    perform acs_object_type__drop_type(
        ''notification'', ''f''
    );

    return null;

end;' language 'plpgsql';

select inline_0();
drop function inline_0();
