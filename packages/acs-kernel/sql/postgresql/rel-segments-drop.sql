--
-- packages/acs-kernel/sql/rel-segments-drop.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-11-22
-- @cvs-id rel-segments-drop.sql,v 1.1.4.1 2001/01/12 22:58:51 mbryzek Exp
\t
create function inline_0 ()
declare 
        r       record;
begin
    for r in select segment_id from rel_segments 
    LOOP
	PERFORM rel_segment__delete(r.segment_id);
    end loop;

    PERFORM acs_object_type__drop_type(''rel_segment'');
    return null;
end;' language 'plpgsql';
select inline_0 ();

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
select drop_package('rel_segment');
\t
