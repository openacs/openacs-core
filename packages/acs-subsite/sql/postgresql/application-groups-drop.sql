--
-- packages/acs-subsite/sql/application-groups-drop.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-02-02
-- @cvs-id $Id$
--

delete from group_type_rels where rel_type = 'application_group';

drop view application_group_segments;
drop view app_group_distinct_rel_map;
drop view app_group_distinct_element_map;
drop view application_group_element_map;

select drop_package('application_group');
select acs_object_type__drop_type('application_group', 'f');

drop table application_groups;
