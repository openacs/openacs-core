
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

--
-- The service contract implementation for email
-- 

create function inline_1() returns integer as '
declare
   impl_id      integer;
   foo           integer;
begin
   
   impl_id := acs_sc_impl__new (
              ''NotificationDeliveryMethod'',
              ''notification_email'',
              ''notifications''
   );

   foo := acs_sc_impl_alias__new (
              ''NotificationDeliveryMethod'',
              ''notification_email'',
              ''Send'',
              ''notification::email::send'',
              ''TCL''
   );

   foo := acs_sc_impl_alias__new (
              ''NotificationDeliveryMethod'',
              ''notification_email'',
              ''ScanReplies'',
              ''notification::email::scan_replies'',
              ''TCL''
   );

   perform acs_sc_binding__new (
              ''NotificationDeliveryMethod'',
              ''notification_email''
   );                             

   foo:= notification_delivery_method__new(
       NULL,
       impl_id,
       ''email'',
       ''Email'',
       now(),
       null,
       null,
       null
   );

   return(0);   
        
end;
' language 'plpgsql';

select inline_1();
drop function inline_1();
