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
--
-- @author <a href="mailto:openacs@dirkgomez.de">openacs@dirkgomez.de</a>
-- @version $Id$
-- @creation-date 13-May-2005
--
-- Partly ported from ACES.


create table search_observer_queue (
    object_id                       integer,
    event_date                      date
                                    default sysdate,
    event                           varchar(6)
                                    constraint search_observer_queue_event_ck
                                    check (event in ('INSERT','DELETE','UPDATE'))  
);

-- Intermedia sometimes is painful to debug, so I added a logging
-- mechanism which relies on Oracle's autonomous transactions: DML
-- statements are committed immediately so you can access this data
-- from a different session right away.

create table sws_log_messages (
  logmessage varchar2(4000),
  logtime    date default sysdate);

