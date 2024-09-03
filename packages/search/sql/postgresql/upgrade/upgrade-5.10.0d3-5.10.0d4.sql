--
-- procedure search_observer__enqueue/2
--
select define_function_args('search_observer__enqueue','object_id,event');

CREATE OR REPLACE FUNCTION search_observer__enqueue(
   p_object_id integer,
   p_event varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    --
    -- We see cases, where the object to be removed from the observer
    -- queue does not exist anymore. Probably, this is due to some
    -- race condition.
    --
    if p_event = 'DELETE' then

      IF NOT EXISTS (select 1 from acs_objects where object_id = p_object_id) then
         return 0;
      end if;

    end if;

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
