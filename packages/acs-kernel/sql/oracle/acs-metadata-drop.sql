--
-- acs-kernel/sql/acs-metadata-drop.sql
--
-- DDL commands to purge the Community Core data model
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @creation-date 2000-05-18
-- @cvs-id $Id$
--

drop package acs_attribute;
drop package acs_object_type;
drop view acs_object_type_attributes;
drop table acs_attribute_descriptions;
drop table acs_enum_values;
drop table acs_attributes;
drop sequence acs_attribute_id_seq;
drop table acs_datatypes;
drop table acs_object_type_tables;
drop view acs_object_type_supertype_map;
drop table acs_object_types;
