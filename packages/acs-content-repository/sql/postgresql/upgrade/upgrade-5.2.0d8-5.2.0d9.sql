-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2004-12-29
-- @arch-tag: 9b265639-f2f6-49ad-9ca6-d4688b162a8e
-- @cvs-id $Id$
--
-- set default for creation_date

select define_function_args('content_template__new','name,parent_id,template_id,creation_date;now,creation_user,creation_ip');