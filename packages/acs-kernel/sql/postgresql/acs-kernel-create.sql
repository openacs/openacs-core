--
-- /packages/acs-kernel/sql/acs-kernel-create.sql
--
-- Load the entire ACS Core package's data model
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @creation-date 2000/07/29
-- @cvs-id $Id$
--

--\set ECHO queries
\set VERBOSITY 'verbose'

\i postgresql.sql
\i lob.sql
\i acs-logs-create.sql
\i acs-metadata-create.sql
\i acs-objects-create.sql
\i acs-object-util.sql
\i acs-relationships-create.sql
\i utilities-create.sql
\i authentication-create.sql
\i community-core-create.sql
\i groups-create.sql
\i rel-segments-create.sql
\i rel-constraints-create.sql
\i acs-permissions-create.sql
\i groups-body-create.sql
\i rel-segments-body-create.sql
\i rel-constraints-body-create.sql
\i security-create.sql
\i journal-create.sql
\i site-nodes-create.sql
\i site-node-object-map-create.sql
\i apm-create.sql

\i acs-create.sql
\i acs-create-2.sql

-- set feedback on
