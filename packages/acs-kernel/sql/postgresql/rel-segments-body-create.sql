--
-- packages/acs-kernel/sql/rel-segments-create.sql
--
-- @author Oumi Mehrotra oumi@arsdigita.com
-- @creation-date 2000-11-22
-- @cvs-id rel-segments-body-create.sql,v 1.1.4.1 2001/01/12 22:58:33 mbryzek Exp

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

------------------
-- PACKAGE BODY --
------------------

-- rel_segment__new -- full version
create or replace function rel_segment__new (integer,varchar,timestamptz,integer,varchar,varchar,varchar,varchar,integer,varchar,integer)
returns integer as '
declare
  new__segment_id        alias for $1;  -- default null  
  object_type            alias for $2;  -- default ''rel_segment''
  creation_date          alias for $3;  -- default now()
  creation_user          alias for $4;  -- default null
  creation_ip            alias for $5;  -- default null
  email                  alias for $6;  -- default null
  url                    alias for $7;  -- default null
  new__segment_name      alias for $8;  
  new__group_id          alias for $9;  
  new__rel_type          alias for $10; 
  context_id             alias for $11; -- default null
  v_segment_id           rel_segments.segment_id%TYPE;
begin
  v_segment_id :=
   party__new(new__segment_id, object_type, creation_date, creation_user,
             creation_ip, email, url, context_id);

  insert into rel_segments
   (segment_id, segment_name, group_id, rel_type)
  values
   (v_segment_id, new__segment_name, new__group_id, new__rel_type);

  return v_segment_id;
  
end;' language 'plpgsql';

-- rel_segment__new -- overloaded version for specifying only non-default values
create or replace function rel_segment__new (varchar,integer,varchar)
returns integer as '
declare
  new__segment_name      alias for $1;  
  new__group_id          alias for $2;  
  new__rel_type          alias for $3;
  v_segment_id           rel_segments.segment_id%TYPE;
begin

   v_segment_id := rel_segment__new(null, ''rel_segment'', now(), null, null, null, null, new__segment_name, new__group_id, new__rel_type, null);

   return v_segment_id;

end;' language 'plpgsql';


-- procedure delete
create or replace function rel_segment__delete (integer)
returns integer as '
declare
  delete__segment_id            alias for $1;  
  row                           record;
begin

   -- remove all constraints on this segment
   for row in  select constraint_id 
                 from rel_constraints 
                where rel_segment = delete__segment_id 
   LOOP

       PERFORM rel_constraint__delete(row.constraint_id);

   end loop;

   PERFORM party__delete(delete__segment_id);

   return 0; 
end;' language 'plpgsql';


-- function get
create or replace function rel_segment__get (integer,varchar)
returns integer as '
declare
  get__group_id         alias for $1;  
  get__rel_type         alias for $2;  
begin

   return min(segment_id)
   from rel_segments
   where group_id = get__group_id
     and rel_type = get__rel_type;
  
end;' language 'plpgsql' stable strict;

create or replace function rel_segment__get_or_new(integer,varchar) returns integer as '
declare
        gid     alias for $1;
        typ     alias for $2;
begin
        return rel_segment__get_or_new(gid,typ,null);
end;' language 'plpgsql';

-- function get_or_new
create or replace function rel_segment__get_or_new (integer,varchar,varchar)
returns integer as '
declare
  get_or_new__group_id          alias for $1;  
  get_or_new__rel_type          alias for $2;  
  segment_name                  alias for $3;  -- default null
  v_segment_id                  rel_segments.segment_id%TYPE;
  v_segment_name                rel_segments.segment_name%TYPE;
begin

   v_segment_id := rel_segment__get(get_or_new__group_id,get_or_new__rel_type);

   if v_segment_id is null then

      if segment_name is not null then
         v_segment_name := segment_name;
      else
         select groups.group_name || '' - '' || acs_object_types.pretty_name ||
                  '' segment''
         into v_segment_name
         from groups, acs_object_types
         where groups.group_id = get_or_new__group_id
           and acs_object_types.object_type = get_or_new__rel_type;

      end if;

      v_segment_id := rel_segment__new (
          null,
          ''rel_segment'',
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

  
end;' language 'plpgsql';


-- function name
create or replace function rel_segment__name (integer)
returns varchar as '
declare
  name__segment_id             alias for $1;  
  name__segment_name           varchar(200);  
begin
  return segment_name
  from rel_segments
  where segment_id = name__segment_id;

end;' language 'plpgsql' stable strict;



-- show errors

