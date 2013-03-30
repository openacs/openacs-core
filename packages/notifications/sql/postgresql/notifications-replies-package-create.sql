
--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--


-- The Notification Replies Package

select define_function_args ('notification_reply__new','reply_id,object_id,type_id,from_user,subject,content,reply_date,creation_date,creation_user,creation_ip,context_id');

select define_function_args ('notification_reply__delete','reply_id');


CREATE OR REPLACE FUNCTION notification_reply__new (
       p_reply_id integer,
       p_object_id integer,
       p_type_id integer,
       p_from_user integer,
       p_subject varchar,
       p_content text,
       p_reply_date timestamptz,
       p_creation_date timestamptz,
       p_creation_user integer,
       p_creation_ip varchar,
       p_context_id integer
) RETURNS integer AS $$
DECLARE
        v_reply_id                      integer;        
BEGIN
        v_reply_id:= acs_object__new (
                                    p_reply_id,
                                    'notification_reply',
                                    p_creation_date,
                                    p_creation_user,
                                    p_creation_ip,
                                    p_context_id
                                    );

        insert into notification_replies
        (reply_id, object_id, type_id, from_user, subject, content, reply_date)
        values
        (v_reply_id, p_object_id, p_type_id, p_from_user, p_subject, p_content, p_reply_date);


        return v_reply_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION notification_reply__delete(
       p_reply_id integer
)
RETURNS integer AS $$
DECLARE
BEGIN
        perform acs_object__delete(p_reply_id);
        return (0);
END;
$$ LANGUAGE plpgsql;
