--
-- packages/acs-kernel/sql/test/groups-test.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-10-07
-- @cvs-id $Id$
--

set serveroutput on

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

  rel_id := membership_rel.new(object_id_one => B, object_id_two => joe);
  rel_id := membership_rel.new(object_id_one => B, object_id_two => jane);
  rel_id := membership_rel.new(object_id_one => B, object_id_two => betty);
  rel_id := membership_rel.new(object_id_one => A, object_id_two => bob);
  rel_id := membership_rel.new(object_id_one => A, object_id_two => betty);
  rel_id := membership_rel.new(object_id_one => E, object_id_two => betty);

  delete from acs_logs;

  for g in (select * from groups) loop
    if acs_group.check_representation(g.group_id) = 'f' then
      dbms_output.put_line('Group ' || g.group_name || ' (' || g.group_id ||
			   ') failed.');
    end if;
  end loop;

  -- Remove the test groups.
  acs_group.delete(G);
  acs_group.delete(F);
  acs_group.delete(E);
  acs_group.delete(D);
  acs_group.delete(C);
  acs_group.delete(B);
  acs_group.delete(A);

  -- Remove the test members.
  acs_user.delete(joe);
  acs_user.delete(jane);
  acs_user.delete(bob);
  acs_user.delete(betty);
  acs_user.delete(jack);
  acs_user.delete(jill);
  acs_user.delete(sven);
  acs_user.delete(stacy);
end;
/
show errors


select log_level, log_key, message
from acs_logs
where log_key = 'error';
