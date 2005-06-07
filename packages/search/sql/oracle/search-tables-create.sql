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
-- Create database tables for .LRN site-wide search
--
-- @author <a href="mailto:openacs@dirkgomez.de">openacs@dirkgomez.de</a>
-- @version $Id$
-- @creation-date 13-May-2005
--
-- Partly ported from ACES.

-- Central table for site-wide search. 
create table site_wide_index (
	object_id		integer
                                        constraint sws_index_pk primary key
                                        constraint sws_index_fk references acs_objects(object_id) on delete cascade,
	object_name	     	varchar(4000),
	indexed_content	        clob,
	package_id		integer 
-- TODO Dirk: bring back not null constraint 
--		                     constraint swi_package_id_nn
--		                     not null
				     constraint swi_package_id_fk
                                     references apm_packages
                                     on delete cascade,
	datastore		char(1) not null,
        event_date                      date
                                        default sysdate,
        event                   varchar(6)
                                        constraint site_wide_index_event_ck
                                        check (event in ('INSERT','DELETE','UPDATE'))  
);

-- Intermedia sometimes is painful to debug, so I added a logging
-- mechanism which relies on Oracle's autonomous transactions: DML
-- statements are committed immediately so you can access this data
-- from a different session right away.

create table sws_log_messages (
  logmessage varchar2(4000),
  logtime    date default sysdate);

exit;
