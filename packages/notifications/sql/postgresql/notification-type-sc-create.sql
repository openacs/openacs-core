
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
-- The service contract for a notification type
-- 

create function inline_1()
returns integer as '
DECLARE
BEGIN
   PERFORM acs_sc_contract__new (
              ''NotificationType'',
              ''Notification Type''
   );

   PERFORM acs_sc_msg_type__new (
              ''NotificationType.GetURL.InputType'',
              ''object_id:integer''
   );

   PERFORM acs_sc_msg_type__new (
              ''NotificationType.GetURL.OutputType'',
              ''url:string''
   );

   PERFORM acs_sc_operation__new (
              ''NotificationType'',
              ''GetURL'',
              ''gets the URL for an object in this notification type'',
              ''f'',
              1,
              ''NotificationType.GetURL.InputType'',
              ''NotificationType.GetURL.OutputType''
   );

   PERFORM acs_sc_msg_type__new (
              ''NotificationType.ProcessReply.InputType'',
              ''reply_id:integer''
   );

   PERFORM acs_sc_msg_type__new (
              ''NotificationType.ProcessReply.OutputType'',
              ''success_p:boolean''
   );

   PERFORM acs_sc_operation__new (
              ''NotificationType'',
              ''ProcessReply'',
              ''Process a single reply'',
              ''f'',
              1,
              ''NotificationType.ProcessReply.InputType'',
              ''NotificationType.ProcessReply.OutputType''
   );

   return (0);

END;
' language 'plpgsql';

select inline_1();
drop function inline_1();

