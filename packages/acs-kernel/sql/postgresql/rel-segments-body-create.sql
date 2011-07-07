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

-- rel_segment__new -- full version


-- added
select define_function_args('rel_segment__new','segment_id;null,object_type;rel_segment,creation_date;now(),creation_user;null,creation_ip;null,email;null,url;null,segment_name,group_id,rel_type,context_id;null');

--
-- procedure rel_segment__new/11
--
CREATE OR REPLACE FUNCTION rel_segment__new(
   new__segment_id integer,   -- default null
   object_type varchar,       -- default 'rel_segment'
   creation_date timestamptz, -- default now()
   creation_user integer,     -- default null
   creation_ip varchar,       -- default null
   email varchar,             -- default null
   url varchar,               -- default null
   new__segment_name varchar,
   new__group_id integer,
   new__rel_type varchar,
   context_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_segment_id           rel_segments.segment_id%TYPE;
BEGIN
  v_segment_id :=
   party__new(new__segment_id, object_type, creation_date, creation_user,
             creation_ip, email, url, context_id);

  update acs_objects
  set title = new__segment_name
  where object_id = v_segment_id;

  insert into rel_segments
   (segment_id, segment_name, group_id, rel_type)
  values
   (v_segment_id, new__segment_name, new__group_id, new__rel_type);

  return v_segment_id;
  
END;
$$ LANGUAGE plpgsql;

-- rel_segment__new -- overloaded version for specifying only non-default values


--
-- procedure rel_segment__new/3
--
CREATE OR REPLACE FUNCTION rel_segment__new(
   new__segment_name varchar,
   new__group_id integer,
   new__rel_type varchar
) RETURNS integer AS $$
DECLARE
  v_segment_id           rel_segments.segment_id%TYPE;
BEGIN

   v_segment_id := rel_segment__new(null, 'rel_segment', now(), null, null, null, null, new__segment_name, new__group_id, new__rel_type, null);

   return v_segment_id;

END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('rel_segment__delete','segment_id');

--
-- procedure rel_segment__delete/1
--
CREATE OR REPLACE FUNCTION rel_segment__delete(
   delete__segment_id integer
) RETURNS integer AS $$
DECLARE
  row                           record;
BEGIN

   -- remove all constraints on this segment
   for row in  select constraint_id 
                 from rel_constraints 
                where rel_segment = delete__segment_id 
   LOOP

       PERFORM rel_constraint__delete(row.constraint_id);

   end loop;

   PERFORM party__delete(delete__segment_id);

   return 0; 
END;
$$ LANGUAGE plpgsql;


-- function get


-- added
select define_function_args('rel_segment__get','group_id,rel_type');

--
-- procedure rel_segment__get/2
--
CREATE OR REPLACE FUNCTION rel_segment__get(
   get__group_id integer,
   get__rel_type varchar
) RETURNS integer AS $$
DECLARE
BEGIN

   return min(segment_id)
   from rel_segments
   where group_id = get__group_id
     and rel_type = get__rel_type;
  
END;
$$ LANGUAGE plpgsql stable strict;



-- added

--
-- procedure rel_segment__get_or_new/2
--
CREATE OR REPLACE FUNCTION rel_segment__get_or_new(
   gid integer,
   typ varchar
) RETURNS integer AS $$
DECLARE
BEGIN
        return rel_segment__get_or_new(gid,typ,null);
END;
$$ LANGUAGE plpgsql;

-- function get_or_new


-- added
select define_function_args('rel_segment__get_or_new','group_id,rel_type,segment_name;null');

--
-- procedure rel_segment__get_or_new/3
--
CREATE OR REPLACE FUNCTION rel_segment__get_or_new(
   get_or_new__group_id integer,
   get_or_new__rel_type varchar,
   segment_name varchar -- default null

) RETURNS integer AS $$
DECLARE
  v_segment_id                  rel_segments.segment_id%TYPE;
  v_segment_name                rel_segments.segment_name%TYPE;
BEGIN

   v_segment_id := rel_segment__get(get_or_new__group_id,get_or_new__rel_type);

   if v_segment_id is null then

      if segment_name is not null then
         v_segment_name := segment_name;
      else
         select groups.group_name || ' - ' || acs_object_types.pretty_name ||
                  ' segment'
         into v_segment_name
         from groups, acs_object_types
         where groups.group_id = get_or_new__group_id
           and acs_object_types.object_type = get_or_new__rel_type;

      end if;

      v_segment_id := rel_segment__new (
          null,
          'rel_segment',
          now(),
          null,
          null,
          null,
          null,
          v_segment_name,
          get_or_new__group_id,
          get_or_new__rel_type,
          get_or_new__group_id
      );

   end if;

   return v_segment_id;

  
END;
$$ LANGUAGE plpgsql;


-- function name


-- added
select define_function_args('rel_segment__name','segment_id');

--
-- procedure rel_segment__name/1
--
CREATE OR REPLACE FUNCTION rel_segment__name(
   name__segment_id integer
) RETURNS varchar AS $$
DECLARE
  name__segment_name           varchar(200);  
BEGIN
  return segment_name
  from rel_segments
  where segment_id = name__segment_id;

END;
$$ LANGUAGE plpgsql stable strict;



-- show errors

