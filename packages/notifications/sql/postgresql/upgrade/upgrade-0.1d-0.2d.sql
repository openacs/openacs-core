drop function notification__delete;



-- added
select define_function_args('notification__delete','notification_id');

--
-- procedure notification__delete/1
--
CREATE OR REPLACE FUNCTION notification__delete(
   p_notification_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from notifications where notification_id = p_notification_id;
    perform acs_object__delete(p_notification_id);
    return 0;
END;

$$ LANGUAGE plpgsql;

