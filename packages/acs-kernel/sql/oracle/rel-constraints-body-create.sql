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


create or replace package body rel_constraint
as

  function new (
    constraint_id	in rel_constraints.constraint_id%TYPE default null,
    constraint_type     in acs_objects.object_type%TYPE default 'rel_constraint',
    constraint_name	in rel_constraints.constraint_name%TYPE,
    rel_segment		in rel_constraints.rel_segment%TYPE,
    rel_side	        in rel_constraints.rel_side%TYPE default 'two',
    required_rel_segment in rel_constraints.required_rel_segment%TYPE,
    context_id		in acs_objects.context_id%TYPE default null,
    creation_user	in acs_objects.creation_user%TYPE default null,
    creation_ip		in acs_objects.creation_ip%TYPE default null
  ) return rel_constraints.constraint_id%TYPE
  is
    v_constraint_id rel_constraints.constraint_id%TYPE;
  begin
    v_constraint_id := acs_object.new (
      object_id => constraint_id,
      object_type => constraint_type,
      context_id => context_id,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into rel_constraints
     (constraint_id, constraint_name, 
      rel_segment, rel_side, required_rel_segment)
    values
     (v_constraint_id, new.constraint_name, 
      new.rel_segment, new.rel_side, new.required_rel_segment);

     return v_constraint_id;
  end;

  procedure del (
    constraint_id	in rel_constraints.constraint_id%TYPE
  )
  is
  begin
    acs_object.del(constraint_id);
  end;

  function get_constraint_id (
    rel_segment		in rel_constraints.rel_segment%TYPE,
    rel_side	        in rel_constraints.rel_side%TYPE default 'two',
    required_rel_segment in rel_constraints.required_rel_segment%TYPE
  ) return rel_constraints.constraint_id%TYPE
  is
    v_constraint_id	rel_constraints.constraint_id%TYPE;
  begin
    select constraint_id into v_constraint_id
    from rel_constraints
    where rel_segment = get_constraint_id.rel_segment
      and rel_side = get_constraint_id.rel_side
      and required_rel_segment = get_constraint_id.required_rel_segment;

    return v_constraint_id;

  end;  

  function violation (
    rel_id	in acs_rels.rel_id%TYPE
  ) return varchar
  is
      v_error varchar(4000);
  begin

    v_error := null;

    for constraint_violated in
      (select /*+ FIRST_ROWS*/ constraint_id, constraint_name
       from rel_constraints_violated_one
       where rel_id = rel_constraint.violation.rel_id
         and rownum = 1) loop

	  v_error := v_error || 'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

          return v_error;
    end loop;

    for constraint_violated in
      (select /*+ FIRST_ROWS*/ constraint_id, constraint_name
       from rel_constraints_violated_two
       where rel_id = rel_constraint.violation.rel_id
         and rownum = 1) loop

           v_error := v_error || 'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

          return v_error;
    end loop;

    return v_error;

  end violation;


  function violation_if_removed (
    rel_id	in acs_rels.rel_id%TYPE
  ) return varchar
  is
      v_count integer;
      v_error varchar(4000);
  begin
    v_error := null;

    select count(*) into v_count
      from dual
     where exists (select 1 from rc_violations_by_removing_rel r where r.rel_id = violation_if_removed.rel_id);

    if v_count > 0 then
      -- some other relation depends on this one. Let's build up a string
      -- of the constraints we are violating
      for constraint_violated in (select constraint_id, constraint_name
                                    from rc_violations_by_removing_rel r
                                   where r.rel_id = violation_if_removed.rel_id) loop

          v_error := v_error || 'Relational Constraint Violation: ' ||
                     constraint_violated.constraint_name || 
                     ' (constraint_id=' ||
                     constraint_violated.constraint_id || '). ';

      end loop;

    end if;

    return v_error;

  end;


end;
/
show errors
