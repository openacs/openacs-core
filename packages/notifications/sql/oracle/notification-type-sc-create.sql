
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

declare
   foo           integer;
begin
   foo := acs_sc_contract.new (
              contract_name => 'NotificationType',
              contract_desc => 'Notification Type'
          );

   foo := acs_sc_msg_type.new (
              msg_type_name => 'NotificationType.GetURL.InputType',
              msg_type_spec => 'object_id:integer'
          );

   foo := acs_sc_msg_type.new (
              msg_type_name => 'NotificationType.GetURL.OutputType',
              msg_type_spec => 'url:string'
          );

   foo := acs_sc_operation.new (
              contract_name => 'NotificationType',
              operation_name => 'GetURL',
              operation_desc => 'gets the URL for an object in this notification type',
              operation_iscachable_p => 'f',
              operation_nargs => 1,
              operation_inputtype => 'NotificationType.GetURL.InputType',
              operation_outputtype => 'NotificationType.GetURL.OutputType'
   );

   foo := acs_sc_msg_type.new (
              msg_type_name => 'NotificationType.ProcessReply.InputType',
              msg_type_spec => 'reply_id:integer'
          );

   foo := acs_sc_msg_type.new (
              msg_type_name => 'NotificationType.ProcessReply.OutputType',
              msg_type_spec => 'success_p:boolean'
          );

   foo := acs_sc_operation.new (
              contract_name => 'NotificationType',
              operation_name => 'ProcessReply',
              operation_desc => 'Process a single reply',
              operation_iscachable_p => 'f',
              operation_nargs => 1,
              operation_inputtype => 'NotificationType.ProcessReply.InputType',
              operation_outputtype => 'NotificationType.ProcessReply.OutputType'
   );

end;
/
show errors

