--
-- /packages/acs-kernel/sql/rel-constraints-drop.sql
-- 
-- @author Oumi Mehrotra
-- @creation-date 2000-11-22
-- @cvs-id $Id$


begin
acs_rel_type.drop_type('rel_constraint');
end;
/
show errors

drop view rel_constraints_violated_one;
drop view rel_constraints_violated_two;
drop view rc_required_rel_segments;
drop view rc_parties_in_required_segs;
drop view rc_violations_by_removing_rel;
drop table rel_constraints;
drop package rel_constraint;
