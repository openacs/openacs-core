--
-- packages/acs-kernel/sql/acs-permissions-drop.sql
--
-- @creation-date 2000-08-13
--
-- @author rhs@mit.edu
--
-- @cvs-id acs-permissions-drop.sql,v 1.5 2000/10/24 22:26:19 bquinn Exp
--

--drop view acs_object_party_method_map;
drop view acs_object_party_privilege_map;
drop view acs_object_grantee_priv_map;
drop view acs_permissions_all;
drop view acs_privilege_descendant_map;
\t
select drop_package('acs_permission');
drop table acs_permissions;
--drop view acs_privilege_method_map;
--drop table acs_privilege_method_rules;
select drop_package('acs_privilege');
\t
drop table acs_privilege_hierarchy;
drop table acs_privileges;
--drop table acs_methods;
