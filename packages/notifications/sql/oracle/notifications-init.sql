
--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright OpenForce, 2002.
--
-- GNU GPL v2
--

-- initialize some stuff
declare
        v_foo   integer;
begin
        v_foo:= notification_interval.new (
           name => 'daily',
           n_seconds => 3600 * 24,
           creation_user => NULL,
           creation_ip => NULL
        );

        v_foo:= notification_interval.new (
           name => 'hourly',
           n_seconds => 3600,
           creation_user => NULL,
           creation_ip => NULL
        );

        v_foo:= notification_interval.new (
           name => 'instant',
           n_seconds => 0,
           creation_user => NULL,
           creation_ip => NULL
        );
           
        v_foo:= notification_delivery_method.new (
           short_name => 'email',
           pretty_name => 'Email',
           creation_user => NULL,
           creation_ip => NULL
        );

end;
/
show errors
