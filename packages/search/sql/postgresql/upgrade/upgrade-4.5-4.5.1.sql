-- packages/search/sql/postgresql/upgrade/upgrade-4.2-4.5.sql
--
-- @author jon@jongriffi.com
-- @creation-date 2002-08-02
-- @cvs-id $Id$
--

-- search-packages-create.sql

drop function search_observer__dequeue(integer,timestamp with time zone,varchar);



-- added
select define_function_args('search_observer__dequeue','object_id,event_date,event');

--
-- procedure search_observer__dequeue/3
--
CREATE OR REPLACE FUNCTION search_observer__dequeue(
   p_object_id integer,
   p_event_date timestamp with time zone,
   p_event varchar
) RETURNS integer AS $$
DECLARE
BEGIN

    delete from search_observer_queue
    where object_id = p_object_id
    and event = p_event
    and event_date = p_event_date;

    return 0;

END;
$$ LANGUAGE plpgsql;

-- 

alter table search_observer_queue rename column date to event_date;




