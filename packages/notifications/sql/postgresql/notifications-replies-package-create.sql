
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


create function notification_reply__new (integer,integer,integer,integer,varchar,text,timestamptz,timestamptz,integer,varchar,integer)
returns integer as '
DECLARE
        p_reply_id                      alias for $1;
        p_object_id                     alias for $2;
        p_type_id                       alias for $3;
        p_from_user                     alias for $4;
        p_subject                       alias for $5;
        p_content                       alias for $6;
        p_reply_date                    alias for $7;
        p_creation_date                 alias for $8;
        p_creation_user                 alias for $9;
        p_creation_ip                   alias for $10;
        p_context_id                    alias for $11;
        v_reply_id                      integer;        
BEGIN
        v_reply_id:= acs_object__new (
                                    p_reply_id,
                                    ''notification_reply'',
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
' language 'plpgsql';


create function notification_reply__delete(integer)
returns integer as '
DECLARE
        p_reply_id              alias for $1;
BEGIN
        perform acs_object__delete(p_reply_id);
        return (0);
END;
' language 'plpgsql';
