
--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--


-- The Notification Replies Package

create or replace package notification_reply
as
   function new (
      reply_id                          in notification_replies.reply_id%TYPE default null,
      object_id                         in notification_replies.object_id%TYPE,
      type_id                           in notification_replies.type_id%TYPE,
      from_user                         in notification_replies.from_user%TYPE,
      subject                           in notification_replies.subject%TYPE,
      content                           in varchar,
      reply_date                        in notification_replies.reply_date%TYPE default sysdate,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE default null,
      creation_ip                       in acs_objects.creation_ip%TYPE default null,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notification_replies.reply_id%TYPE;

   procedure del (
      reply_id                          in notification_replies.reply_id%TYPE
   );
end notification_reply;
/
show errors


create or replace package body notification_reply
as
   function new (
      reply_id                          in notification_replies.reply_id%TYPE default null,
      object_id                         in notification_replies.object_id%TYPE,
      type_id                           in notification_replies.type_id%TYPE,
      from_user                         in notification_replies.from_user%TYPE,
      subject                           in notification_replies.subject%TYPE,
      content                           in varchar,
      reply_date                        in notification_replies.reply_date%TYPE default sysdate,
      creation_date                     in acs_objects.creation_date%TYPE default sysdate,
      creation_user                     in acs_objects.creation_user%TYPE default null,
      creation_ip                       in acs_objects.creation_ip%TYPE default null,
      context_id                        in acs_objects.context_id%TYPE default null
   ) return notification_replies.reply_id%TYPE
   is
        v_reply_id                      acs_objects.object_id%TYPE;
   begin
        v_reply_id:= acs_object.new (
                                    object_id => reply_id,
                                    object_type => 'notification_reply',
                                    creation_date => creation_date,
                                    creation_user => creation_user,
                                    creation_ip => creation_ip,
                                    context_id => context_id
                                    );

        insert into notification_replies
        (reply_id, object_id, type_id, from_user, subject, content, reply_date)
        values
        (v_reply_id, object_id, type_id, from_user, subject, content, reply_date);

        return v_reply_id;
   end new;

   procedure del (
      reply_id                          in notification_replies.reply_id%TYPE
   )
   is
   begin
      acs_object.del(object_id => reply_id);
   end del;

end notification_reply;
/
show errors
