--
-- packages/acs-kernel/sql/test/groups-test.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-10-07
-- @cvs-id $Id$
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

create function test_groups() returns integer as '
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

  rel_a  integer;
  rel_b  integer;
  rel_c  integer;
  rel_d  integer;
  rel_e  integer;
  rel_f  integer;
  rel_g  integer;
  rel_h  integer;
  rel_i  integer;
  rel_j  integer;
  rel_k  integer;
  rel_l  integer;
  gp     record;
  n_rows integer;
begin
  -- Create the test groups.

  A := acs_group__new(''A'');
  B := acs_group__new(''B'');
  C := acs_group__new(''C'');
  D := acs_group__new(''D'');
  E := acs_group__new(''E'');
  F := acs_group__new(''F'');
  G := acs_group__new(''G'');

  insert into groups_test_groups values (A,1,''A'');
  insert into groups_test_groups values (B,2,''B'');
  insert into groups_test_groups values (C,3,''C'');
  insert into groups_test_groups values (D,4,''D'');
  insert into groups_test_groups values (E,5,''E'');
  insert into groups_test_groups values (F,6,''F'');  
  insert into groups_test_groups values (G,7,''G'');

  -- Create the test members.
  joe   := acs_user__new(''joe@asdf.com'',''Joe'',
                         ''Smith'',''assword'',''p'');
  jane  := acs_user__new(''jane@asdf.com'',''Jane'',
                         ''Smith'',''assword'',''p'');
  bob   := acs_user__new(''bob@asdf.com'',''Bob'',
                         ''Smith'',''assword'',''p'');
  betty := acs_user__new(''betty@asdf.com'',''Betty'',
                         ''Smith'',''assword'',''p'');
  jack  := acs_user__new(''jack@asdf.com'',''Jack'',
                         ''Smith'',''assword'',''p'');
  jill  := acs_user__new(''jill@asdf.com'',''Jill'',
                         ''Smith'',''assword'',''p'');
  sven  := acs_user__new(''sven@asdf.com'',''Sven'',
                         ''Smith'',''assword'',''p'');
  stacy := acs_user__new(''stacy@asdf.com'',''Stacy'',
                         ''Smith'',''assword'',''p'');

  insert into groups_test_users values (joe,1,''joe'');
  insert into groups_test_users values (jane,2,''jane'');
  insert into groups_test_users values (bob,3,''bob'');
  insert into groups_test_users values (betty,4,''betty'');
  insert into groups_test_users values (jack,5,''jack'');
  insert into groups_test_users values (jill,6,''jill'');  
  insert into groups_test_users values (sven,7,''sven'');
  insert into groups_test_users values (stacy,8,''stacy'');

  -- Make a couple of compositions.

  rel_a := composition_rel__new(A, B);
  rel_b := composition_rel__new(A, C);
  rel_c := composition_rel__new(A, D);
  rel_d := composition_rel__new(E, A);
  rel_e := composition_rel__new(F, A);
  rel_f := composition_rel__new(G, A);

  -- Make a couple of memberships.

  rel_g := membership_rel__new(B, joe);
  rel_h := membership_rel__new(B, jane);
  rel_i := membership_rel__new(B, betty);
  rel_j := membership_rel__new(A, bob);
  rel_k := membership_rel__new(A, betty);
  rel_l := membership_rel__new(E, betty);

  delete from acs_logs;

  return null;

end;' language 'plpgsql';

create function check_groups () returns integer as '
declare 
        gp      record;
        v_rec   record;
begin
  for gp in select * from groups order by group_name LOOP
    if NOT acs_group__check_representation(gp.group_id) then
      raise notice ''Group % (%) failed'', gp.group_name, gp.group_id;
    else 
      raise notice ''Group % (%) passed'', gp.group_name, gp.group_id;
    end if;
  end LOOP;

  for v_rec in select group_id from groups_test_groups order by sorder desc
  LOOP
    raise notice ''dropping %'', v_rec.group_id;
    PERFORM acs_group__delete(v_rec.group_id);
  end LOOP;

  delete from groups_test_groups;

  for v_rec in select user_id from groups_test_users order by sorder
  LOOP
    raise notice ''dropping %'', v_rec.user_id;
    PERFORM acs_user__delete(v_rec.user_id);
  end LOOP;
  delete from groups_test_users;

  return null;

end;' language 'plpgsql';

select test_groups();
select check_groups();

drop table groups_test_groups;
drop table groups_test_users;

drop function test_groups();
drop function check_groups();

select log_level, log_key, message
from acs_logs
where log_level = 'error';

