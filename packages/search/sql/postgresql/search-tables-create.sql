create table search_observer_queue (
    object_id		   integer
			   constraint search_observer_queue_object_id_fk 
			   references acs_objects(object_id),
    date		   timestamp default now(),
    event		   varchar(6)
			   constraint search_observer_queue_event_ck
			   check (event in ('INSERT','DELETE','UPDATE')),
    constraint search_observer_queue_oid_date_un unique(object_id,date)   
);
