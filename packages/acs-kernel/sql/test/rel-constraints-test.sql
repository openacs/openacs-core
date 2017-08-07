--
-- packages/acs-kernel/sql/test/rel-constraints-test.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-12-02
-- @cvs-id rel-constraints-test.sql,v 1.1.4.1 2001/01/12 23:06:33 oumi Exp
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

CREATE OR REPLACE FUNCTION rel_constraint_dump_views() RETURNS integer AS $$
       r        record;
       str      varchar;
BEGIN

   raise NOTICE 'Contents of view 'rel_constraints_violated_one':';

   for r in select * from rel_constraints_violated_one 
   LOOP
      str := rpad(r.constraint_id, 10) ||
             rpad(r.rel_id, 10) ||
             rpad(acs_object__name(r.container_id), 20) ||
             rpad(acs_object__name(r.party_id), 20);

      raise NOTICE '%', str;
   end LOOP;


   raise NOTICE 'Contents of view 'rel_constraints_violated_two':';

   for r in select * from rel_constraints_violated_two 
   LOOP
      str := rpad(r.constraint_id, 10) ||
             rpad(r.rel_id, 10) ||
             rpad(acs_object__name(r.container_id), 20) ||
             rpad(acs_object__name(r.party_id), 20);

      raise NOTICE '%', str;
   end loop;

   return null;

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('rel_constraint_test_check','rel_id,expect_violation_p');

--
-- procedure rel_constraint_test_check/2
--
CREATE OR REPLACE FUNCTION rel_constraint_test_check(
   rel_id integer,
   expect_violation_p boolean
) RETURNS integer AS $$
DECLARE
  v_violation_msg     varchar(4000);
  v_violation_p       boolean;
  v_object_id_one     integer;
  v_object_id_two     integer;
  v_rel_type          acs_rels.rel_type%TYPE;
  str                 varchar;
BEGIN

  v_violation_p := 'f';

  v_violation_msg := rel_constraint__violation(rel_id);

  if v_violation_msg is not null then
     v_violation_p := 't';
  end if;

  if v_violation_p != expect_violation_p then

      select object_id_one, object_id_two, rel_type
      into v_object_id_one, v_object_id_two, v_rel_type
      from acs_rels
      where rel_id = rel_constraint_test_check.rel_id;

      str :=        'Relation ' || acs_object_name(rel_id) || 
                    ' (' || rel_id || ')' ||
                    ' failed (violation_p = ' || v_violation_p || ').  ' ||
                    'Rel info: type = ' || v_rel_type || 
                    ', object one = ' ||
                    acs_object__name(v_object_id_one) || 
                    ' (' || v_object_id_one || ')' || 
                    ', object two = ' ||
                    acs_object__name(v_object_id_two) || 
                    ' (' || v_object_id_two || ').';

      PERFORM acs_log__error('rel_constraint_test_check', str);

      raise NOTICE '%', str;

      raise NOTICE 'Violation Message:';
      raise NOTICE '%', v_violation_msg;

  end if;

  return null;

END;
$$ LANGUAGE plpgsql; 

-- creates blah_member_rel and yippe_member_rel relationships

\i rel-segments-test-types-create.sql



