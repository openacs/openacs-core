--    file: packages/acs-kernel/acs/resequence.sql
-- history: date            email                   message
--          2000-07-28      rhs@mit.edu             initial version

-- In theory this stuff should allow us to merge multiple acs
-- installs.

-- The code in this file can be used to modify any number of tables
-- with an integer primary key so that they are keyed by non
-- overlapping sequences. This also modifies data in any table
-- referencing these tables. It is necessary to disable lots of
-- constraints in order to do this so this should *never* be done to
-- an active database. Once the resequence procedure finishes, all
-- primary key sequences will need to be reinitialized.

drop procedure resequence;
drop procedure rs_increment;
drop table rs_dummy;
drop table rs_tables;
drop sequence rs_sort_key_seq;
drop view rs_unconstrained_references;
drop view rs_primary_key_columns;
drop table rs_user_cons_columns;
drop table rs_user_constraints;
drop table rs_user_tab_columns;
drop table rs_user_tables;
drop table rs_referential_constraints;

-- We're going to pull all the info we need out of the system views
-- and stick it in our own tables because for no reason I can figure
-- out certain queries on the system views are *really* slow.

create table rs_user_tables (
	table_name	varchar2(30) primary key
);

create table rs_user_tab_columns (
	table_name	not null references rs_user_tables,
	column_name	varchar2(30) not null,
	primary key (table_name, column_name)
);

create table rs_user_constraints (
	constraint_name	varchar2(30) primary key,
	table_name	not null references rs_user_tables,
	constraint_type char(1),
	r_constraint_name references rs_user_constraints
);

create table rs_user_cons_columns (
	constraint_name	references rs_user_constraints,
	table_name	not null references rs_user_tables,
	column_name	varchar2(30) not null,
	primary key (constraint_name, column_name),
	foreign key (table_name, column_name) references rs_user_tab_columns
);

-- It's important that no tables are created or constraints added
-- between any of the following statements.

insert into rs_user_tables
(table_name)
select table_name
from user_tables;

insert into rs_user_tab_columns
(table_name, column_name)
select utc.table_name, utc.column_name
from user_tab_columns utc, rs_user_tables ut
where utc.table_name = ut.table_name;

insert into rs_user_constraints
(constraint_name, table_name, constraint_type, r_constraint_name)
select constraint_name, table_name, constraint_type, r_constraint_name
from user_constraints;

insert into rs_user_cons_columns
(constraint_name, table_name, column_name)
select constraint_name, table_name, column_name
from user_cons_columns;

-- have to create a table because connect by queries don't work on views.
create table rs_referential_constraints
as select c2.table_name,
          cc.column_name,
	  c2.constraint_name,
          c1.table_name as target
     from rs_user_constraints c1,
          rs_user_constraints c2,
          rs_user_cons_columns cc
    where c2.r_constraint_name = c1.constraint_name
      and c2.constraint_type = 'R'
      and c1.constraint_type = 'P'
      and c2.constraint_name = cc.constraint_name;

create or replace view rs_primary_key_columns
as select c.table_name, cc.column_name
     from rs_user_constraints c,
	  rs_user_cons_columns cc
    where c.constraint_type = 'P'
      and c.constraint_name = cc.constraint_name;

create or replace view rs_unconstrained_references
as select table_name
     from rs_user_tab_columns utc
    where column_name = 'ON_WHICH_TABLE'
      and exists (select 1
                  from rs_user_tab_columns
                  where table_name = utc.table_name
		    and column_name = 'ON_WHAT_ID');

-- This table should have all the tables that require resequencing. No
-- work is required to put the first table in sequence, so it's
-- probably a good idea to make that the users table, thereby avoiding
-- updating nearly every table in the database.

create table rs_tables (
	table_name	varchar2(30) not null,
	sequence_name	varchar2(30),
	min_id		integer,
	max_id		integer,
	offset		integer,
	sort_key	integer not null
);

create sequence rs_sort_key_seq start with 1;

-- Just insert the desired tables and the desired order here. The
-- first table requires no modification, so you can make things go
-- faster by making that be the users table since you won't have to
-- update the users table or anything that references it.

insert into rs_tables
(table_name, sort_key)
values
('USERS', rs_sort_key_seq.nextval);

insert into rs_tables
(table_name, sequence_name, sort_key)
values
('USER_GROUPS', 'USER_GROUP_SEQUENCE', rs_sort_key_seq.nextval);

create table rs_dummy (
	one	integer unique check(one = 1),
	dummy	integer
);

insert into rs_dummy (one) values (1);

