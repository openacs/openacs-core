--
-- packages/acs-kernel/sql/acs-drop.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-08-22
-- @cvs-id acs-drop.sql,v 1.5 2000/10/24 22:26:18 bquinn Exp
--

drop view cc_users;
drop view registered_users;
\t
select drop_package('acs');
\t
drop table acs_magic_objects;
