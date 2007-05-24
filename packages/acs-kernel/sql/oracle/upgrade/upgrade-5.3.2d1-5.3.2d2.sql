-- 
-- packages/acs-kernel/sql/oracle/upgrade/upgrade-5.3.2d1-5.3.2d2.sql
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2007-05-24
-- @cvs-id $Id$
--

alter table apm_parameters drop constraint apm_parameter_datatype_ck;
alter table apm_parameters add constraint apm_parameter_datatype_ck check(datat\
ype in ('number', 'string','text'));