--
-- packages/acs-kernel/sql/rel-segments-create.sql
--
-- @author Oumi Mehrotra oumi@arsdigita.com
-- @creation-date 2000-11-22
-- @cvs-id $Id$

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

------------------
-- PACKAGE BODY --
------------------

create or replace package body rel_segment
is
 function new (
  segment_id            in rel_segments.segment_id%TYPE default null,
  object_type           in acs_objects.object_type%TYPE
                           default 'rel_segment',
  creation_date         in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user         in acs_objects.creation_user%TYPE
                           default null,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  email                 in parties.email%TYPE default null,
  url                   in parties.url%TYPE default null,
  segment_name          in rel_segments.segment_name%TYPE,
  group_id              in rel_segments.group_id%TYPE,
  rel_type              in rel_segments.rel_type%TYPE,
  context_id	in acs_objects.context_id%TYPE default null
 ) return rel_segments.segment_id%TYPE
 is
  v_segment_id rel_segments.segment_id%TYPE;
 begin
  v_segment_id :=
   party.new(segment_id, object_type, creation_date, creation_user,
             creation_ip, email, url, context_id);

  update acs_objects
  set title = segment_name
  where object_id = v_segment_id;

  insert into rel_segments
   (segment_id, segment_name, group_id, rel_type)
  values
   (v_segment_id, new.segment_name, new.group_id, new.rel_type);

  return v_segment_id;
 end new;

 procedure del (
   segment_id     in rel_segments.segment_id%TYPE
 )
 is
 begin

   -- remove all constraints on this segment
   for row in (select constraint_id 
                 from rel_constraints 
                where rel_segment = rel_segment.del.segment_id) loop

       rel_constraint.del(row.constraint_id);

   end loop;

   party.del(segment_id);

 end del;

 -- EXPERIMENTAL / UNSTABLE -- use at your own risk
 --
 function get (
   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE
 ) return rel_segments.segment_id%TYPE
 is
   v_segment_id rel_segments.segment_id%TYPE;
 begin
   select min(segment_id) into v_segment_id
   from rel_segments
   where group_id = get.group_id
     and rel_type = get.rel_type;

   return v_segment_id;
 end get;


 -- EXPERIMENTAL / UNSTABLE -- use at your own risk
 --
 -- This function simplifies the use of segments a little by letting
 -- you not have to worry about creating and initializing segments.
 -- If the segment you're interested in exists, this function
 -- returns its segment_id.
 -- If the segment you're interested in doesn't exist, this function
 -- does a pretty minimal amount of initialization for the segment
 -- and returns a new segment_id.
 function get_or_new (
   group_id       in rel_segments.group_id%TYPE,
   rel_type       in rel_segments.rel_type%TYPE,
   segment_name   in rel_segments.segment_name%TYPE
                  default null
 ) return rel_segments.segment_id%TYPE
 is
   v_segment_id rel_segments.segment_id%TYPE;
   v_segment_name rel_segments.segment_name%TYPE;
 begin

   v_segment_id := get(group_id, rel_type);

   if v_segment_id is null then

      if segment_name is not null then
         v_segment_name := segment_name;
      else
         select groups.group_name || ' - ' || acs_object_types.pretty_name ||
                  ' segment'
         into v_segment_name
         from groups, acs_object_types
         where groups.group_id = get_or_new.group_id
           and acs_object_types.object_type = get_or_new.rel_type;

      end if;

      v_segment_id := rel_segment.new (
          object_type => 'rel_segment',
          creation_user => null,
          creation_ip => null,
          email => null,
          url => null,
          segment_name => v_segment_name,
          group_id => get_or_new.group_id,
          rel_type => get_or_new.rel_type,
          context_id => get_or_new.group_id
      );

   end if;

   return v_segment_id;

 end get_or_new;

 function name (
  segment_id      in rel_segments.segment_id%TYPE
 )
 return rel_segments.segment_name%TYPE
 is
  segment_name varchar(200);
 begin
  select segment_name
  into segment_name
  from rel_segments
  where segment_id = name.segment_id;

  return segment_name;
 end name;

end rel_segment;
/
show errors

