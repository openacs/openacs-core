--
-- Search Observer
--

create function search_observer__enqueue(integer,varchar)
returns integer as '
declare
    p_object_id			alias for $1;
    p_event			alias for $2;
begin
    insert into search_observer_queue (
	object_id,
	event
    ) values (
        p_object_id,
	p_event
    );

    return 0;

end;' language 'plpgsql';


create function search_observer__dequeue(integer,timestamptz,varchar)
returns integer as '
declare
    p_object_id                 alias for $1;
    p_event_date                alias for $2;
    p_event                     alias for $3;
begin

    delete from search_observer_queue 
    where object_id = p_object_id 
    and event = p_event
    and to_char(event_date,''yyyy-mm-dd hh24:mi:ss.us-tz'') = to_char(p_event_date,''yyyy-mm-dd hh24:mi:ss.us-tz'');

    return 0;

end;' language 'plpgsql';
