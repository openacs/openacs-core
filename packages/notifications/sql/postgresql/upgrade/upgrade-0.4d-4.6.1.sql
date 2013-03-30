-- DRB: deleting requests would fail if any notification were still pending



-- added
select define_function_args('notification_request__delete','request_id');

--
-- procedure notification_request__delete/1
--
CREATE OR REPLACE FUNCTION notification_request__delete(
   p_request_id integer
) RETURNS integer AS $$
DECLARE
    v_notifications record;
BEGIN
    for v_notifications in select notification_id
                           from notifications n, notification_requests nr
                           where n.response_id = nr.object_id
                             and nr.request_id = p_request_id
    loop
      perform acs_object__delete(v_notifications.notification_id);
    end loop;

    perform acs_object__delete(p_request_id);
    return 0;
END;

$$ LANGUAGE plpgsql;

