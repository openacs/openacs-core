-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Stanislav Freidin (sfreidin@arsdigita.com)

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- create or replace package body content_keyword
-- function get_heading
create function content_keyword__get_heading (integer)
returns text as '
declare
  get_heading__keyword_id             alias for $1;  
  v_heading                           text; 
begin

  select heading into v_heading from cr_keywords
    where keyword_id = get_heading__keyword_id;

  return v_heading;
 
end;' language 'plpgsql';


-- function get_description
create function content_keyword__get_description (integer)
returns text as '
declare
  get_description__keyword_id             alias for $1;  
  v_description                           text; 
begin

  select description into v_description from cr_keywords
    where keyword_id = get_description__keyword_id;

  return v_description;
 
end;' language 'plpgsql';


-- procedure set_heading
create function content_keyword__set_heading (integer,varchar)
returns integer as '
declare
  set_heading__keyword_id             alias for $1;  
  set_heading__heading                alias for $2;  
begin

  update cr_keywords set 
    heading = set_heading__heading
  where
    keyword_id = set_heading__keyword_id;

  return 0; 
end;' language 'plpgsql';


-- procedure set_description
create function content_keyword__set_description (integer,varchar)
returns integer as '
declare
  set_description__keyword_id             alias for $1;  
  set_description__description            alias for $2;  
begin

  update cr_keywords set 
    description = set_description__description
  where
    keyword_id = set_description__keyword_id;

  return 0; 
end;' language 'plpgsql';


-- function is_leaf
create function content_keyword__is_leaf (integer)
returns varchar as '
declare
  is_leaf__keyword_id             alias for $1;  
begin

  select
      1
  from 
    cr_keywords k
  where
    k.parent_id = is_leaf__keyword_id;

  if NOT FOUND then 
     return ''t'';
  else 
     return ''f'';
  end if;
 
end;' language 'plpgsql';


-- function new
create function content_keyword__new (varchar,varchar,integer,integer,timestamp,integer,varchar,varchar)
returns integer as '
declare
  new__heading                alias for $1;  
  new__description            alias for $2;  
  new__parent_id              alias for $3;  
  new__keyword_id             alias for $4;  
  new__creation_date          alias for $5;  
  new__creation_user          alias for $6;  
  new__creation_ip            alias for $7;  
  new__object_type            alias for $8;  
  v_id                        integer;       
begin

  v_id := acs_object__new (new__keyword_id,
                           new__object_type,
                           new__creation_date, 
                           new__creation_user, 
                           new__creation_ip
                           new__parent_id,
  );
    
  insert into cr_keywords 
    (heading, description, keyword_id, parent_id)
  values
    (new__heading, new__description, v_id, new__parent_id);

  return v_id;
 
end;' language 'plpgsql';


-- procedure delete
create function content_keyword__delete (integer)
returns integer as '
declare
  delete__keyword_id             alias for $1;  
  v_item_id                      integer;      
  v_rec                          record; 
begin

  for v_rec in select item_id from cr_item_keyword_map 
    where keyword_id = delete__keyword_id LOOP
    PERFORM content_keyword__item_unassign(v_item_id, delete__keyword_id);
  end LOOP;

  PERFORM acs_object__delete(delete__keyword_id);

  return 0; 
end;' language 'plpgsql';


-- procedure item_assign
create function content_keyword__item_assign (integer,integer,integer,integer,varchar)
returns integer as '
declare
  item_assign__item_id                alias for $1;  
  item_assign__keyword_id             alias for $2;  
  item_assign__context_id             alias for $3;  
  item_assign__creation_user          alias for $4;  
  item_assign__creation_ip            alias for $5;  
  exists_p                            boolean;
