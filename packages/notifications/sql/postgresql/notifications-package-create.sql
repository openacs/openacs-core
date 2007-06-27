--
-- The Notifications Package
--
-- ben@openforce.net
-- Copyright (C) 2000 MIT
--
-- GNU GPL v2
--

select define_function_args ('notification_interval__new','interval_id,name,n_seconds,creation_date,creation_user,creation_ip,context_id');

create function notification_interval__new (integer, varchar, integer, timestamptz, integer, varchar, integer)
returns integer as '
declare
    p_interval_id                   alias for $1;
    p_name                          alias for $2;
    p_n_seconds                     alias for $3;
    p_creation_date                 alias for $4;
    p_creation_user                 alias for $5;
    p_creation_ip                   alias for $6;
    p_context_id                    alias for $7;
    v_interval_id                   integer;
begin
    v_interval_id := acs_object__new(
        p_interval_id,
        ''notification_interval'',
        p_creation_date,
        p_creation_user,
        p_creation_ip,
        p_context_id
    );

    insert
    into notification_intervals
    (interval_id, name, n_seconds)
    values
    (v_interval_id, p_name, p_n_seconds);

    return v_interval_id;
end;
' language 'plpgsql';

select define_function_args ('notification_interval__delete','interval_id');

create function notification_interval__delete(integer)
returns integer as '
declare
    p_interval_id                   alias for $1;
begin
    perform acs_object__delete(p_interval_id);
    return 0;
end;
' language 'plpgsql';

select define_function_args ('notification_delivery_method__new','delivery_method_id,sc_impl_id,short_name,pretty_name,creation_date,creation_user,creation_ip,context_id');

create function notification_delivery_method__new (integer, integer, varchar, varchar, timestamptz, integer, varchar, integer)
returns integer as '
declare
    p_delivery_method_id            alias for $1;
    p_sc_impl_id                    alias for $2;
    p_short_name                    alias for $3;
    p_pretty_name                   alias for $4;
    p_creation_date                 alias for $5;
    p_creation_user                 alias for $6;
    p_creation_ip                   alias for $7;
    p_context_id                    alias for $8;
    v_delivery_method_id            integer;
begin
    v_delivery_method_id := acs_object__new(
        p_delivery_method_id,
        ''notification_delivery_method'',
        p_creation_date,
        p_creation_user,
        p_creation_ip,
        p_context_id
    );

    insert
    into notification_delivery_methods
    (delivery_method_id, sc_impl_id, short_name, pretty_name)
    values
    (v_delivery_method_id, p_sc_impl_id, p_short_name, p_pretty_name);

    return v_delivery_method_id;
end;
' language 'plpgsql';


create function notification_delivery_method__delete(integer)
returns integer as '
DECLARE
        p_delivery_method_id            alias for $1;
BEGIN
        perform acs_object__delete(p_delivery_method_id);
        return 0;
END;
' language 'plpgsql';


-- Notification Types Package
select define_function_args ('notification_type__new','type_id,sc_impl_id,short_name,pretty_name,description,creation_date,creation_user,creation_ip,context_id');

-- implementation

create function notification_type__new (integer,integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer)
returns integer as '
DECLARE
        p_type_id                       alias for $1;
        p_sc_impl_id                    alias for $2;
        p_short_name                    alias for $3;
        p_pretty_name                   alias for $4;
        p_description                   alias for $5;
        p_creation_date                 alias for $6;
        p_creation_user                 alias for $7;
        p_creation_ip                   alias for $8;
        p_context_id                    alias for $9;
        v_type_id                       integer;
BEGIN
        v_type_id:= acs_object__new (
                                    p_type_id,
                                    ''notification_type'',
                                    p_creation_date,
                                    p_creation_user,
                                    p_creation_ip,
                                    p_context_id);

      insert into notification_types
      (type_id, sc_impl_id, short_name, pretty_name, description) values
      (v_type_id, p_sc_impl_id, p_short_name, p_pretty_name, p_description);
      
      return v_type_id;
