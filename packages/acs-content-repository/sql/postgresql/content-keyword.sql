-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Stanislav Freidin (sfreidin@arsdigita.com)

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

select define_function_args ('content_keyword__get_heading','keyword_id');
create or replace function content_keyword__get_heading (integer)
returns text as '
declare
  get_heading__keyword_id             alias for $1;  
  v_heading                           text; 
begin

  select heading into v_heading from cr_keywords
    where keyword_id = get_heading__keyword_id;

  return v_heading;
 
end;' language 'plpgsql' stable strict;


-- function get_description
select define_function_args ('content_keyword__get_description','keyword_id');
create or replace function content_keyword__get_description (integer)
returns text as '
declare
  get_description__keyword_id             alias for $1;  
  v_description                           text; 
begin

  select description into v_description from cr_keywords
    where keyword_id = get_description__keyword_id;

  return v_description;
 
end;' language 'plpgsql' stable strict;


-- procedure set_heading
select define_function_args ('content_keyword__set_heading','keyword_id,heading');
create or replace function content_keyword__set_heading (integer,varchar)
returns integer as '
declare
  set_heading__keyword_id             alias for $1;  
  set_heading__heading                alias for $2;  
begin

  update cr_keywords set 
    heading = set_heading__heading
  where
    keyword_id = set_heading__keyword_id;

  update acs_objects
  set title = set_heading__heading
  where object_id = set_heading__keyword_id;

  return 0; 
end;' language 'plpgsql';


-- procedure set_description
select define_function_args ('content_keyword__set_description','keyword_id,description');
create or replace function content_keyword__set_description (integer,varchar)
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
select define_function_args ('content_keyword__is_leaf','keyword_id');
create or replace function content_keyword__is_leaf (integer)
returns boolean as '
declare
  is_leaf__keyword_id             alias for $1;  
begin

  return 
      count(*) = 0
  from 
    cr_keywords k
  where
    k.parent_id = is_leaf__keyword_id;
 
end;' language 'plpgsql' stable;


-- function new

select define_function_args('content_keyword__new','heading,description,parent_id,keyword_id,creation_date;now,creation_user,creation_ip,object_type;content_keyword');

create or replace function content_keyword__new (varchar,varchar,integer,integer,timestamptz,integer,varchar,varchar,integer)
returns integer as '
declare
  new__heading                alias for $1;  
  new__description            alias for $2;  -- default null  
  new__parent_id              alias for $3;  -- default null
  new__keyword_id             alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__creation_ip            alias for $7;  -- default null
  new__object_type            alias for $8;  -- default ''content_keyword''
  new__package_id             alias for $9;  -- default null
  v_id                        integer;       
  v_package_id                acs_objects.package_id%TYPE;
begin

  if new__package_id is null then
    v_package_id := acs_object__package_id(new__parent_id);
  else
    v_package_id := new__package_id;
  end if;

  v_id := acs_object__new (new__keyword_id,
                           new__object_type,
                           new__creation_date, 
                           new__creation_user, 
                           new__creation_ip,
                           new__parent_id,
                           ''t'',
                           new__heading,
                           v_package_id
  );
    
  insert into cr_keywords 
    (heading, description, keyword_id, parent_id)
  values
    (new__heading, new__description, v_id, new__parent_id);

  return v_id;
 
end;' language 'plpgsql';

create or replace function content_keyword__new (varchar,varchar,integer,integer,timestamptz,integer,varchar,varchar)
returns integer as '
declare
  new__heading                alias for $1;  
  new__description            alias for $2;  -- default null  
  new__parent_id              alias for $3;  -- default null
  new__keyword_id             alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__creation_ip            alias for $7;  -- default null
  new__object_type            alias for $8;  -- default ''content_keyword''
begin
  return content_keyword__new(new__heading,
                              new__description,
                              new__parent_id,
                              new__keyword_id,
                              new__creation_date,
                              new__creation_user,
                              new__creation_ip,
                              new__object_type,
                              null
  );

end;' language 'plpgsql';

-- procedure delete
select define_function_args ('content_keyword__del','keyword_id');
create or replace function content_keyword__del (integer)
returns integer as '
declare
  delete__keyword_id             alias for $1;  
  v_rec                          record; 
