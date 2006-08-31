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
-- Populate .LRN's intermedia index
--
-- @author <a href="mailto:openacs@dirkgomez.de">Dirk Gomez</a>
-- @version $Id$
-- @creation-date 13-May-2005
--

truncate table search_observer_queue;

insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('cal_item') ;
commit;
     
insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects, cr_items where object_id=live_revision and object_type in ('file_storage_object') ;
commit;

insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('static_portal_content');
commit;

insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('forums_message') ;
commit;

insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('forums_forum') ;
commit;

insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects, cr_items, cr_news where news_id=live_revision and object_id=live_revision and object_type in ('news');
-- and archive_date is null;
commit;

insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('faq') ;
commit;

insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects where object_type in ('survey');
commit;

insert into search_observer_queue (object_id, event) select object_id, 'INSERT' from acs_objects,cr_items where object_type in ('phb_person') and object_id=live_revision ;
commit;


--alter index swi_index rebuild parameters ('sync') ;
