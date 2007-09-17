-- 
-- packages/acs-content-repository/sql/postgresql/upgrade/upgrade-5.4.0d6-5.4.0d7.sql
-- 
-- @author Malte Sussdorff (malte.sussdorff@cognovis.de)
-- @creation-date 2007-09-07
-- @cvs-id $Id$
--

select define_function_args('content_type__drop_type','content_type,drop_children_p;f,drop_table_p;f,drop_objects_p;f');