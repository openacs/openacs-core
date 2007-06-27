-- Adding support for file attachments in notifications
alter table notifications add column file_ids text;

select define_function_args ('notification__new','notification_id,type_id,object_id,notif_date,response_id,notif_user,notif_subject,notif_text,notif_html,file_ids,creation_date,creation_user,creation_ip,context_id');

create or replace function notification__new(integer,integer,integer,timestamptz,integer,integer,varchar,text,text,text,timestamptz,integer,varchar,integer)
returns integer as '
declare
    p_notification_id               alias for $1;
    p_type_id                       alias for $2;
    p_object_id                     alias for $3;
    p_notif_date                    alias for $4;
    p_response_id                   alias for $5;
    p_notif_user                    alias for $6;
    p_notif_subject                 alias for $7;
    p_notif_text                    alias for $8;
    p_notif_html                    alias for $9;
    p_file_ids                      alias for $10;
    p_creation_date                 alias for $11;
    p_creation_user                 alias for $12;
    p_creation_ip                   alias for $13;
    p_context_id                    alias for $14;
    v_notification_id               integer;
    v_notif_date                    notifications.notif_date%TYPE;
begin
    v_notification_id := acs_object__new(
        p_notification_id,
        ''notification'',
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
    (notification_id, type_id, object_id, notif_date, response_id, notif_user, notif_subject, notif_text, notif_html, file_ids)
    values
    (v_notification_id, p_type_id, p_object_id, v_notif_date, p_response_id, p_notif_user, p_notif_subject, p_notif_text, p_notif_html, p_file_ids);

    return v_notification_id;
end;
' language 'plpgsql';