begin
  
  -- Do nothing if the keyword is assigned already
  select count(*) > 0 into exists_p from dual 
    where exists (select 1 from cr_item_keyword_map
                   where item_id = item_assign__item_id 
                   and keyword_id = item_assign__keyword_id);

  if NOT exists_p then

    insert into cr_item_keyword_map (
      item_id, keyword_id
    ) values (
      item_assign__item_id, item_assign__keyword_id
    );
  end if;

  return 0; 
end;' language 'plpgsql';


-- procedure item_unassign
create function content_keyword__item_unassign (integer,integer)
returns integer as '
declare
  item_unassign__item_id                alias for $1;  
  item_unassign__keyword_id             alias for $2;  
begin

  delete from cr_item_keyword_map
    where item_id = item_unassign__item_id 
    and keyword_id = item_unassign__keyword_id;

  return 0; 
end;' language 'plpgsql';


-- function is_assigned
create function content_keyword__is_assigned (integer,integer,varchar)
returns boolean as '
declare
  is_assigned__item_id                alias for $1;  
  is_assigned__keyword_id             alias for $2;  
  is_assigned__recurse                alias for $3;  
  v_ret                               boolean;    
begin

  -- Look for an exact match
  if is_assigned__recurse = ''none'' then
      select 1 from cr_item_keyword_map
       where item_id = is_assigned__item_id
         and   keyword_id = is_assigned__keyword_id;
      if NOT FOUND then 
         return ''f'';
      else 
         return ''t'';
      end if;
  end if;

  -- Look from specific to general
  if is_assigned__recurse = ''up'' then
      select 1 from dual where exists (select 1 from
	(select keyword_id from cr_keywords
	   connect by parent_id = prior keyword_id
	   start with keyword_id = is_assigned__keyword_id
	 ) t, cr_item_keyword_map m
      where
	t.keyword_id = m.keyword_id
      and
	m.item_id = is_assigned__item_id);

      if NOT FOUND then 
         return ''f'';
      else 
         return ''t'';
      end if;
  end if;

  if is_assigned__recurse = ''down'' then
      select 1 from dual where exists ( select 1 from
	(select keyword_id from cr_keywords
	   connect by prior parent_id = keyword_id
	   start with keyword_id = is_assigned__keyword_id
	 ) t, cr_item_keyword_map m
      where
	t.keyword_id = m.keyword_id
      and
	m.item_id = is_assigned__item_id);

      if NOT FOUND then 
         return ''f'';
      else 
         return ''t'';
      end if;
  end if;  

  -- Tried none, up and down - must be an invalid parameter
  raise EXCEPTION ''-20000: The recurse parameter to content_keyword.is_assigned should be \\\\'none\\\\', \\\\'up\\\\' or \\\\'down\\\\''';
  
  return null;
end;' language 'plpgsql';


-- function get_path
create function content_keyword__get_path (integer)
returns text as '
declare
  keyword_id             alias for $1;  
  v_path                 text default '''';
  v_is_found             boolean default ''f'';   
  v_heading              cr_keywords.heading%TYPE;
  v_rec                  record;
begin

  for v_rec in select 
                 heading 
               from (
                  select 
                    heading, level as tree_level
                  from cr_keywords
                    connect by prior parent_id = keyword_id
                    start with keyword_id = get_path.keyword_id) k 
                order by 
                  tree_level desc 
  LOOP
      v_heading := v_rec.heading;
      v_is_found := ''t'';
      v_path := v_path || ''/'' || v_heading;
  end LOOP;

  if v_is_found = ''f'' then
    return null;
  else
    return v_path;
  end if;
 
end;' language 'plpgsql';



-- show errors


-- Ensure that the context_id in acs_objects is always set to the
-- parent_id in cr_keywords

create function cr_keywords_update_tr () returns opaque as '
begin
  if old.parent_id <> new.parent_id then
    update acs_objects set context_id = new.parent_id
      where object_id = new.keyword_id;
  end if;

  return new;
end;' language 'plpgsql';

create trigger cr_keywords_update_tr after update on cr_keywords
for each row execute procedure cr_keywords_update_tr ();

-- show errors
