--
-- packages/acs-kernel/sql/test/rel-constraints-test.sql
--
-- @author oumi@arsdigita.com
-- @creation-date 2000-12-02
-- @cvs-id $Id$
--

set serveroutput on

create or replace procedure rel_constraint_dump_views
is
begin

   dbms_output.put_line(' ');
   dbms_output.put_line('Contents of view ''rel_constraints_violated_one'':');

   for r in (select * from rel_constraints_violated_one) loop
      dbms_output.put_line(rpad(r.constraint_id, 10) ||
                           rpad(r.rel_id, 10) ||
                           rpad(acs_object.name(r.container_id), 20) ||
                           rpad(acs_object.name(r.party_id), 20));
   end loop;


   dbms_output.put_line(' ');
   dbms_output.put_line('Contents of view ''rel_constraints_violated_two'':');

   for r in (select * from rel_constraints_violated_two) loop
      dbms_output.put_line(rpad(r.constraint_id, 10) ||
                           rpad(r.rel_id, 10) ||
                           rpad(acs_object.name(r.container_id), 20) ||
                           rpad(acs_object.name(r.party_id), 20));
   end loop;

end rel_constraint_dump_views;
/
show errors

create or replace procedure rel_constraint_test_check (
  rel_id              integer,
  expect_violation_p  char
)
is
  v_violation_msg varchar(4000);
  v_violation_p char;
  v_object_id_one integer;
  v_object_id_two integer;
  v_rel_type    acs_rels.rel_type%TYPE;
begin

  v_violation_p := 'f';

  v_violation_msg := rel_constraint.violation(rel_id);

  if v_violation_msg is not null then
     v_violation_p := 't';
  end if;

  if v_violation_p != expect_violation_p then

      select object_id_one, object_id_two, rel_type
      into v_object_id_one, v_object_id_two, v_rel_type
      from acs_rels
      where rel_id = rel_constraint_test_check.rel_id;

      acs_log.error('rel_constraint_test_check',
                    'Relation ' || acs_object.name(rel_id) || 
                    ' (' || rel_id || ')' ||
                    ' failed (violation_p = ' || v_violation_p || ').  ' ||
                    'Rel info: type = ' || v_rel_type || ', object one = ' ||
                    acs_object.name(v_object_id_one) || 
                    ' (' || v_object_id_one || ')' || ', object two = ' ||
                    acs_object.name(v_object_id_two) || 
                    ' (' || v_object_id_two || ').');

      dbms_output.put_line('Relation ' || acs_object.name(rel_id) || 
                    ' (' || rel_id || ')' ||
                    ' failed (violation_p = ' || v_violation_p || ').  ' ||
                    'Rel info: type = ' || v_rel_type || ', object one = ' ||
                    acs_object.name(v_object_id_one) || 
                    ' (' || v_object_id_one || ')' || ', object two = ' ||
                    acs_object.name(v_object_id_two) || 
                    ' (' || v_object_id_two || ').');

      dbms_output.put_line('Violation Message:');
      dbms_output.put_line(v_violation_msg);


  end if;

end rel_constraint_test_check;
/
show errors

