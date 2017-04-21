--
-- packages/acs-kernel/sql/test/rel-segments-test.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-12-01
-- @cvs-id rel-segments-test.sql,v 1.1.4.1 2001/01/12 23:06:33 oumi Exp
--

-- set serveroutput on

create table groups_test_groups (
       group_id      integer,
       sorder        integer,
       gname         varchar(100)
);

create table groups_test_users (
       user_id     integer,
       sorder      integer,
       uname       varchar(100)
);

create table groups_test_segs (
       seg_id      integer,
       sorder      integer,
       sname       varchar(100)
);

-- creates blah_member_rel and yippie_member_rel relationships

\i rel-segments-test-types-create.sql




-- added
select define_function_args('rel_segment_test_check','segment_id,party_id,container_id');

--
-- procedure rel_segment_test_check/3
--
CREATE OR REPLACE FUNCTION rel_segment_test_check(
   test_check__segment_id integer,
   test_check__party_id integer,
   test_check__container_id integer
) RETURNS boolean AS $$
DECLARE
  v_pass_p                          boolean;
  str                               text;
BEGIN

  select count(*) > 0 into v_pass_p
  from rel_segment_party_map
  where segment_id = test_check__segment_id
  and party_id = test_check__party_id
  and container_id = test_check__container_id;

  if NOT v_pass_p then

      str := 'Row missing from rel_segment_party_map for' ||
                    ' segment ' || 
                    acs_object__name(test_check__segment_id) ||
                    ' (' || test_check__segment_id || ')' ||
                    ', party ' || 
                    acs_object__name(test_check__party_id) || 
                    ' (' || test_check__party_id || ')' ||
                    ', container ' || 
                    acs_object__name(test_check__container_id) || 
                    ' (' || test_check__container_id || ')';

      raise NOTICE '%', str;

      PERFORM acs_log__error('rel_segment_test_check', str);
  end if;


  return v_pass_p;

END;
$$ LANGUAGE plpgsql; 




--
-- procedure test_segs/0
--
CREATE OR REPLACE FUNCTION test_segs(

) RETURNS integer AS $$
DECLARE
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

  seg_G_blahs    integer;
  seg_E_yippies  integer;
  seg_F          integer;

  rel_id integer;
BEGIN
  -- Create the test groups.

  A := acs_group__new('A');
  B := acs_group__new('B');
  C := acs_group__new('C');
  D := acs_group__new('D');
  E := acs_group__new('E');
  F := acs_group__new('F');
  G := acs_group__new('G');

  insert into groups_test_groups values (A,1,'A');
  insert into groups_test_groups values (B,2,'B');
  insert into groups_test_groups values (C,3,'C');
  insert into groups_test_groups values (D,4,'D');
  insert into groups_test_groups values (E,5,'E');
  insert into groups_test_groups values (F,6,'F');  
  insert into groups_test_groups values (G,7,'G');

  -- Create the test members.
  joe   := acs_user__new('joe@asdf.com','Joe',
                         'Smith','assword','p');
  jane  := acs_user__new('jane@asdf.com','Jane',
                         'Smith','assword','p');
  bob   := acs_user__new('bob@asdf.com','Bob',
                         'Smith','assword','p');
  betty := acs_user__new('betty@asdf.com','Betty',
                         'Smith','assword','p');
  jack  := acs_user__new('jack@asdf.com','Jack',
                         'Smith','assword','p');
  jill  := acs_user__new('jill@asdf.com','Jill',
                         'Smith','assword','p');
  sven  := acs_user__new('sven@asdf.com','Sven',
                         'Smith','assword','p');
  stacy := acs_user__new('stacy@asdf.com','Stacy',
                         'Smith','assword','p');

  insert into groups_test_users values (joe,1,'joe');
  insert into groups_test_users values (jane,2,'jane');
  insert into groups_test_users values (bob,3,'bob');
  insert into groups_test_users values (betty,4,'betty');
  insert into groups_test_users values (jack,5,'jack');
  insert into groups_test_users values (jill,6,'jill');  
  insert into groups_test_users values (sven,7,'sven');
  insert into groups_test_users values (stacy,8,'stacy');

  -- Make a couple of compositions.

  rel_id := composition_rel__new(A, B);
  rel_id := composition_rel__new(A, C);
  rel_id := composition_rel__new(A, D);

  rel_id := composition_rel__new(E, A);
  rel_id := composition_rel__new(F, A);
  rel_id := composition_rel__new(G, A);

  -- Make a couple of memberships.

  rel_id := blah_member_rel__new(null, 'blah_member_rel', B, joe);
  rel_id := yippie_member_rel__new(null, 'yippie_member_rel', B, jane);
  rel_id := blah_member_rel__new(null, 'blah_member_rel', B, betty);
  rel_id := yippie_member_rel__new(null, 'yippie_member_rel', A, bob);
  rel_id := blah_member_rel__new(null, 'blah_member_rel', A, betty);
  rel_id := yippie_member_rel__new(null, 'yippie_member_rel', E, betty);

  -- define a few segments.

  -- the segment of all parties that are blah members of G
  seg_G_blahs := rel_segment__new(null,
                                  'rel_segment',
                                  now(),
                                  null,
                                  null,
                                  null,
                                  null,                                  
                                  'Blahs of Group G',
                                  G, 
                                  'blah_member_rel',
                                  null
                 );

  -- the segment of all parties that are yippie members of E
  seg_E_yippies := rel_segment__new(null,
                                  'rel_segment',
                                  now(),
                                  null,
                                  null,
                                  null,
                                  null,
                                  'Yippies of Group E',
                                  E, 
                                  'yippie_member_rel',
                                  null
                  );

  seg_F := rel_segment__get_or_new(F,'membership_rel',null);

  insert into groups_test_segs values (seg_G_blahs,1,'seg_G_blahs');
  insert into groups_test_segs values (seg_E_yippies,2,'seg_E_yippies');
  insert into groups_test_segs values (seg_F,3,'seg_F');

  delete from acs_logs;

  return null;

