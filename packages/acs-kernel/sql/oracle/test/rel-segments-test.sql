--
-- packages/acs-kernel/sql/test/rel-segments-test.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-12-01
-- @cvs-id $Id$
--

set serveroutput on

-- creates blah_member_rel and yippe_member_rel relationships
@rel-segments-test-types-create.sql


create or replace function rel_segment_test_check (
  segment_id              integer,
  party_id              integer,
  container_id          integer
) return char
is
  v_pass_p char(1);
begin

  select decode(count(*), 0, 'f', 't') into v_pass_p
  from rel_segment_party_map
  where segment_id = rel_segment_test_check.segment_id
  and party_id = rel_segment_test_check.party_id
  and container_id = rel_segment_test_check.container_id;

  if v_pass_p = 'f' then

      dbms_output.put_line('Row missing from rel_segment_party_map for' ||
                    ' segment ''' || acs_object.name(segment_id) ||
                    ''' (' || segment_id || ')' ||
                    ', party ''' || acs_object.name(party_id) || 
                    ''' (' || party_id || ')' ||
                    ', container ''' || acs_object.name(container_id) || 
                    ''' (' ||container_id || ')');

      acs_log.error('rel_segment_test_check',
                    'Row missing from rel_segment_party_map for' ||
                    ' segment ''' || acs_object.name(segment_id) || 
                    ''' (' || segment_id || ')' ||
                    ', party ''' || acs_object.name(party_id) || 
                    ''' (' || party_id || ')' ||
                    ', container ''' || acs_object.name(container_id) || 
                    ''' (' ||container_id || ')');
  end if;


  return v_pass_p;

end;
/
show errors


declare
  A      integer;
  B      integer;
  C      integer;
  D      integer;
  E      integer;
  F      integer;
  G      integer;

  joe    integer;
  jane   integer;
  bob    integer;
  betty  integer;
  jack	 integer;
  jill	 integer;
  sven	 integer;
  stacy	 integer;

  seg_G_blahs   integer;
  seg_E_yippes  integer;

  rel_id integer;
begin
  -- Create the test groups.
  A := acs_group.new(group_name => 'A');
  B := acs_group.new(group_name => 'B');
  C := acs_group.new(group_name => 'C');
  D := acs_group.new(group_name => 'D');
  E := acs_group.new(group_name => 'E');
  F := acs_group.new(group_name => 'F');
  G := acs_group.new(group_name => 'G');

  -- Create the test members.
  joe   := acs_user.new(email => 'joe@asdf.com',
	                first_names => 'Joe', last_name => 'Smith',
		        password => 'assword', salt => 'p');
  jane  := acs_user.new(email => 'jane@asdf.com',
	                first_names => 'Jane', last_name => 'Smith',
		        password => 'assword', salt => 'p');
  bob   := acs_user.new(email => 'bob@asdf.com',
	                first_names => 'Bob', last_name => 'Smith',
		        password => 'assword', salt => 'p');
  betty := acs_user.new(email => 'betty@asdf.com',
	                first_names => 'Betty', last_name => 'Smith',
		        password => 'assword', salt => 'p');
  jack  := acs_user.new(email => 'jack@asdf.com',
	                first_names => 'Jack', last_name => 'Smith',
		        password => 'assword', salt => 'p');
  jill  := acs_user.new(email => 'jill@asdf.com',
	                first_names => 'Jill', last_name => 'Smith',
		        password => 'assword', salt => 'p');
  sven  := acs_user.new(email => 'sven@asdf.com',
	                first_names => 'Sven', last_name => 'Smith',
		        password => 'assword', salt => 'p');
  stacy := acs_user.new(email => 'stacy@asdf.com',
	                first_names => 'Stacy', last_name => 'Smith',
		        password => 'assword', salt => 'p');

  -- Make a couple of compositions.

  rel_id := composition_rel.new(object_id_one => A, object_id_two => B);
  rel_id := composition_rel.new(object_id_one => A, object_id_two => C);
  rel_id := composition_rel.new(object_id_one => A, object_id_two => D);

  rel_id := composition_rel.new(object_id_one => E, object_id_two => A);
  rel_id := composition_rel.new(object_id_one => F, object_id_two => A);
  rel_id := composition_rel.new(object_id_one => G, object_id_two => A);

  -- Make a couple of memberships.

  rel_id := blah_member_rel.new(object_id_one => B, object_id_two => joe);
  rel_id := yippe_member_rel.new(object_id_one => B, object_id_two => jane);
  rel_id := blah_member_rel.new(object_id_one => B, object_id_two => betty);
  rel_id := yippe_member_rel.new(object_id_one => A, object_id_two => bob);
  rel_id := blah_member_rel.new(object_id_one => A, object_id_two => betty);
  rel_id := yippe_member_rel.new(object_id_one => E, object_id_two => betty);


  -- define a few segments.

  -- the segment of all parties that are blah members of G
  seg_G_blahs := acs_rel_segment.new(segment_name => 'Blahs of Group G',
                                     group_id => G, 
                                     rel_type => 'blah_member_rel');

  -- the segment of all parties that are yippe members of E
  seg_E_yippes := acs_rel_segment.new(segment_name => 'Yippes of Group E',
                                      group_id => E, 
                                      rel_type => 'yippe_member_rel');


  delete from acs_logs;


--  group_element_index_dump;
--  rel_segment_party_map_dump;



  -- Expectations:
  --   1. seg_G_blahs should include joe and betty
  --   2. seg_E_yippes should include bob, and jane, betty

  -- check: seg_G_blahs contains joe with container B
  if rel_segment_test_check(seg_G_blahs, joe, B) = 'f' then
    dbms_output.put_line('Segment ' || acs_object.name(seg_G_blahs) || 
                         '(' || seg_G_blahs || ') failed.   Group_id = ' || G);
  end if;

  -- check: seg_G_blahs contains betty with container B
  if rel_segment_test_check(seg_G_blahs, betty, B) = 'f' then
    dbms_output.put_line('Segment ' || acs_object.name(seg_G_blahs) || 
                         '(' || seg_G_blahs || ') failed.  Group_id = ' || G);
  end if;

  -- check: seg_G_blahs contains betty with container A
  if rel_segment_test_check(seg_G_blahs, betty, A) = 'f' then
    dbms_output.put_line('Segment ' || acs_object.name(seg_G_blahs) || 
                         '(' || seg_G_blahs || ') failed.  Group_id = ' || G);
  end if;

  -- check: seg_E_yippes contains jane with container B
  if rel_segment_test_check(seg_E_yippes, jane, B) = 'f' then
    dbms_output.put_line('Segment ' || acs_object.name(seg_E_yippes) || 
                         '(' || seg_E_yippes || ') failed.  Group_id = ' || E);
  end if;

  -- check: seg_E_yippes contains bob with container A
  if rel_segment_test_check(seg_E_yippes, bob, A) = 'f' then
    dbms_output.put_line('Segment ' || acs_object.name(seg_E_yippes) || 
                         '(' || seg_E_yippes || ') failed. Group_id = ' || E);
  end if;

  -- check: seg_E_yippes contains betty with container E
  if rel_segment_test_check(seg_E_yippes, betty, E) = 'f' then
    dbms_output.put_line('Segment ' || acs_object.name(seg_E_yippes) || 
                         '(' || seg_E_yippes || ') failed. Group_id = ' || E);
  end if;

  -- Now we test on-the-fly creation of rel-segments with the get_or_new
  -- function:

  -- The segment of all memers of F should contain jane through group B
  if rel_segment_test_check(
          acs_rel_segment.get_or_new(F,'membership_rel'), jane, B) = 'f' then
    dbms_output.put_line('Segment ' || 
                 acs_object.name(acs_rel_segment.get(F,'membership_rel')) || 
                 '(' || acs_rel_segment.get(F,'membership_rel') 
                 || ') failed. Group_id = ' || F);
  end if;

  -- The segment of all memers of F should contain betty through group A
  if rel_segment_test_check(
          acs_rel_segment.get_or_new(F,'membership_rel'), betty, A) = 'f' then
    dbms_output.put_line('Segment ' || 
                 acs_object.name(acs_rel_segment.get(F,'membership_rel')) || 
                 '(' || acs_rel_segment.get(F,'membership_rel') 
                 || ') failed. Group_id = ' || A);
  end if;



  -- Remove the test segments.
  acs_rel_segment.del(seg_G_blahs);
  acs_rel_segment.del(seg_E_yippes);
  acs_rel_segment.del(acs_rel_segment.get(F,'membership_rel'));

  -- Remove the test membership relations
  for r in (select * from blah_member_rels) loop
    blah_member_rel.del(r.rel_id);
  end loop;

  for r in (select * from yippe_member_rels) loop
    yippe_member_rel.del(r.rel_id);
  end loop;


  -- Remove the test groups.
  acs_group.del(G);
  acs_group.del(F);
  acs_group.del(E);
  acs_group.del(D);
  acs_group.del(C);
  acs_group.del(B);
  acs_group.del(A);

  -- Remove the test members.
  acs_user.del(joe);
  acs_user.del(jane);
  acs_user.del(bob);
  acs_user.del(betty);
  acs_user.del(jack);
  acs_user.del(jill);
  acs_user.del(sven);
  acs_user.del(stacy);
end;
/
show errors


drop function rel_segment_test_check;

@rel-segments-test-types-drop.sql

select log_level, log_key, message
from acs_logs
where log_key = 'error';