--
-- procedure test_rel_constraints/0
--
CREATE OR REPLACE FUNCTION test_rel_constraints(

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

  reg_users integer;

  rel_id integer;

  side_one_constraint integer;
  side_two_constraint integer;

  v_count integer;

  r       record;

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

  reg_users := acs__magic_object_id('registered_users');

  rel_id := composition_rel__new(A, B);
  rel_id := composition_rel__new(A, C);
  rel_id := composition_rel__new(A, D);

  rel_id := composition_rel__new(E, A);
  rel_id := composition_rel__new(E, F);

  rel_id := composition_rel__new(reg_users, E);
  rel_id := composition_rel__new(reg_users, G);
  -- define a few segments.

  -- define a few relational constraints.

 
  side_two_constraint := rel_constraint__new(
                                null,
                                'rel_constraint',
                                'Yippe: side 2 must be a blah of A',
                                rel_segment__get_or_new(reg_users, 
                                                        'yippe_member_rel', 
                                                        null),
                                'two',
                                rel_segment__get_or_new(A,
                                                        'blah_member_rel', 
                                                        null),
                                null,
                                null,
                                null
                                
  );


  side_one_constraint := rel_constraint__new(
                                null,
                                'rel_constraint',
                                'Yippe: side 1 must be a component of E',
                                rel_segment__get_or_new(reg_users, 
                                                        'yippe_member_rel', 
                                                        null),
                                'one',
                                rel_segment__get_or_new(E, 
                                                        'composition_rel', 
                                                        null),
                                null,
                                null,
                                null
  );


  delete from acs_logs;


  -- Make a couple of memberships.

  -- LEGAL MEMBERSHIPS:

  -- textbook case: 
  -- joe is a blah of A, and F is component of E, so its legal to make joe
  -- a yippe of F.

  rel_id := blah_member_rel__new(null, 'blah_member_rel', A, joe);

  PERFORM rel_constraint_test_check(rel_id, 'f');

  rel_id := yippe_member_rel__new(null, 'yippie_member_rel', F, joe);

  PERFORM rel_constraint_test_check(rel_id, 'f');

  -- do constraints respect group hierarchy? If so, this will be legal:
  rel_id := blah_member_rel__new(null, 'blah_member_rel', B, jane);

  PERFORM rel_constraint_test_check(rel_id, 'f');

  rel_id := yippe_member_rel__new(null, 'yippie_member_rel', F, jane);

  PERFORM rel_constraint_test_check(rel_id, 'f');

  -- ILLEGAL MEMBERSHIPS:
  
  -- G is not a component of F, therefore no one can be a yippe of G
  -- This should violated 2 constraints (object one and object two are both
  -- invalid).
  rel_id := yippe_member_rel__new(null, 'yippie_member_rel', G, bob);

  PERFORM rel_constraint_test_check(rel_id, 't');

  -- betty is not a blah of A, therefore she cannot be a yippe of F.
  rel_id := yippe_member_rel__new(null, 'yippie_member_rel', F, betty);

  PERFORM rel_constraint_test_check(rel_id, 't');

  -- make sven be a regular member of A.  Sven cannot be a yippe of F.
  rel_id := membership_rel__new(A, sven);
  rel_id := yippe_member_rel__new(null, 'yippie_member_rel', F, sven);

  PERFORM rel_constraint_test_check(rel_id, 't');

  -- TEST THE VIEWS (there should be 4 violated constraints,
  -- 1 side one violation and 3 side two violations.

  select count(*) into v_count
  from rel_constraints_violated_one;

  if v_count != 1 then
     raise NOTICE 'rel_constraints_violated_one should have 1 row. Found % rows.', 
                  v_count;
     PERFORM rel_constraint_dump_views();
  end if;

  select count(*) into v_count
  from rel_constraints_violated_two;

  if v_count != 3 then
     raise NOTICE 'rel_constraints_violated_two should have 2 rows. Found % rows.', 
                  v_count;
     PERFORM rel_constraint_dump_views();
  end if;


  -- Remove the constraints
  PERFORM rel_constraint__delete(side_one_constraint);
  PERFORM rel_constraint__delete(side_two_constraint);

  -- Remove the test membership relations
  for r in select * from blah_member_rels LOOP
    PERFORM blah_member_rel__delete(r.rel_id);
  end loop;

  for r in select * from yippe_member_rels LOOP
    PERFORM yippe_member_rel__delete(r.rel_id);
  end loop;

  -- Remove the test segments.
  PERFORM rel_segment__delete(rel_segment__get(A,'blah_member_rel'));
  PERFORM rel_segment__delete(rel_segment__get(E,'composition_rel'));
  PERFORM rel_segment__delete(rel_segment__get(reg_users,'yippe_member_rel'));

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


select test_rel_constraints();
drop function rel_constraint_dump_views();
drop function rel_constraint_test_check (integer, boolean);
drop function test_rel_constraints();
drop table groups_test_groups;
drop table groups_test_users;

\i rel-segments-test-types-drop.sql

select log_level, log_key, message
from acs_logs
where log_key = 'error';
