--
-- packages/acs-kernel/sql/site-nodes-drop.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-09-06
-- @cvs-id $Id$
--

drop package site_node;
drop table site_nodes;

begin
  acs_object_type.drop_type ('site_node');
end;
/
show errors
