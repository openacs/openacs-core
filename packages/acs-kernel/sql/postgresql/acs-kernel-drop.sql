--
-- /packages/acs-kernel/sql/acs-kernel-drop.sql
--
-- Purge the entire ACS Core package's data model
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @creation-date 2000/07/29
-- @cvs-id $Id$
--

\i acs-drop.sql
\i journal-drop.sql
\i utilities-drop.sql
\i security-drop.sql
\i acs-permissions-drop.sql
\i rel-constraints-drop.sql
\i rel-segments-drop.sql
\i groups-drop.sql
\i site-node-object-map-drop.sql
\i site-nodes-drop.sql
\i community-core-drop.sql
\i authentication-drop.sql
\i acs-relationships-drop.sql
\i acs-object-util-remove.sql
\i acs-objects-drop.sql
\i acs-metadata-drop.sql
\i apm-drop.sql
\i acs-logs-drop.sql
