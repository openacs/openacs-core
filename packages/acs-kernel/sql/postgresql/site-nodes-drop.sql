--
-- packages/acs-kernel/sql/site-nodes-drop.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-09-06
-- @cvs-id site-nodes-drop.sql,v 1.5 2000/10/24 22:26:20 bquinn Exp
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
