
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

--
-- The service contract for defining a delivery method
-- 

create function inline_1()
returns integer as '
DECLARE
BEGIN
   PERFORM acs_sc_contract__new (
              ''NotificationDeliveryMethod'',
              ''Notification Delivery Method''
   );

   PERFORM acs_sc_msg_type__new (
              ''NotificationDeliveryMethod.Send.InputType'',
              ''to_user_id:integer,reply_object_id:integer,notification_type_id:integer,subject:string,content:string''
   );

   PERFORM acs_sc_msg_type__new (
              ''NotificationDeliveryMethod.Send.OutputType'',
              ''''
   );

   PERFORM acs_sc_operation__new (
              ''NotificationDeliveryMethod'',
              ''Send'',
              ''send a notification'',
              ''f'',
              5,
              ''NotificationDeliveryMethod.Send.InputType'',
              ''NotificationDeliveryMethod.Send.OutputType''
   );

   PERFORM acs_sc_msg_type__new (
              ''NotificationDeliveryMethod.ScanReplies.InputType'',
              ''''
   );

   PERFORM acs_sc_msg_type__new (
              ''NotificationDeliveryMethod.ScanReplies.OutputType'',
              ''''
   );

   PERFORM acs_sc_operation__new (
              ''NotificationDeliveryMethod'',
              ''ScanReplies'',
              ''scan for replies'',
              ''f'',
              0,
              ''NotificationDeliveryMethod.ScanReplies.InputType'',
              ''NotificationDeliveryMethod.ScanReplies.OutputType''
   );

   return(0);

end;
' language 'plpgsql';

select inline_1();
drop function inline_1();
