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


select log_level, log_key, message
from acs_logs
where log_key = 'error';
