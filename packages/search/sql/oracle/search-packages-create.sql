--
-- Search Observer
--

create or replace package search_observer
as

    procedure enqueue (
        object_id in search_observer_queue.object_id%TYPE,
        event in search_observer_queue.event%TYPE
    );

    procedure dequeue (
        object_id in search_observer_queue.object_id%TYPE,
        event_date in search_observer_queue.event_date%TYPE,
        event in search_observer_queue.event%TYPE
    );

end search_observer;
/
show errors

create or replace package body search_observer
as

    procedure enqueue (
        object_id in search_observer_queue.object_id%TYPE,
        event in search_observer_queue.event%TYPE
    )
    is
    begin
    
        insert
        into search_observer_queue
        (object_id, event)
        values
        (enqueue.object_id, enqueue.event);

    end enqueue;

    procedure dequeue (
        object_id in search_observer_queue.object_id%TYPE,
        event_date in search_observer_queue.event_date%TYPE,
        event in search_observer_queue.event%TYPE
    )
    is
    begin
    
        delete
        from search_observer_queue 
        where object_id = dequeue.object_id 
        and event = dequeue.event
        and event_date = dequeue.event_date;
    
    end dequeue;

end search_observer;
/
show errors
