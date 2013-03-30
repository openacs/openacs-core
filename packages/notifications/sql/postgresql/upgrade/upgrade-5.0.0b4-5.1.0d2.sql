select define_function_args ('notification_request__delete_all_for_user', 'user_id');



--
-- procedure notification_request__delete_all_for_user/1
--
CREATE OR REPLACE FUNCTION notification_request__delete_all_for_user(
   p_user_id integer
) RETURNS integer AS $$
DECLARE
    v_request                       RECORD;
BEGIN
    for v_request in select request_id
                     from notification_requests
                     where user_id= p_user_id
    loop
        perform notification_request__delete(v_request.request_id);
    end loop;

    return 0;
END;

$$ LANGUAGE plpgsql;
