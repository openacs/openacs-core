--
-- packages/acs-kernel/sql/rel-segments-drop.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-11-22
-- @cvs-id $Id$


begin
    for r in (select segment_id from rel_segments) loop
	rel_segment.del(r.segment_id);
    end loop;

    acs_object_type.drop_type('rel_segment');
end;
/
show errors


drop view party_element_map;
drop view party_approved_member_map;
drop view party_member_map;
drop view rel_seg_distinct_member_map;
drop view rel_seg_approved_member_map;
drop view rel_segment_member_map;
drop view rel_segment_distinct_party_map;
drop view rel_segment_party_map;
drop index rel_segments_rel_type_idx;
drop table rel_segments;
drop package rel_segment;
