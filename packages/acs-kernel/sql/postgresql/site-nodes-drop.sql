--
-- packages/acs-kernel/sql/site-nodes-drop.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-09-06
-- @cvs-id $Id$
--

\t
select drop_package('site_node');
drop table site_nodes;

create function inline_0 () returns integer as '
begin
  PERFORM acs_object_type__drop_type (''site_node'');
  returns null;
end;' language 'plpgsql';
select inline_0 ();
drop function inline_0 ();
\t
