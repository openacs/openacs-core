--
-- packages/acs-subsite/sql/portraits-drop.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-02-02
-- @cvs-id $Id$
--

drop table user_portraits;
drop package user_portrait_rel;

begin
  acs_rel_type.drop_type('user_portrait_rel');
end;
/
show errors
