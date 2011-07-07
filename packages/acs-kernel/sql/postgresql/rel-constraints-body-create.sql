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



-- added

--
-- procedure rel_constraint__new/4
--
CREATE OR REPLACE FUNCTION rel_constraint__new(
   nam varchar,
   sid1 integer,
   side varchar,
   sid2 integer
) RETURNS integer AS $$
DECLARE
BEGIN
        return rel_constraint__new(null,
                                   'rel_constraint',
                                   nam,
                                   sid1,
                                   side,
                                   sid2,
                                   null,
                                   null,
                                   null
                                   );                                   
END;
$$ LANGUAGE plpgsql;

-- function new


-- added
select define_function_args('rel_constraint__new','constraint_id;null,constraint_type;rel_constraint,constraint_name,rel_segment,rel_side;two,required_rel_segment,context_id;null,creation_user;null,creation_ip;null');

--
-- procedure rel_constraint__new/9
--
CREATE OR REPLACE FUNCTION rel_constraint__new(
   new__constraint_id integer,   -- default null
   new__constraint_type varchar, -- default 'rel_constraint'
   new__constraint_name varchar,
   new__rel_segment integer,
   new__rel_side char,           -- default 'two'
   new__required_rel_segment integer,
   new__context_id integer,      -- default null
   new__creation_user integer,   -- default null
   new__creation_ip varchar      -- default null

) RETURNS integer AS $$
DECLARE
  v_constraint_id             rel_constraints.constraint_id%TYPE;
BEGIN
    v_constraint_id := acs_object__new (
      new__constraint_id,
      new__constraint_type,
      now(),
      new__creation_user,
      new__creation_ip,
      new__context_id,
      't',
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
   
END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('rel_constraint__delete','constraint_id');

--
-- procedure rel_constraint__delete/1
--
CREATE OR REPLACE FUNCTION rel_constraint__delete(
   constraint_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    PERFORM acs_object__delete(constraint_id);

    return 0; 
END;
$$ LANGUAGE plpgsql;


-- function get_constraint_id


-- added
select define_function_args('rel_constraint__get_constraint_id','rel_segment,rel_side,required_rel_segment');

--
-- procedure rel_constraint__get_constraint_id/3
--
CREATE OR REPLACE FUNCTION rel_constraint__get_constraint_id(
   get_constraint_id__rel_segment integer,
   get_constraint_id__rel_side char,
   get_constraint_id__required_rel_segment integer
) RETURNS integer AS $$
DECLARE
  v_constraint_id                           rel_constraints.constraint_id%TYPE;
BEGIN

    return constraint_id
    from rel_constraints
    where rel_segment = get_constraint_id__rel_segment
      and rel_side = get_constraint_id__rel_side
      and required_rel_segment = get_constraint_id__required_rel_segment;

END;
$$ LANGUAGE plpgsql stable strict;


-- function violation


-- added
select define_function_args('rel_constraint__violation','rel_id');

--
-- procedure rel_constraint__violation/1
--
CREATE OR REPLACE FUNCTION rel_constraint__violation(
   violation__rel_id integer
) RETURNS varchar AS $$
DECLARE
  v_error                           text; 
  constraint_violated               record;
BEGIN

    v_error := null;

    for constraint_violated in
     select constraint_id, constraint_name
       from rel_constraints_violated_one
       where rel_id = violation__rel_id
       LIMIT 1 
    LOOP

	  v_error := coalesce(v_error,'') || 
                     'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

          return v_error;
    end loop;

    for constraint_violated in
     select constraint_id, constraint_name
       from rel_constraints_violated_two
      where rel_id = violation__rel_id
      LIMIT 1 
    LOOP

           v_error := coalesce(v_error,'') || 
                      'Relational Constraint Violation: ' ||
                      constraint_violated.constraint_name || 
                      ' (constraint_id=' ||
                      constraint_violated.constraint_id || '). ';

           return v_error;
    end loop;

    return v_error;
   
END;
$$ LANGUAGE plpgsql stable strict;


-- function violation_if_removed


-- added
select define_function_args('rel_constraint__violation_if_removed','rel_id');

--
-- procedure rel_constraint__violation_if_removed/1
--
CREATE OR REPLACE FUNCTION rel_constraint__violation_if_removed(
   violation_if_removed__rel_id integer
) RETURNS varchar AS $$
DECLARE
  v_count                                      integer;       
  v_error                                      text; 
  constraint_violated                          record;
BEGIN
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

          v_error := v_error || 'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

      end loop;

    end if;

    return v_error;

   
END;
$$ LANGUAGE plpgsql stable strict;



-- show errors
