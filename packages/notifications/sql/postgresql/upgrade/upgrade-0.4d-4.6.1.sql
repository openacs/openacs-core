-- DRB: deleting requests would fail if any notification were still pending

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

