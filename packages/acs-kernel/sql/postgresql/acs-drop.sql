--
-- packages/acs-kernel/sql/acs-drop.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-08-22
-- @cvs-id $Id$
--

drop view cc_users;
drop view registered_users;
\t
select drop_package('acs');
\t
drop table acs_magic_objects;
