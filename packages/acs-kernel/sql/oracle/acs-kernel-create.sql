--
-- /packages/acs-kernel/sql/acs-kernel-create.sql
--
-- Load the entire ACS Core package's data model
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @creation-date 2000/07/29
-- @cvs-id $Id$
--

set feedback off

@@ acs-logs-create
@@ acs-metadata-create
@@ acs-objects-create
@@ acs-object-util
@@ acs-relationships-create
@@ utilities-create
@@ community-core-create
@@ groups-create
@@ rel-segments-create
@@ rel-constraints-create
@@ groups-body-create
@@ rel-segments-body-create
@@ rel-constraints-body-create
@@ acs-permissions-create
@@ security-create
@@ journal-create
@@ site-nodes-create
@@ apm-create
@@ acs-create

-- added by Ben for OpenACS
@@ acs-create-2

set feedback on
