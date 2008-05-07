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
-- Create the intermedia index for .LRN site-wide search
--
-- @author <a href="mailto:openacs@dirkgomez.de">openacs@dirkgomez.de</a>
-- @version $Id$
-- @creation-date 13-May-2005
--
-- Partly ported from ACES.

-- create section groups for within clauses
begin
  ctx_ddl.create_section_group('swsgroup', 'basic_section_group');
  ctx_ddl.add_field_section('swsgroup', 'oneline', 'oneline', TRUE);
end;
/
create index swi_index on site_wide_index (indexed_content)
indextype is ctxsys.context parameters ('datastore ctxsys.default_datastore memory 250M');


-- create intermedia index for site wide index
begin
  ctx_ddl.create_preference('sws_user_datastore', 'user_datastore');
  ctx_ddl.set_attribute('sws_user_datastore', 'procedure', 'sws_user_proc_&1');
end;
/


exit;