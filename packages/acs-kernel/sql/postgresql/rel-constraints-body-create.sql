--
-- /packages/acs-kernel/sql/rel-constraints-create.sql
-- 
-- Add support for relational constraints based on relational segmentation.
--
-- @author Oumi Mehrotra (oumi@arsdigita.com)
-- @creation-date 2000-11-22
-- @cvs-id $Id$

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html


-- create or replace package body rel_constraint

create or replace function rel_constraint__new(varchar,integer,varchar,integer) 
returns integer as '
declare
        nam     alias for $1;
        sid1    alias for $2;
        side    alias for $3;
        sid2    alias for $4;
begin
        return rel_constraint__new(null,
                                   ''rel_constraint'',
                                   nam,
                                   sid1,
                                   side,
                                   sid2,
                                   null,
                                   null,
                                   null
                                   );                                   
end;' language 'plpgsql';

-- function new
create or replace function rel_constraint__new (integer,varchar,varchar,integer,char,integer,integer,integer,varchar)
returns integer as '
declare
  new__constraint_id          alias for $1;  -- default null  
  new__constraint_type        alias for $2;  -- default ''rel_constraint''
  new__constraint_name        alias for $3;  
  new__rel_segment            alias for $4;  
  new__rel_side               alias for $5;  -- default ''two''
  new__required_rel_segment   alias for $6;  
  new__context_id             alias for $7;  -- default null
  new__creation_user          alias for $8;  -- default null
  new__creation_ip            alias for $9;  -- default null
  v_constraint_id             rel_constraints.constraint_id%TYPE;
begin
    v_constraint_id := acs_object__new (
      new__constraint_id,
      new__constraint_type,
      now(),
      new__creation_user,
      new__creation_ip,
      new__context_id,
      ''t'',
      new__constraint_name,
      null
    );

    insert into rel_constraints
     (constraint_id, constraint_name, 
      rel_segment, rel_side, required_rel_segment)
    values
     (v_constraint_id, new__constraint_name, 
      new__rel_segment, new__rel_side, new__required_rel_segment);

     return v_constraint_id;
   
end;' language 'plpgsql';


-- procedure delete
create or replace function rel_constraint__delete (integer)
returns integer as '
declare
  constraint_id          alias for $1;  
begin
    PERFORM acs_object__delete(constraint_id);

    return 0; 
end;' language 'plpgsql';


-- function get_constraint_id
create or replace function rel_constraint__get_constraint_id (integer,char,integer)
returns integer as '
declare
  get_constraint_id__rel_segment            alias for $1;  
  get_constraint_id__rel_side               alias for $2;  
  get_constraint_id__required_rel_segment   alias for $3;  
  v_constraint_id                           rel_constraints.constraint_id%TYPE;
begin

    return constraint_id
    from rel_constraints
    where rel_segment = get_constraint_id__rel_segment
      and rel_side = get_constraint_id__rel_side
      and required_rel_segment = get_constraint_id__required_rel_segment;

end;' language 'plpgsql' stable strict;


-- function violation
create or replace function rel_constraint__violation (integer)
returns varchar as '
declare
  violation__rel_id                 alias for $1;  
  v_error                           text; 
  constraint_violated               record;
begin

    v_error := null;

    for constraint_violated in
     select constraint_id, constraint_name
       from rel_constraints_violated_one
       where rel_id = violation__rel_id
       LIMIT 1 
    LOOP

	  v_error := coalesce(v_error,'''') || 
                     ''Relational Constraint Violation: '' ||
                     constraint_violated.constraint_name || 
                     '' (constraint_id='' ||
                     constraint_violated.constraint_id || ''). '';

          return v_error;
    end loop;

    for constraint_violated in
     select constraint_id, constraint_name
       from rel_constraints_violated_two
      where rel_id = violation__rel_id
      LIMIT 1 
    LOOP

           v_error := coalesce(v_error,'''') || 
                      ''Relational Constraint Violation: '' ||
                      constraint_violated.constraint_name || 
                      '' (constraint_id='' ||
                      constraint_violated.constraint_id || ''). '';

           return v_error;
    end loop;

    return v_error;
   
end;' language 'plpgsql' stable strict;


-- function violation_if_removed
create or replace function  rel_constraint__violation_if_removed (integer)
returns varchar as '
declare
  violation_if_removed__rel_id                 alias for $1;  
  v_count                                      integer;       
  v_error                                      text; 
  constraint_violated                          record;
begin
    v_error := null;

    select count(*) into v_count
      from dual
     where exists (select 1 
                     from rc_violations_by_removing_rel r 
                    where r.rel_id = violation_if_removed__rel_id);

    if v_count > 0 then
      -- some other relation depends on this one. Lets build up a string
      -- of the constraints we are violating
      for constraint_violated in select constraint_id, constraint_name
                                   from rc_violations_by_removing_rel r
                                  where r.rel_id = violation_if_removed__rel_id 
      LOOP

          v_error := v_error || ''Relational Constraint Violation: '' ||
                     constraint_violated.constraint_name || 
                     '' (constraint_id='' ||
                     constraint_violated.constraint_id || ''). '';

      end loop;

    end if;

    return v_error;

   
end;' language 'plpgsql' stable strict;



-- show errors
