create table notification_email_hold (
    reply_id			integer
				constraint notification_email_hold_pk primary key
				constraint notif_email_hold_reply_id_ref
				references notification_replies(reply_id),
    to_addr			clob,
    headers			clob,
    body			clob
);


--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--


-- The Notification Interval Package

create or replace package notification_interval
as
   function new (
      interval_id                       in notification_intervals.interval_id%TYPE default null,
      name                              in notification_intervals.name%TYPE,
      n_seconds                         in notification_intervals.n_seconds%TYPE,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE,
      creation_ip                       in acs_objects.creation_ip%TYPE,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notification_intervals.interval_id%TYPE;

   procedure del (
      interval_id                       in notification_intervals.interval_id%TYPE
   );

end notification_interval;
/
show errors



create or replace package body notification_interval
as
   function new (
      interval_id                       in notification_intervals.interval_id%TYPE default null,
      name                              in notification_intervals.name%TYPE,
      n_seconds                         in notification_intervals.n_seconds%TYPE,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE,
      creation_ip                       in acs_objects.creation_ip%TYPE,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notification_intervals.interval_id%TYPE
   is
      v_interval_id                     acs_objects.object_id%TYPE;
   begin
      v_interval_id:= acs_object.new (
                                      object_id => interval_id,
                                      object_type => 'notification_interval',
                                      creation_date => creation_date,
                                      creation_user => creation_user,
                                      creation_ip => creation_ip,
                                      context_id => context_id
                                      );

      insert into notification_intervals
      (interval_id, name, n_seconds) values
      (v_interval_id, name, n_seconds);

      return v_interval_id;
   end new;

   procedure del (
      interval_id                       in notification_intervals.interval_id%TYPE
   )
   is 
   begin
      acs_object.del(interval_id);
   end del;

end notification_interval;
/
show errors


-- The notification delivery methods package

create or replace package notification_delivery_method
as
   function new (
      delivery_method_id                in notification_delivery_methods.delivery_method_id%TYPE default null,
      sc_impl_id                        in notification_delivery_methods.sc_impl_id%TYPE,
      short_name                        in notification_delivery_methods.short_name%TYPE,
      pretty_name                       in notification_delivery_methods.pretty_name%TYPE,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE,
      creation_ip                       in acs_objects.creation_ip%TYPE,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notification_delivery_methods.delivery_method_id%TYPE;

   procedure del (
      delivery_method_id                in notification_delivery_methods.delivery_method_id%TYPE
   );

end notification_delivery_method;
/
show errors



create or replace package body notification_delivery_method
as
   function new (
      delivery_method_id                in notification_delivery_methods.delivery_method_id%TYPE default null,
      sc_impl_id                        in notification_delivery_methods.sc_impl_id%TYPE,
      short_name                        in notification_delivery_methods.short_name%TYPE,
      pretty_name                       in notification_delivery_methods.pretty_name%TYPE,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE,
      creation_ip                       in acs_objects.creation_ip%TYPE,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notification_delivery_methods.delivery_method_id%TYPE
   is
      v_delivery_method_id              acs_objects.object_id%TYPE;
   begin
      v_delivery_method_id := acs_object.new (
                                  object_id => delivery_method_id,
                                  object_type => 'notification_delivery_method',
                                  creation_date => creation_date,
                                  creation_user => creation_user,
                                  creation_ip => creation_ip,
                                  context_id => context_id
                              );

      insert into notification_delivery_methods
      (delivery_method_id, sc_impl_id, short_name, pretty_name) values
      (v_delivery_method_id, sc_impl_id, short_name, pretty_name);

      return v_delivery_method_id;
   end new;

   procedure del (
      delivery_method_id                in notification_delivery_methods.delivery_method_id%TYPE
   )
   is
   begin
      acs_object.del (delivery_method_id);
   end del;

end notification_delivery_method;
/
show errors



-- Notification Types Package
create or replace package notification_type
as
   function new (
      type_id                           in notification_types.type_id%TYPE default null,
      sc_impl_id                        in notification_types.sc_impl_id%TYPE,
      short_name                        in notification_types.short_name%TYPE,
      pretty_name                       in notification_types.pretty_name%TYPE,
      description                       in notification_types.description%TYPE,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE,
      creation_ip                       in acs_objects.creation_ip%TYPE,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notification_types.type_id%TYPE;

   procedure del (
      type_id                           in notification_types.type_id%TYPE default null
   );

end notification_type;
/
show errors



create or replace package body notification_type
as
   function new (
      type_id                           in notification_types.type_id%TYPE default null,
      sc_impl_id                        in notification_types.sc_impl_id%TYPE,
      short_name                        in notification_types.short_name%TYPE,
      pretty_name                       in notification_types.pretty_name%TYPE,
      description                       in notification_types.description%TYPE,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE,
      creation_ip                       in acs_objects.creation_ip%TYPE,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notification_types.type_id%TYPE
   is
      v_type_id                         acs_objects.object_id%TYPE;
   begin
      v_type_id := acs_object.new (
                       object_id => type_id,
                       object_type => 'notification_type',
                       creation_date => creation_date,
                       creation_user => creation_user,
                       creation_ip => creation_ip,
                       context_id => context_id
                   );
      
      insert into notification_types
      (type_id, sc_impl_id, short_name, pretty_name, description) values
      (v_type_id, sc_impl_id, short_name, pretty_name, description);
      
      return v_type_id;
   end new;

   procedure del (
      type_id                           in notification_types.type_id%TYPE default null
   )
   is
   begin
      acs_object.del(type_id);
   end del;

end notification_type;
/
show errors



-- the notification request package

create or replace package notification_request
as
   function new (
      request_id                        in notification_requests.request_id%TYPE default null,
      object_type                       in acs_objects.object_type%TYPE default 'notification_request',
      type_id                           in notification_requests.type_id%TYPE,
      user_id                           in notification_requests.user_id%TYPE,
      object_id                         in notification_requests.object_id%TYPE,
      interval_id                       in notification_requests.interval_id%TYPE,
      delivery_method_id                in notification_requests.delivery_method_id%TYPE,
      format                            in notification_requests.format%TYPE,
      dynamic_p                         in notification_requests.dynamic_p%TYPE,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE,
      creation_ip                       in acs_objects.creation_ip%TYPE,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notification_requests.request_id%TYPE;

   procedure del (
      request_id                        in notification_requests.request_id%TYPE default null
   );

   procedure delete_all (
      object_id                        in notification_requests.object_id%TYPE default null
   );
end notification_request;
/
show errors

create or replace package body notification_request
as
   function new (
      request_id                        in notification_requests.request_id%TYPE default null,
      object_type                       in acs_objects.object_type%TYPE default 'notification_request',
      type_id                           in notification_requests.type_id%TYPE,
      user_id                           in notification_requests.user_id%TYPE,
      object_id                         in notification_requests.object_id%TYPE,
      interval_id                       in notification_requests.interval_id%TYPE,
      delivery_method_id                in notification_requests.delivery_method_id%TYPE,
      format                            in notification_requests.format%TYPE,
      dynamic_p                         in notification_requests.dynamic_p%TYPE,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE,
      creation_ip                       in acs_objects.creation_ip%TYPE,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notification_requests.request_id%TYPE
   is
      v_request_id                      acs_objects.object_id%TYPE;
   begin
      v_request_id := acs_object.new (
                          object_id => request_id,
                          object_type => object_type,
                          creation_date => creation_date,
                          creation_user => creation_user,
                          creation_ip => creation_ip,
                          context_id => context_id
                      );

      insert into notification_requests
      (request_id, type_id, user_id, object_id, interval_id, delivery_method_id, format, dynamic_p) values
      (v_request_id, type_id, user_id, object_id, interval_id, delivery_method_id, format, dynamic_p);

      return v_request_id;                          
   end new;

   procedure del (
      request_id                        in notification_requests.request_id%TYPE default null
   )
   is
   begin
     for v_notifications in (select notification_id
                             from notifications n, notification_requests nr
                             where n.response_id = nr.object_id
                               and nr.request_id = request_id)
     loop
      acs_object.del(v_notifications.notification_id);
     end loop;
     acs_object.del(request_id);
   end del;

   procedure delete_all (
      object_id                        in notification_requests.object_id%TYPE default null
   )
   is
      v_request                        notification_requests%ROWTYPE;
   begin
      for v_request in
      (select request_id from notification_requests where object_id= delete_all.object_id)
      LOOP    
              notification_request.del(v_request.request_id);
      END LOOP;
   end delete_all;

end notification_request;
/
show errors





-- the notifications package
create or replace package notification
as

   function new (
      notification_id                   in notifications.notification_id%TYPE default null,
      type_id                           in notifications.type_id%TYPE,
      object_id                         in notifications.object_id%TYPE,
      notif_date                        in notifications.notif_date%TYPE default sysdate,
      response_id                       in notifications.response_id%TYPE default null,
      notif_user                        in notifications.notif_user%TYPE default null,
      notif_subject                     in notifications.notif_subject%TYPE default null,
      notif_text                        in varchar default null,
      notif_html                        in varchar default null,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE,
      creation_ip                       in acs_objects.creation_ip%TYPE,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notifications.notification_id%TYPE;

   procedure del (
      notification_id                   in notifications.notification_id%TYPE default null
   );

end notification;
/
show errors



create or replace package body notification
as

   function new (
      notification_id                   in notifications.notification_id%TYPE default null,
      type_id                           in notifications.type_id%TYPE,
      object_id                         in notifications.object_id%TYPE,
      notif_date                        in notifications.notif_date%TYPE default sysdate,
      response_id                       in notifications.response_id%TYPE default null,
      notif_user                        in notifications.notif_user%TYPE default null,
      notif_subject                     in notifications.notif_subject%TYPE default null,
      notif_text                        in varchar default null,
      notif_html                        in varchar default null,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE,
      creation_ip                       in acs_objects.creation_ip%TYPE,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notifications.notification_id%TYPE
   is
      v_notification_id                 acs_objects.object_id%TYPE;
   begin
      v_notification_id := acs_object.new (
                               object_id => notification_id,
                               object_type => 'notification',
                               creation_date => creation_date,
                               creation_user => creation_user,
                               creation_ip => creation_ip,
                               context_id => context_id
                           );

      insert into notifications
      (notification_id, type_id, object_id, notif_date, response_id, notif_user, notif_subject, notif_text, notif_html)
      values
      (v_notification_id, type_id, object_id, notif_date, response_id, notif_user, notif_subject, notif_text, notif_html);

      return v_notification_id;
   end new;

   procedure del (
      notification_id                   in notifications.notification_id%TYPE default null
   )
   is
   begin
      delete from notifications where notification_id = notification.del.notification_id;

      acs_object.del (notification_id);
   end del;

end notification;
/
show errors
