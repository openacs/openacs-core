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
-- Create ctxsys schema objects for .LRN site-wide search
--
-- @author <a href="mailto:openacs@dirkgomez.de">openacs@dirkgomez.de</a>
-- @version $Id$
-- @creation-date 13-May-2005
--
-- Partly ported from ACES.

CREATE OR replace procedure sws_user_proc_&1 ( rid IN ROWID, tlob IN OUT nocopy clob )
AS
BEGIN
   &1..sws_user_datastore_proc(rid, tlob);
END;
/
show errors;

grant execute on sws_user_proc_&1 to &1;

grant ctxapp to &1;

-- stuff to make interMedia faster
exec ctx_adm.set_parameter('max_index_memory', '1G');

exit;
