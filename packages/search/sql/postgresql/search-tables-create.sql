create table search_observer_queue (
    object_id		   integer,
    event_date		   timestamp default now(),
    event		   varchar(6)
			   constraint search_observer_queue_event_ck
			   check (event in ('INSERT','DELETE','UPDATE'))  
);
