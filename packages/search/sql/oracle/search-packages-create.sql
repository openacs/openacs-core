--
--  Copyright (C) 2005 MIT
--
--  This file is part of dotLRN.
--
--  dotLRN is free software; you can redistribute it and/or modify it under the
--  terms of the GNU General Public License as published by the Free Software
--  Foundation; either version 2 of the License, or (at your option) any later
--  version.
--
--  dotLRN is distributed in the hope that it will be useful, but WITHOUT ANY
--  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
--  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
--  details.
--

--
-- Create database packages for .LRN site-wide search
--
-- @author <a href="mailto:openacs@dirkgomez.de">Dirk Gomez</a>
-- @version $Id$
-- @creation-date 13-May-2005

-- Partly ported from ACES.

-- The site_wide_search packages holds generally useful
-- PL/SQL procedures and functions.

create or replace package search_observer
as
  procedure enqueue (
	object_id 	acs_objects.object_id%TYPE,
	event		search_observer_queue.event%TYPE
);
  procedure dequeue (
        object_id acs_objects.object_id%TYPE, event
	search_observer_queue.event%TYPE, event_date
	search_observer_queue.event_date%TYPE
);
end search_observer;
/
show errors

create or replace package body search_observer
as
  procedure enqueue (
	object_id 	acs_objects.object_id%TYPE,
	event		search_observer_queue.event%TYPE
) is
begin
    insert into search_observer_queue (
	object_id,
	event
    ) values (
        enqueue.object_id,
	enqueue.event
    );

  end enqueue;

  procedure dequeue (
	object_id 	acs_objects.object_id%TYPE,
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
show errors

