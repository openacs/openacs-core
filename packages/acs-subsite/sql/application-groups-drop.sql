--
-- packages/acs-subsite/sql/application-groups-drop.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-02-02
-- @cvs-id $Id$
--

delete from group_type_rels where rel_type = 'application_group';

drop table application_groups;
drop package application_group;

begin
  acs_object_type.drop_type('application_group');
end;
/
show errors

drop view application_group_element_map;
drop view application_users;
drop view registered_users_for_package_id;
drop view cc_users_for_package_id;