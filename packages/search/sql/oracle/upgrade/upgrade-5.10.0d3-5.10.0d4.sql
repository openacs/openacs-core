create or replace package body search_observer
as
  procedure enqueue (
        object_id       acs_objects.object_id%TYPE,
        event		search_observer_queue.event%TYPE
) is
  l_count integer;
begin
    --
    -- We see cases, where the object to be removed from the observer
    -- queue does not exist anymore. Probably, this is due to some
    -- race condition.
    --

    if p_event = 'DELETE' then

      select count(*) from acs_objects into l_count
      where object_id = p_object_id;

      if l_count = 0 then
         return;
      end if;
    end if;

    insert into search_observer_queue (
        object_id,
        event
    ) values (
        enqueue.object_id,
        enqueue.event
    );

  end enqueue;

  procedure dequeue (
        object_id       acs_objects.object_id%TYPE,
        event		search_observer_queue.event%TYPE,
        event_date	search_observer_queue.event_date%TYPE
) is
  begin

    delete from search_observer_queue
    where object_id = dequeue.object_id
    and event = dequeue.event
    and to_char(dequeue.event_date,'yyyy-mm-dd hh24:mi:ss') = to_char(dequeue.event_date,'yyyy-mm-dd hh24:mi:ss');

  end dequeue;
end search_observer;
/
sh
