drop function notification__delete;

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

