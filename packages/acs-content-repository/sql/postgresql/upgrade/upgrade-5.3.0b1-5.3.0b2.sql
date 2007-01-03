-- 
-- packages/acs-content-repository/sql/postgresql/upgrade/upgrade-5.3.0b1-5.3.0b2.sql
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2007-01-03
-- @cvs-id $Id$
--

update cr_revisions set content = '<html><body>@text;noquote@</body></html>' where revision_id = (select template_id from cr_type_template_map where content_type = 'content_revision' and use_context = 'public' and is_default = 't');