END;
' language 'plpgsql';

select define_function_args ('notification_type__delete','type_id');

create function notification_type__delete(integer)
returns integer as '
declare
    p_type_id                       alias for $1;
begin
    perform acs_object__delete(p_type_id);
    return 0;
end;
' language 'plpgsql';

select define_function_args ('notification_request__new','request_id,object_type;notification_request,type_id,user_id,object_id,interval_id,delivery_method_id,format,dynamic_p;f,creation_date,creation_user,creation_ip,context_id');

create function notification_request__new (
       integer,                       -- request_id
       varchar,                       -- object_type
       integer,                       -- type_id
       integer,                       -- user_id
       integer,                       -- object_id
       integer,                       -- interval_id
       integer,                       -- delivery_method_id
       varchar,                       -- format
       bool,                          -- dynamic_p
       timestamptz,                   -- creation_date
       integer,                       -- creation_user
       varchar,                       -- creation_ip
       integer                        -- context_id
) returns integer as '

DECLARE
        p_request_id                            alias for $1;
        p_object_type                           alias for $2;
        p_type_id                               alias for $3;
        p_user_id                               alias for $4;
        p_object_id                             alias for $5;
        p_interval_id                           alias for $6;
        p_delivery_method_id                    alias for $7;
        p_format                                alias for $8;
        p_dynamic_p                             alias for $9;
        p_creation_date                         alias for $10;
        p_creation_user                         alias for $11;
        p_creation_ip                           alias for $12;
        p_context_id                            alias for $13;
        v_request_id                            integer;
BEGIN
        v_request_id:= acs_object__new (
                                       p_request_id,
                                       p_object_type,
                                       p_creation_date,
                                       p_creation_user,
                                       p_creation_ip,
                                       p_context_id);

      insert into notification_requests
      (request_id, type_id, user_id, object_id, interval_id, delivery_method_id, format, dynamic_p) values
      (v_request_id, p_type_id, p_user_id, p_object_id, p_interval_id, p_delivery_method_id, p_format, p_dynamic_p);

      return v_request_id;                          

END;
' language 'plpgsql';

select define_function_args ('notification_request__delete','request_id');

create or replace function notification_request__delete(integer)
returns integer as '
declare
    p_request_id                    alias for $1;
    v_notifications record;
begin
    for v_notifications in select notification_id
                           from notifications n, notification_requests nr
                           where n.response_id = nr.object_id
                             and nr.request_id = p_request_id
    loop
      perform acs_object__delete(v_notifications.notification_id);
    end loop;

    perform acs_object__delete(p_request_id);
    return 0;
end;
' language 'plpgsql';

select define_function_args ('notification_request__delete_all', 'object_id');

create function notification_request__delete_all(integer)
returns integer as '
declare
    p_object_id                     alias for $1;
    v_request                       RECORD;
begin
    for v_request in select request_id
                     from notification_requests
                     where object_id= p_object_id
    loop
        perform notification_request__delete(v_request.request_id);
    end loop;

    return 0;
end;
' language 'plpgsql';

select define_function_args ('notification_request__delete_all_for_user', 'user_id');

create function notification_request__delete_all_for_user(integer)
returns integer as '
declare
    p_user_id                       alias for $1;
    v_request                       RECORD;
begin
    for v_request in select request_id
                     from notification_requests
                     where user_id= p_user_id
    loop
        perform notification_request__delete(v_request.request_id);
    end loop;

    return 0;
end;
' language 'plpgsql';


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

select define_function_args ('notification__delete','notification_id');

create function notification__delete(integer)
returns integer as '
declare
    p_notification_id               alias for $1;
begin
    delete from notifications where notification_id = p_notification_id;
    perform acs_object__delete(p_notification_id);
    return 0;
end;
' language 'plpgsql';
