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
