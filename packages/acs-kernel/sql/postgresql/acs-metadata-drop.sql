--
-- acs-kernel/sql/acs-metadata-drop.sql
--
-- DDL commands to purge the Community Core data model
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @creation-date 2000-05-18
-- @cvs-id acs-metadata-drop.sql,v 1.5.2.1 2001/01/12 23:05:13 oumi Exp
--
\t
select drop_package('acs_attribute');
select drop_package('acs_object_type');
\t
drop view acs_object_type_attributes;
drop table acs_attribute_descriptions;
drop table acs_enum_values;
drop table acs_attributes;
drop view acs_attribute_id_seq;
drop sequence t_acs_attribute_id_seq;
drop table acs_datatypes;
drop table acs_object_type_tables;
drop view acs_object_type_supertype_map;
drop table acs_object_types;
