-- Add on delete cascade to the notifications.response_id column foreign key constraint
-- see Bug http://openacs.org/bugtracker/openacs/bug?filter%2estatus=resolved&filter%2eactionby=6815&bug%5fnumber=260
-- @author Peter Marklund
alter table notifications drop constraint notif_reponse_id_fk;
alter table notifications add constraint notif_reponse_id_fk
                              foreign key (response_id)
                              references acs_objects (object_id)
                              on delete cascade;

-- Add on delete cascade to notification_user_map.notification_in foreign key constraint
alter table notification_user_map drop constraint notif_user_map_notif_id_fk;
alter table notification_user_map add constraint notif_user_map_notif_id_fk 
                                      foreign key (notification_id) 
                                      references notifications(notification_id) 
                                      on delete cascade;
