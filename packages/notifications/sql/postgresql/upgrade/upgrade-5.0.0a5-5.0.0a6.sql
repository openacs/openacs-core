-- Add the on delete cascade to response_id column,
-- see Bug http://openacs.org/bugtracker/openacs/bug?filter%2estatus=resolved&filter%2eactionby=6815&bug%5fnumber=260
-- @author Peter Marklund

alter table notifications rename to notifications_bak;

-- Before we create the new table we need to drop constraints
-- to avoid naming conflicts
alter table notifications_bak drop constraint notif_notif_id_pk;

create table notifications (
    notification_id                 integer
                                    constraint notif_notif_id_fk
                                    references acs_objects (object_id)
                                    constraint notif_notif_id_pk
                                    primary key,
    type_id                         integer
                                    constraint notif_type_id_fk
                                    references notification_types(type_id),
    -- the object this notification pertains to
    object_id                       integer
                                    constraint notif_object_id_fk
                                    references acs_objects(object_id)
                                    on delete cascade,
    notif_date                      timestamptz
                                    constraint notif_notif_date_nn
                                    not null,
    -- this is to allow responses to notifications
    response_id                     integer
                                    constraint notif_reponse_id_fk
                                    references acs_objects (object_id)
                                    on delete cascade,
    -- this is the user that caused the notification to go out
    notif_user                      integer
                                    constraint notif_user_id_fk
                                    references users(user_id),
    notif_subject                   varchar(1000),
    notif_text                      text,
    notif_html                      text
);

insert into notifications select * from notifications_bak;
