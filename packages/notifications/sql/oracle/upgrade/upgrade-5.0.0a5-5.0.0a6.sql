-- Add the on delete cascade to response_id column,
-- see Bug http://openacs.org/bugtracker/openacs/bug?filter%2estatus=resolved&filter%2eactionby=6815&bug%5fnumber=260
-- @author Peter Marklund
alter table notifications drop constraint notif_response_id_fk;
alter table notifications add constraint notif_response_id_fk
                              foreign key (response_id)
                              references acs_objects (object_id)
                              on delete cascade;
