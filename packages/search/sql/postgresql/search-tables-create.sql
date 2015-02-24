create table search_observer_queue (
    object_id		   integer not null
                           references acs_objects(object_id) on delete cascade,
    event_date		   timestamptz default current_timestamp,
    event		   varchar(6)
			   constraint search_observer_queue_event_ck
			   check (event in ('INSERT','DELETE','UPDATE'))  
);