END;
$$ LANGUAGE plpgsql;



--
-- procedure check_segs/0
--
CREATE OR REPLACE FUNCTION check_segs(

) RETURNS integer AS $$
DECLARE
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

  seg_G_blahs    integer;
  seg_E_yippies  integer;
  seg_F          integer;

  rel_id integer;
  r      record;
  str    varchar;
BEGIN

  select group_id into A from groups_test_groups where gname = 'A';
  select group_id into B from groups_test_groups where gname = 'B';
  select group_id into C from groups_test_groups where gname = 'C';
  select group_id into D from groups_test_groups where gname = 'D';
  select group_id into E from groups_test_groups where gname = 'E';
  select group_id into F from groups_test_groups where gname = 'F';
  select group_id into G from groups_test_groups where gname = 'G';

  select user_id into joe   from groups_test_users where uname = 'joe';
  select user_id into jane  from groups_test_users where uname = 'jane';
  select user_id into bob   from groups_test_users where uname = 'bob';
  select user_id into betty from groups_test_users where uname = 'betty';
  select user_id into jack  from groups_test_users where uname = 'jack';
  select user_id into jill  from groups_test_users where uname = 'jill';
  select user_id into sven  from groups_test_users where uname = 'sven';
  select user_id into stacy from groups_test_users where uname = 'stacy';

  select seg_id into seg_G_blahs  
    from groups_test_segs 
   where sname = 'seg_G_blahs';

  select seg_id into seg_E_yippies 
    from groups_test_segs 
   where sname = 'seg_E_yippies';

  select seg_id into seg_F 
    from groups_test_segs 
   where sname = 'seg_F';

