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

-- Remove Objects
declare
    v_object_id     integer;
begin

    select max(object_id) 
    into   v_object_id 
    from   acs_objects 
    where  object_type = 'notification_interval' 
    or     object_type = 'notification_delivery_method' 
    or     object_type = 'notification_type' 
    or     object_type='notification_request' 
    or     object_type='notification';

    while (v_object_id > 0) loop
         delete from acs_permissions where object_id = v_object_id;

        acs_object.del(
                v_object_id
        );

        select max(object_id) 
        into   v_object_id 
        from   acs_objects 
        where  object_type = 'notification_interval' 
        or     object_type = 'notification_delivery_method' 
        or     object_type = 'notification_type' 
        or     object_type = 'notification_request' 
        or     object_type = 'notification';
    end loop;

end;
/
show errors

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
