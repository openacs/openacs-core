--
-- acs-kernel/sql/community-core-drop.sql
--
-- DDL commands to purge the Community Core data model
--
-- @author Michael Yoon (michael@arsdigita.com)
-- @creation-date 2000-05-18
-- @cvs-id $Id$
--

-- We need to drop the circular creation_user and modifying_user
-- references before we can drop the users table.
--
\t
alter table acs_objects drop constraint acs_objects_creation_user_fk;
alter table acs_objects drop constraint acs_objects_modifying_user_fk;

select drop_package('acs_user');
drop table user_preferences;
drop table users;

select drop_package('person');
drop table persons;

select drop_package('party');
drop table parties;
\t
