--
-- acs-kernel/sql/acs-objects-drop.sql
--
-- DDL commands to purge the ACS Objects data model
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @creation-date 2000-05-18
-- @cvs-id acs-objects-drop.sql,v 1.5 2000/10/24 22:26:18 bquinn Exp
--

\t
drop table general_objects;
select drop_package('acs_object');
drop table acs_static_attr_values;
drop table acs_attribute_values;
drop view acs_attribute_value_id_seq;
drop sequence t_acs_attribute_value_id_seq;
drop trigger acs_objects_context_id_del_tr;
drop trigger acs_objects_context_id_up_tr;
drop trigger acs_objects_context_id_in_tr;
drop view acs_object_contexts;
drop view acs_object_paths;
drop table acs_object_context_index;
drop trigger acs_objects_last_mod_update_tr;
drop trigger acs_objects_mod_ip_insert_tr;
drop table acs_objects;
drop view acs_objbect_id_seq;
drop sequence t_acs_object_id_seq;
\t
