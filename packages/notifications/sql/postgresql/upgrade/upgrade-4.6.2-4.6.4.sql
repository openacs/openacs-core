--
-- Upgrade script
-- 
-- Adds a notif_user column to notifications table
--
-- @author Lars Pind (lars@pinds.com)
-- @creation-date 2003-02-06
--


-- add the column
alter table notifications add 
    notif_user                      integer
                                    constraint notif_user_id_fk
                                    references users(user_id);



-- First, drop the old __new function
delete from acs_function_args where function = upper('notification__new');
drop function notification__new(integer,integer,integer,timestamptz,integer,varchar,text,text,timestamptz,integer,varchar,integer);


-- The define the new one
select define_function_args ('notification__new','notification_id,type_id,object_id,notif_date,response_id,notif_user,notif_subject,notif_text,notif_html,creation_date,creation_user,creation_ip,context_id');



--
-- procedure notification__new/13
--
CREATE OR REPLACE FUNCTION notification__new(
   p_notification_id integer,
   p_type_id integer,
   p_object_id integer,
   p_notif_date timestamptz,
   p_response_id integer,
   p_notif_user integer,
   p_notif_subject varchar,
   p_notif_text text,
   p_notif_html text,
   p_creation_date timestamptz,
   p_creation_user integer,
   p_creation_ip varchar,
   p_context_id integer
) RETURNS integer AS $$
DECLARE
    v_notification_id               integer;
    v_notif_date                    notifications.notif_date%TYPE;
BEGIN
    v_notification_id := acs_object__new(
        p_notification_id,
        'notification',
        p_creation_date,
        p_creation_user,
        p_creation_ip,
        p_context_id
    );

    if p_notif_date is null then
        v_notif_date := now();
    else
        v_notif_date := p_notif_date;
    end if;

    insert
    into notifications
    (notification_id, type_id, object_id, notif_date, response_id, notif_user, notif_subject, notif_text, notif_html)
    values
    (v_notification_id, p_type_id, p_object_id, v_notif_date, p_response_id, p_notif_user, p_notif_subject, p_notif_text, p_notif_html);

    return v_notification_id;
END;

$$ LANGUAGE plpgsql;
