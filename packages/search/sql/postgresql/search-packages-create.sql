-- Search Observer Package
--
-- @cvs-id $Id$ 



--
-- procedure search_observer__enqueue/2
--
CREATE OR REPLACE FUNCTION search_observer__enqueue(
   p_object_id integer,
   p_event varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    insert into search_observer_queue (
	object_id,
	event
    ) values (
        p_object_id,
	p_event
    );

    return 0;

END;
$$ LANGUAGE plpgsql;

select define_function_args('search_observer__enqueue','object_id,event');



--
-- procedure search_observer__dequeue/3
--
CREATE OR REPLACE FUNCTION search_observer__dequeue(
   p_object_id integer,
   p_event_date timestamptz,
   p_event varchar
) RETURNS integer AS $$
DECLARE
BEGIN

    delete from search_observer_queue 
    where object_id = p_object_id 
    and event = p_event
    and to_char(event_date,'yyyy-mm-dd hh24:mi:ss.us-tz') = to_char(p_event_date,'yyyy-mm-dd hh24:mi:ss.us-tz');

    return 0;

END;
$$ LANGUAGE plpgsql;

select define_function_args('search_observer__dequeue','object_id,event_date,event');

