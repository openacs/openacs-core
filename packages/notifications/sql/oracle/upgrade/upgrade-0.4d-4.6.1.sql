-- DRB: Deleting notification requests failed if any notification were pending

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
      (request_id, type_id, user_id, object_id, interval_id, delivery_method_id, format) values
      (v_request_id, type_id, user_id, object_id, interval_id, delivery_method_id, format);

      return v_request_id;                          
   end new;

   procedure delete (
      request_id                        in notification_requests.request_id%TYPE default null
   )
   is
   begin
     for v_notifications in (select notification_id
                             from notifications n, notification_requests nr
                             where n.response_id = nr.object_id
                               and nr.request_id = request_id)
     loop
       acs_object.delete(v_notifications.notification_id);
     end loop;
     acs_object.delete(request_id);
   end delete;

   procedure delete_all (
      object_id                        in notification_requests.object_id%TYPE default null
   )
   is
      v_request                        notification_requests%ROWTYPE;
   begin
      for v_request in
      (select request_id from notification_requests where object_id= delete_all.object_id)
      LOOP    
              notification_request.delete(v_request.request_id);
      END LOOP;
   end delete_all;

end notification_request;
/
show errors

