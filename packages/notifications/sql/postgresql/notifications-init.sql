
--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--

select notification_interval__new (
    null,
    '#notifications.daily#',
    3600 * 24,
    now(),
    null,
    null,
    null
);

select notification_interval__new (
    null,
    '#notifications.hourly#',
    3600,
    now(),
    null,
    null,
    null
);

select notification_interval__new (
    null,
    '#notifications.instant#',
    0,
    now(),
    null,
    null,
    null
);
