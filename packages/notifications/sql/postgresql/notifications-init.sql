
--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright OpenForce, 2002.
--
-- GNU GPL v2
--

-- initialize some stuff
begin
        select notification_interval__new (
           NULL,
	   'daily',
           3600 * 24,
           now(),
	   NULL,
	   NULL,
	   NULL
	);

        select notification_interval__new (
	   NULL,
           'hourly',
           3600,
	   now(),
           NULL,
           NULL,
	   NULL
        );

        select notification_interval__new (
	   NULL,
           'instant',
           0,
	   now(),
           NULL,
           NULL,
	   NULL
        );
           
        select notification_delivery_method__new (
	   NULL,
           'email',
           'Email',
	   now(),
           NULL,
           NULL,
	   NULL
        );

end;
