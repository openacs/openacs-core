--
-- /packages/acs-kernel/sql/utilities-drop.sql
--
-- Purges useful PL/SQL utility routines.
--
-- @author Jon Salz (jsalz@mit.edu)
-- @creation-date 12 Aug 2000
-- @cvs-id utilities-drop.sql,v 1.2 2000/09/19 07:23:29 ron Exp
--
\t
select drop_package('util');
\t
