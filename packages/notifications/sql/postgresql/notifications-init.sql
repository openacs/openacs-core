
--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--

-- initialize some stuff
create function inline_0 ()
returns integer as '
begin

    perform notification_interval__new (
        null,
        ''daily'',
        3600 * 24,
        now(),
        null,
        null,
        null
    );

    perform notification_interval__new (
        null,
        ''hourly'',
        3600,
        now(),
        null,
        null,
        null
    );

    perform notification_interval__new (
        null,
        ''instant'',
        0,
        now(),
        null,
        null,
        null
    );
           
-- This is now done by email-sc-impl-create.sql
--
--     perform notification_delivery_method__new (
--         null,
--         ''email'',
--         ''Email'',
--         now(),
--         null,
--         null,
--         null
--     );

    return null;

end;' language 'plpgsql';

select inline_0();
drop function inline_0 ();
