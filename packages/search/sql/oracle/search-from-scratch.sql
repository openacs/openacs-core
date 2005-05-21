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

truncate table site_wide_index;

insert into site_wide_index (object_id, object_name, datastore)
  select message_id, subject, 'a' from forums_messages;

insert into site_wide_index (object_id, object_name, datastore)
  select event_id, name, 'a' from acs_events;

insert into site_wide_index (object_id, object_name, datastore)
  select entry_id, question, 'a' from faq_q_and_as;

insert into site_wide_index (object_id, object_name, datastore)
  select content_id, pretty_name, 'a' from static_portal_content;

insert into site_wide_index (object_id, object_name, datastore)
  select survey_id, name, 'a' from surveys;

commit;

alter index sws_ctx_index rebuild parameters ('sync') ;

exit