-- creates blah_member_rel and yippe_member_rel relationships
@rel-segments-test-types-create.sql

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

  reg_users integer;

  rel_id integer;

  side_one_constraint integer;
  side_two_constraint integer;

  v_count integer;

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

  reg_users := acs.magic_object_id('registered_users');

  rel_id := composition_rel.new(object_id_one => A, object_id_two => B);
  rel_id := composition_rel.new(object_id_one => A, object_id_two => C);
  rel_id := composition_rel.new(object_id_one => A, object_id_two => D);

  rel_id := composition_rel.new(object_id_one => E, object_id_two => A);
  rel_id := composition_rel.new(object_id_one => E, object_id_two => F);

  rel_id := composition_rel.new(object_id_one=>reg_users, object_id_two=>E);
  rel_id := composition_rel.new(object_id_one=>reg_users, object_id_two=>G);

  -- define a few segments.

  -- define a few relational constraints.
 
  side_two_constraint := rel_constraint.new(
      constraint_name => 'Yippe: side 2 must be a ''blah'' of A',
      rel_segment => acs_rel_segment.get_or_new(reg_users, 'yippe_member_rel'),
      rel_side => 'two',
      required_rel_segment => acs_rel_segment.get_or_new(A,'blah_member_rel')
  );

  side_one_constraint := rel_constraint.new(
      constraint_name => 'Yippe: side 1 must be a component of E',
      rel_segment => acs_rel_segment.get_or_new(reg_users, 'yippe_member_rel'),
      rel_side => 'one',
      required_rel_segment => acs_rel_segment.get_or_new(E, 'composition_rel')
  );


  delete from acs_logs;


  -- Make a couple of memberships.

  -- LEGAL MEMBERSHIPS:

  -- textbook case: 
  -- joe is a blah of A, and F is component of E, so its legal to make joe
  -- a yippe of F.
  rel_id := blah_member_rel.new(object_id_one => A, object_id_two => joe);

  rel_constraint_test_check(rel_id => rel_id, 
                            expect_violation_p => 'f');

  rel_id := yippe_member_rel.new(object_id_one => F, object_id_two => joe);

  rel_constraint_test_check(rel_id => rel_id, 
                            expect_violation_p => 'f');

  -- do constraints respect group hierarchy? If so, this will be legal:
  rel_id := blah_member_rel.new(object_id_one => B, object_id_two => jane);

  rel_constraint_test_check(rel_id => rel_id, 
                            expect_violation_p => 'f');

  rel_id := yippe_member_rel.new(object_id_one => F, object_id_two => jane);

  rel_constraint_test_check(rel_id => rel_id, 
                            expect_violation_p => 'f');

  -- ILLEGAL MEMBERSHIPS:
  
  -- G is not a component of F, therefore no one can be a yippe of G
  -- This should violated 2 constraints (object one and object two are both
  -- invalid).
  rel_id := yippe_member_rel.new(object_id_one => G, object_id_two => bob);

  rel_constraint_test_check(rel_id => rel_id, 
                            expect_violation_p => 't');

  -- betty is not a blah of A, therefore she cannot be a yippe of F.
  rel_id := yippe_member_rel.new(object_id_one => F, object_id_two => betty);

  rel_constraint_test_check(rel_id => rel_id, 
                            expect_violation_p => 't');

  -- make sven be a regular member of A.  Sven cannot be a yippe of F.
  rel_id := membership_rel.new(object_id_one => A, object_id_two => sven);
  rel_id := yippe_member_rel.new(object_id_one => F, object_id_two => sven);

  rel_constraint_test_check(rel_id => rel_id, 
                            expect_violation_p => 't');

  -- TEST THE VIEWS (there should be 4 violated constraints,
  -- 1 side one violation and 3 side two violations.

  select count(*) into v_count
  from rel_constraints_violated_one;

  if v_count != 1 then
     dbms_output.put_line ('rel_constraints_violated_one should have 1 row.' ||
                           '  Found ' || v_count || ' rows.');
     rel_constraint_dump_views;
  end if;

  select count(*) into v_count
  from rel_constraints_violated_two;

  if v_count != 3 then
     dbms_output.put_line ('rel_constraints_violated_two should have 2 rows.' ||
                           '  Found ' || v_count || ' rows.');
     rel_constraint_dump_views;
  end if;


  -- Remove the constraints
  rel_constraint.del(side_one_constraint);
  rel_constraint.del(side_two_constraint);

  -- Remove the test membership relations
  for r in (select * from blah_member_rels) loop
    blah_member_rel.del(r.rel_id);
  end loop;

  for r in (select * from yippe_member_rels) loop
    yippe_member_rel.del(r.rel_id);
  end loop;

  -- Remove the test segments.
  acs_rel_segment.del(acs_rel_segment.get(A,'blah_member_rel'));
  acs_rel_segment.del(acs_rel_segment.get(E,'composition_rel'));
  acs_rel_segment.del(acs_rel_segment.get(reg_users,'yippe_member_rel'));

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


drop procedure rel_constraint_test_check;

@rel-segments-test-types-drop.sql

select log_level, log_key, message
from acs_logs
where log_key = 'error';
