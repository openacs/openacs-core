drop table notification_replies;

create function inline_0 ()
returns integer as '
begin

    perform acs_object_type__drop_type(
        ''notification_reply'', ''f''
    );

    return null;

end;' language 'plpgsql';

select inline_0();
drop function inline_0();
