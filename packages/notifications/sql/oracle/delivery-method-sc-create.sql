
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
-- The service contract for defining a delivery method
-- 

declare
   foo           integer;
begin
   foo := acs_sc_contract.new (
              contract_name => 'NotificationDeliveryMethod',
              contract_desc => 'Notification Delivery Method'
          );

   foo := acs_sc_msg_type.new (
              msg_type_name => 'NotificationDeliveryMethod.Send.InputType',
              msg_type_spec => 'to_user_id:integer,reply_object_id:integer,notification_type_id:integer,subject:string,content:string'
          );

   foo := acs_sc_msg_type.new (
              msg_type_name => 'NotificationDeliveryMethod.Send.OutputType',
              msg_type_spec => ''
          );

   foo := acs_sc_operation.new (
              contract_name => 'NotificationDeliveryMethod',
              operation_name => 'Send',
              operation_desc => 'send a notification',
              operation_iscachable_p => 'f',
              operation_nargs => 5,
              operation_inputtype => 'NotificationDeliveryMethod.Send.InputType',
              operation_outputtype => 'NotificationDeliveryMethod.Send.OutputType'
   );

   foo := acs_sc_msg_type.new (
              msg_type_name => 'NotificationDeliveryMethod.ScanReplies.InputType',
              msg_type_spec => ''
          );

   foo := acs_sc_msg_type.new (
              msg_type_name => 'NotificationDeliveryMethod.ScanReplies.OutputType',
              msg_type_spec => ''
          );

   foo := acs_sc_operation.new (
              contract_name => 'NotificationDeliveryMethod',
              operation_name => 'ScanReplies',
              operation_desc => 'scan for replies',
              operation_iscachable_p => 'f',
              operation_nargs => 0,
              operation_inputtype => 'NotificationDeliveryMethod.ScanReplies.InputType',
              operation_outputtype => 'NotificationDeliveryMethod.ScanReplies.OutputType'
   );

end;
/
show errors