--  group_element_index_dump;
--  rel_segment_party_map_dump;


  -- Expectations:
  --   1. seg_G_blahs should include joe and betty
  --   2. seg_E_yippies should include bob, and jane, betty

  -- check: seg_G_blahs contains joe with container B
  if rel_segment_test_check(seg_G_blahs, joe, B) = 'f' then
    str := 'Segment ' || acs_object__name(seg_G_blahs) || 
                         '(' || seg_G_blahs || ') failed.   Group_id = ' 
                         || G;
    raise NOTICE '%', str; 
  end if;

  -- check: seg_G_blahs contains betty with container B
  if rel_segment_test_check(seg_G_blahs, betty, B) = 'f' then
    str := 'Segment ' || acs_object__name(seg_G_blahs) || 
                         '(' || seg_G_blahs || ') failed.  Group_id = ' 
                         || G;
    raise NOTICE '%', str; 
  end if;

  -- check: seg_G_blahs contains betty with container A
  if rel_segment_test_check(seg_G_blahs, betty, A) = 'f' then
    str := 'Segment ' || acs_object__name(seg_G_blahs) || 
                         '(' || seg_G_blahs || ') failed.  Group_id = ' 
                         || G;
    raise NOTICE '%', str; 
  end if;

  -- check: seg_E_yippies contains jane with container B
  if rel_segment_test_check(seg_E_yippies, jane, B) = 'f' then
    str := 'Segment ' || acs_object__name(seg_E_yippies) || 
                         '(' || seg_E_yippies || ') failed.  Group_id = ' 
                         || E;
    raise NOTICE '%', str; 
  end if;

  -- check: seg_E_yippies contains bob with container A
  if rel_segment_test_check(seg_E_yippies, bob, A) = 'f' then
    str := 'Segment ' || acs_object__name(seg_E_yippies) || 
                         '(' || seg_E_yippies || ') failed. Group_id = ' 
                         || E;
    raise NOTICE '%', str; 
  end if;

  -- check: seg_E_yippies contains betty with container E
  if rel_segment_test_check(seg_E_yippies, betty, E) = 'f' then
    str := 'Segment ' || acs_object__name(seg_E_yippies) || 
                         '(' || seg_E_yippies || ') failed. Group_id = ' 
                         || E;
    raise NOTICE '%', str; 
  end if;

  -- Now we test on-the-fly creation of rel-segments with the get_or_new
  -- function:

  -- The segment of all memers of F should contain jane through group B
  if rel_segment_test_check(seg_F, jane, B) = 'f' then
    str := 'Segment ' || 
                 acs_object__name(rel_segment__get(F,'membership_rel')) || 
                 '(' || rel_segment__get(F,'membership_rel') 
                 || ') failed. Group_id = ' || F;
    raise NOTICE '%', str; 
  end if;

  -- The segment of all memers of F should contain betty through group A
  if rel_segment_test_check(seg_F, betty, A) = 'f' then
    str := 'Segment ' || 
                 acs_object__name(rel_segment__get(F,'membership_rel')) || 
                 '(' || rel_segment__get(F,'membership_rel') 
                 || ') failed. Group_id = ' || A;
    raise NOTICE '%', str; 
  end if;

  -- Remove the test segments.
  PERFORM rel_segment__delete(seg_G_blahs);
  PERFORM rel_segment__delete(seg_E_yippies);
  PERFORM rel_segment__delete(rel_segment__get(F,'membership_rel'));

  -- Remove the test membership relations
  for r in select * from blah_member_rels LOOP
    PERFORM blah_member_rel__delete(r.rel_id);
  end loop;

  for r in select * from yippie_member_rels LOOP
    PERFORM yippie_member_rel__delete(r.rel_id);
  end loop;

  -- Remove the test groups.
  PERFORM acs_group__delete(G);
  PERFORM acs_group__delete(F);
  PERFORM acs_group__delete(E);
  PERFORM acs_group__delete(D);
  PERFORM acs_group__delete(C);
  PERFORM acs_group__delete(B);
  PERFORM acs_group__delete(A);

  -- Remove the test members.
  PERFORM acs_user__delete(joe);
  PERFORM acs_user__delete(jane);
  PERFORM acs_user__delete(bob);
  PERFORM acs_user__delete(betty);
  PERFORM acs_user__delete(jack);
  PERFORM acs_user__delete(jill);
  PERFORM acs_user__delete(sven);
  PERFORM acs_user__delete(stacy);

  return null;

END;
$$ LANGUAGE plpgsql;

select test_segs();
select check_segs();

drop function rel_segment_test_check(integer, integer, integer);
drop function test_segs();
drop function check_segs();
drop table groups_test_groups;
drop table groups_test_users;
drop table groups_test_segs;

\i rel-segments-test-types-drop.sql

select log_level, log_key, message
from acs_logs
where log_level = 'error';