-- This procedure disables all constraints referencing v_table_name's
-- primary key, incremenets all the ids in v_table_name by v_offset as
-- well as all the ids in columns referencing v_table_name, and then
-- reinstates all the constraints. This will probably require that the
-- sequence used for v_table_name's primary key be bumped. This should
-- be used with EXTREME CAUTION!

-- I know of at least one web site where a column containing primary
-- keys for another table is maintained without a referential
-- constraint. In the particular case (artmet) this is because the web
-- interface for custom product fields in ecommerce doesn't let you do
-- more than specify that something is an integer. Currently it seems
-- that the easiest way to deal with something like this is to do an
-- alter table and add the constraint.

create or replace procedure rs_increment(v_table_name in varchar2, v_offset in integer, v_sequence_name in varchar2 default null)
is
  column_name	rs_primary_key_columns.column_name%TYPE;
  seq_next_val	integer;
begin
  if v_offset = 0 then
    return;
  end if;

  select column_name into column_name
  from rs_primary_key_columns
  where table_name = v_table_name;

  -- Disable all the constraints that reference this table.
  for con in (select *
              from rs_referential_constraints
	      start with target = v_table_name
              connect by prior table_name = target) loop
    execute immediate
      'alter table ' || con.table_name || ' modify constraint ' ||
      con.constraint_name || ' disable';
  end loop;

  -- Increment all the ids in tables referencing this one by v_offset.
  for con in (select *
              from rs_referential_constraints
	      start with target = v_table_name
              connect by prior table_name = target) loop
    execute immediate
      'update ' || con.table_name || ' set ' || con.column_name || ' = ' ||
      con.column_name || ' + ' || v_offset;
  end loop;

  -- Increment all the on_which_table/on_what_id style unconstrained
  -- references.
  for ucref in (select * from rs_unconstrained_references) loop
    execute immediate
      'update ' || ucref.table_name || ' set on_what_id = on_what_id + ' ||
      v_offset || ' where upper(on_which_table) = ''' || v_table_name || '''';
  end loop;

  -- Increment the ids in the table itself.
  execute immediate
    'update ' || v_table_name || ' set ' || column_name || ' = ' ||
    column_name || ' + ' || v_offset;

  -- Enable all the constraints that reference this table.
  for con in (select *
              from rs_referential_constraints
	      start with target = v_table_name
              connect by prior table_name = target) loop
    execute immediate
      'alter table ' || con.table_name || ' modify constraint ' ||
      con.constraint_name || ' enable';
  end loop;

  -- Now bump the sequence if it exists.
  if v_sequence_name is not null then
    execute immediate
      'alter sequence ' || v_sequence_name || ' increment by ' || v_offset;
    execute immediate
      'update rs_dummy set dummy = ' || v_sequence_name || '.nextval';
    execute immediate
      'alter sequence ' || v_sequence_name || ' increment by 1';
  end if;
end;
/
show errors

-- This procedure resequences every table specified in rs_tables in to
-- have non overlapping primary key ranges in the order specified by
-- rs_tables.sort_key

create or replace procedure resequence
is
  column_name rs_primary_key_columns.column_name%TYPE;
  v_offset integer;
  counter integer;
  min_id integer;
begin
  -- Let's loop through all the tables we need to resequence
  for tab in (select rs_tables.*, rownum from rs_tables order by sort_key) loop
    -- Grab the primary key column. Note that this won't work for
    -- tables with more than one primary key column.
    select column_name into column_name
    from rs_primary_key_columns
    where table_name = tab.table_name;

    -- Set the minimum and maximum ids for each table we need to
    -- resequence.
    execute immediate
      'update rs_tables set min_id = (select min(' || column_name ||
      ') from ' || tab.table_name || '), max_id = (select max(' ||
      column_name || ') from ' || tab.table_name ||
      ') where table_name = ''' || tab.table_name || '''';

    -- Let's special case the first one so that we can avoid doing
    -- lots of unnecessary work.
    if tab.rownum > 1 then
      -- Figure out how much to bump up ids by.
      -- The maximum id already allocated.
      select max(max_id) into counter
      from rs_tables
      where sort_key < tab.sort_key;

      -- The minimum id used in this table.
      select min_id into min_id
      from rs_tables
      where table_name = tab.table_name;

      v_offset := counter - min_id + 1;

      -- Let's keep track of the offset we use.
      update rs_tables
      set offset = v_offset
      where table_name = tab.table_name;

      rs_increment(tab.table_name, v_offset, tab.sequence_name);
    end if;
  end loop;
end;
/
show errors

commit;
