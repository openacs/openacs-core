
--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--


-- The Notification Interval Package

drop function notification_interval__new (integer, varchar, integer, timestamp, integer, varchar, integer);

drop function notification_interval__delete(integer);


-- The notification delivery methods package

drop function notification_delivery_method__new (integer, varchar, varchar, timestamp, integer, varchar, integer);

drop function notification_delivery_method__delete(integer);


-- Notification Types Package

drop function notification_type__new (integer,varchar,varchar,varchar,timestamp,integer,varchar,integer);

drop function notification_type__delete(integer);


-- the notification request package

drop function notification_request__new (integer,varchar,integer,integer,integer,integer,varchar,timestamp,integer,varchar,integer);

drop function notification_request__delete(integer);

drop function notification_request__delete_all(integer);


-- the notifications package

drop function notification__new(integer,integer,integer,timestamp,integer,varchar,text,text,timestamp,integer,varchar,integer);

drop function notification__delete(integer);

