drop table notification_replies;

CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN

    perform acs_object_type__drop_type(
        'notification_reply', 'f'
    );

    return null;

END;
$$ LANGUAGE plpgsql;

select inline_0();
drop function inline_0();
