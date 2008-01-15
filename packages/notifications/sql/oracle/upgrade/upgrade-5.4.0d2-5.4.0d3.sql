-- Adding support for file attachments in notifications
alter table notifications add file_ids varchar(4000);

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
      file_ids                          in varchar default null,
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
      file_ids                          in varchar default null,
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
      (notification_id, type_id, object_id, notif_date, response_id, notif_user, notif_subject, notif_text, notif_html, file_ids)
      values
      (v_notification_id, type_id, object_id, notif_date, response_id, notif_user, notif_subject, notif_text, notif_html, file_ids);

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