begin

  for v_rec in select item_id from cr_item_keyword_map 
    where keyword_id = delete__keyword_id LOOP
    PERFORM content_keyword__item_unassign(v_rec.item_id, delete__keyword_id);
  end LOOP;

  PERFORM acs_object__delete(delete__keyword_id);

  return 0; 
end;' language 'plpgsql';

create or replace function content_keyword__delete (integer)
returns integer as '
declare
  delete__keyword_id             alias for $1;  
  v_rec                          record; 
begin
  perform content_keyword__del(delete__keyword_id);
  return 0; 
end;' language 'plpgsql';


-- procedure item_assign
select define_function_args ('content_keyword__item_assign','item_id,keyword_id,context_id;null,creation_user;null,creation_ip;null');
create or replace function content_keyword__item_assign (integer,integer,integer,integer,varchar)
returns integer as '
declare
  item_assign__item_id                alias for $1;  
  item_assign__keyword_id             alias for $2;  
  item_assign__context_id             alias for $3;  -- default null  
  item_assign__creation_user          alias for $4;  -- default null
  item_assign__creation_ip            alias for $5;  -- default null
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
select define_function_args ('content_keyword__item_unassign','item_id,keyword_id');
create or replace function content_keyword__item_unassign (integer,integer)
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
select define_function_args ('content_keyword__is_assigned','item_id,keyword_id,recurse;none');
create or replace function content_keyword__is_assigned (integer,integer,varchar)
returns boolean as '
declare
  is_assigned__item_id                alias for $1;  
  is_assigned__keyword_id             alias for $2;  
  is_assigned__recurse                alias for $3;  -- default ''none''  
  v_ret                               boolean;    
  v_is_assigned__recurse	      varchar;
begin
  if is_assigned__recurse is null then 
	v_is_assigned__recurse := ''none'';
  else
      	v_is_assigned__recurse := is_assigned__recurse;	
  end if;

  -- Look for an exact match
  if v_is_assigned__recurse = ''none'' then
      return count(*) > 0 from cr_item_keyword_map
       where item_id = is_assigned__item_id
         and keyword_id = is_assigned__keyword_id;
  end if;

  -- Look from specific to general
  if v_is_assigned__recurse = ''up'' then
      return count(*) > 0
      where exists (select 1
                    from (select keyword_id from cr_keywords c, cr_keywords c2
	                  where c2.keyword_id = is_assigned__keyword_id
                            and c.tree_sortkey between c2.tree_sortkey and tree_right(c2.tree_sortkey)) t,
                      cr_item_keyword_map m
                    where t.keyword_id = m.keyword_id
                      and m.item_id = is_assigned__item_id);
  end if;

  if v_is_assigned__recurse = ''down'' then
      return count(*) > 0
      where exists (select 1
                    from (select k2.keyword_id
                          from cr_keywords k1, cr_keywords k2
                          where k1.keyword_id = is_assigned__keyword_id
                            and k1.tree_sortkey between k2.tree_sortkey and tree_right(k2.tree_sortkey)) t, 
                      cr_item_keyword_map m
                    where t.keyword_id = m.keyword_id
                      and m.item_id = is_assigned__item_id);

  end if;  

  -- Tried none, up and down - must be an invalid parameter
  raise EXCEPTION ''-20000: The recurse parameter to content_keyword.is_assigned should be \\\'none\\\', \\\'up\\\' or \\\'down\\\''';
  
  return null;
end;' language 'plpgsql' stable;


-- function get_path
select define_function_args ('content_keyword__get_path','keyword_id');
create or replace function content_keyword__get_path (integer)
returns text as '
declare
  get_path__keyword_id             alias for $1;  
  v_path                          text default '''';
  v_is_found                      boolean default ''f'';   
  v_heading                       cr_keywords.heading%TYPE;
  v_rec                           record;
begin
--               select
--                 heading 
--               from (
--                  select 
--                    heading, level as tree_level
--                  from cr_keywords
--                    connect by prior parent_id = keyword_id
--                    start with keyword_id = get_path.keyword_id) k 
--                order by 
--                  tree_level desc 

  for v_rec in select heading 
               from (select k2.heading, tree_level(k2.tree_sortkey) as tree_level
                     from cr_keywords k1, cr_keywords k2
                     where k1.keyword_id = get_path__keyword_id
                       and k1.tree_sortkey between k2.tree_sortkey and tree_right(k2.tree_sortkey)) k
                order by tree_level desc 
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
 
end;' language 'plpgsql' stable strict;


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
