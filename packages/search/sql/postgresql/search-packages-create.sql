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


create function search_observer__dequeue(integer,timestamp,varchar)
returns integer as '
declare
    p_object_id			alias for $1;
    p_date			alias for $2;
    p_event			alias for $3;
begin

    delete from search_observer_queue 
    where object_id = p_object_id 
    and date =p_date
    and event = p_event;

    return 0;

end;' language 'plpgsql';
