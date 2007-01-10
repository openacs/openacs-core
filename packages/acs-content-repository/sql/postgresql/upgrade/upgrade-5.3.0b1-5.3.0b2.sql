-- 
-- packages/acs-content-repository/sql/postgresql/upgrade/upgrade-5.3.0b1-5.3.0b2.sql
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2007-01-03
-- @cvs-id $Id$
--

update cr_revisions set content = '<html><body>@text;noquote@</body></html>' where revision_id = (select live_revision from cr_items ci, cr_type_template_map cm where cm.content_type = 'content_revision' and cm.use_context = 'public' and cm.is_default = 't' and ci.item_id=cm.template_id);
