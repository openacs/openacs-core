--
-- packages/acs-kernel/sql/acs-permissions-drop.sql
--
-- @creation-date 2000-08-13
--
-- @author rhs@mit.edu
--
-- @cvs-id $Id$
--

--drop view acs_object_party_method_map;
drop view acs_object_party_privilege_map;
drop view acs_object_grantee_priv_map;
drop view acs_permissions_all;
drop view acs_privilege_descendant_map;
drop package acs_permission;
drop table acs_permissions;
--drop view acs_privilege_method_map;
--drop table acs_privilege_method_rules;
drop package acs_privilege;
drop table acs_privilege_hierarchy;
drop table acs_privileges;
--drop table acs_methods;
