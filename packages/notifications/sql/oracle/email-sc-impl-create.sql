
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

declare
   impl_id      integer;
   foo           integer;
begin
   
   impl_id := acs_sc_impl.new (
              'NotificationDeliveryMethod',
              'notification_email',
              'notifications'
          );

   foo := acs_sc_impl.new_alias (
              'NotificationDeliveryMethod',
              'notification_email'
              'Send',
              'notification::email::send',
              'TCL'
          );

   foo := acs_sc_impl.new_alias (
              'NotificationDeliveryMethod',
              'notification_email'
              'ScanReplies',
              'notification::email::scan_replies',
              'TCL'
          );

   foo := acs_sc_binding.new (
              contract_name => 'NotificationDeliveryMethod',
              impl_name => 'notification_email'
          );                             

   foo:= notification_delivery_method.new(
       short_name => 'email',
       sc_impl_id => impl_id,
       pretty_name => 'Email',
       creation_user => null,
       creation_ip => null
   );
   
        
end;
/
show errors

