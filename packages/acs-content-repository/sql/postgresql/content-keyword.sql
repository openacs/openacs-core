-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Stanislav Freidin (sfreidin@arsdigita.com)

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

select define_function_args ('content_keyword__get_heading','keyword_id');


--
-- procedure content_keyword__get_heading/1
--
CREATE OR REPLACE FUNCTION content_keyword__get_heading(
   get_heading__keyword_id integer
) RETURNS text AS $$
DECLARE
  v_heading                           text; 
BEGIN

  select heading into v_heading from cr_keywords
    where keyword_id = get_heading__keyword_id;

  return v_heading;
 
END;
$$ LANGUAGE plpgsql stable strict;


-- function get_description
select define_function_args ('content_keyword__get_description','keyword_id');


--
-- procedure content_keyword__get_description/1
--
CREATE OR REPLACE FUNCTION content_keyword__get_description(
   get_description__keyword_id integer
) RETURNS text AS $$
DECLARE
  v_description                           text; 
BEGIN

  select description into v_description from cr_keywords
    where keyword_id = get_description__keyword_id;

  return v_description;
 
END;
$$ LANGUAGE plpgsql stable strict;


-- procedure set_heading
select define_function_args ('content_keyword__set_heading','keyword_id,heading');


--
-- procedure content_keyword__set_heading/2
--
CREATE OR REPLACE FUNCTION content_keyword__set_heading(
   set_heading__keyword_id integer,
   set_heading__heading varchar
) RETURNS integer AS $$
DECLARE
BEGIN

  update cr_keywords set 
    heading = set_heading__heading
  where
    keyword_id = set_heading__keyword_id;

  update acs_objects
  set title = set_heading__heading
  where object_id = set_heading__keyword_id;

  return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure set_description
select define_function_args ('content_keyword__set_description','keyword_id,description');


--
-- procedure content_keyword__set_description/2
--
CREATE OR REPLACE FUNCTION content_keyword__set_description(
   set_description__keyword_id integer,
   set_description__description varchar
) RETURNS integer AS $$
DECLARE
BEGIN

  update cr_keywords set 
    description = set_description__description
  where
    keyword_id = set_description__keyword_id;

  return 0; 
END;
$$ LANGUAGE plpgsql;


-- function is_leaf
select define_function_args ('content_keyword__is_leaf','keyword_id');


--
-- procedure content_keyword__is_leaf/1
--
CREATE OR REPLACE FUNCTION content_keyword__is_leaf(
   is_leaf__keyword_id integer
) RETURNS boolean AS $$
DECLARE
BEGIN

  return 
      count(*) = 0
  from 
    cr_keywords k
  where
    k.parent_id = is_leaf__keyword_id;
 
END;
$$ LANGUAGE plpgsql stable;


-- function new

select define_function_args('content_keyword__new','heading,description;null,parent_id;null,keyword_id;null,creation_date;now,creation_user;null,creation_ip;null,object_type;content_keyword,package_id');

--
-- procedure content_keyword__new/9
--
CREATE OR REPLACE FUNCTION content_keyword__new(
   new__heading varchar,
   new__description varchar,       -- default null
   new__parent_id integer,         -- default null
   new__keyword_id integer,        -- default null
   new__creation_date timestamptz, -- default now() -- default 'now'
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__object_type varchar,       -- default 'content_keyword'
   new__package_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_id                        integer;       
  v_package_id                acs_objects.package_id%TYPE;
BEGIN

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
                           't',
                           new__heading,
                           v_package_id
  );
    
  insert into cr_keywords 
    (heading, description, keyword_id, parent_id)
  values
    (new__heading, new__description, v_id, new__parent_id);

  return v_id;
 
END;
$$ LANGUAGE plpgsql;


select define_function_args('content_keyword__new','heading,description;null,parent_id;null,keyword_id;null,creation_date;now,creation_user;null,creation_ip;null,object_type;content_keyword');

--
-- procedure content_keyword__new/8
--
CREATE OR REPLACE FUNCTION content_keyword__new(
   new__heading varchar,
   new__description varchar,       -- default null
   new__parent_id integer,         -- default null
   new__keyword_id integer,        -- default null
   new__creation_date timestamptz, -- default now() -- default 'now'
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__object_type varchar        -- default 'content_keyword'

) RETURNS integer AS $$
DECLARE
BEGIN
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

END;
$$ LANGUAGE plpgsql;

-- procedure delete
select define_function_args ('content_keyword__del','keyword_id');


--
-- procedure content_keyword__del/1
--
CREATE OR REPLACE FUNCTION content_keyword__del(
   delete__keyword_id integer
) RETURNS integer AS $$
DECLARE
  v_rec                          record; 
BEGIN

  for v_rec in select item_id from cr_item_keyword_map 
    where keyword_id = delete__keyword_id LOOP
    PERFORM content_keyword__item_unassign(v_rec.item_id, delete__keyword_id);
  end LOOP;

  PERFORM acs_object__delete(delete__keyword_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('content_keyword__delete','keyword_id');

--
-- procedure content_keyword__delete/1
--
CREATE OR REPLACE FUNCTION content_keyword__delete(
   delete__keyword_id integer
) RETURNS integer AS $$
DECLARE
  v_rec                          record; 
BEGIN
  perform content_keyword__del(delete__keyword_id);
  return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure item_assign
select define_function_args ('content_keyword__item_assign','item_id,keyword_id,context_id;null,creation_user;null,creation_ip;null');


--
-- procedure content_keyword__item_assign/5
--
CREATE OR REPLACE FUNCTION content_keyword__item_assign(
   item_assign__item_id integer,
   item_assign__keyword_id integer,
   item_assign__context_id integer,    -- default null
   item_assign__creation_user integer, -- default null
   item_assign__creation_ip varchar    -- default null

) RETURNS integer AS $$
DECLARE
  exists_p                            boolean;
BEGIN
  
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
END;
$$ LANGUAGE plpgsql;


-- procedure item_unassign
select define_function_args ('content_keyword__item_unassign','item_id,keyword_id');


--
-- procedure content_keyword__item_unassign/2
--
CREATE OR REPLACE FUNCTION content_keyword__item_unassign(
   item_unassign__item_id integer,
   item_unassign__keyword_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  delete from cr_item_keyword_map
    where item_id = item_unassign__item_id 
    and keyword_id = item_unassign__keyword_id;

  return 0; 
END;
$$ LANGUAGE plpgsql;


-- function is_assigned
select define_function_args ('content_keyword__is_assigned','item_id,keyword_id,recurse;none');


--
-- procedure content_keyword__is_assigned/3
--
CREATE OR REPLACE FUNCTION content_keyword__is_assigned(
   is_assigned__item_id integer,
   is_assigned__keyword_id integer,
   is_assigned__recurse varchar -- default 'none'

) RETURNS boolean AS $$
DECLARE
  v_ret                               boolean;    
  v_is_assigned__recurse	      varchar;
BEGIN
  if is_assigned__recurse is null then 
	v_is_assigned__recurse := 'none';
  else
      	v_is_assigned__recurse := is_assigned__recurse;	
  end if;

  -- Look for an exact match
  if v_is_assigned__recurse = 'none' then
      return count(*) > 0 from cr_item_keyword_map
       where item_id = is_assigned__item_id
         and keyword_id = is_assigned__keyword_id;
  end if;

  -- Look from specific to general
  if v_is_assigned__recurse = 'up' then
      return count(*) > 0
      where exists (select 1
                    from (select keyword_id from cr_keywords c, cr_keywords c2
	                  where c2.keyword_id = is_assigned__keyword_id
                            and c.tree_sortkey between c2.tree_sortkey and tree_right(c2.tree_sortkey)) t,
                      cr_item_keyword_map m
                    where t.keyword_id = m.keyword_id
                      and m.item_id = is_assigned__item_id);
  end if;

  if v_is_assigned__recurse = 'down' then
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
  raise EXCEPTION '-20000: The recurse parameter to content_keyword.is_assigned should be ''none'', ''up'' or ''down''';
  
  return null;
END;
$$ LANGUAGE plpgsql stable;


-- function get_path
select define_function_args ('content_keyword__get_path','keyword_id');


--
-- procedure content_keyword__get_path/1
--
CREATE OR REPLACE FUNCTION content_keyword__get_path(
   get_path__keyword_id integer
) RETURNS text AS $$
DECLARE
  v_path                          text default '';
  v_is_found                      boolean default 'f';   
  v_heading                       cr_keywords.heading%TYPE;
  v_rec                           record;
BEGIN
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
      v_is_found := 't';
      v_path := v_path || '/' || v_heading;
  end LOOP;

  if v_is_found = 'f' then
    return null;
  else
    return v_path;
  end if;
 
END;
$$ LANGUAGE plpgsql stable strict;


-- Ensure that the context_id in acs_objects is always set to the
-- parent_id in cr_keywords

CREATE OR REPLACE FUNCTION cr_keywords_update_tr () RETURNS trigger AS $$
BEGIN
  if old.parent_id <> new.parent_id then
    update acs_objects set context_id = new.parent_id
      where object_id = new.keyword_id;
  end if;

  return new;
END;
$$ LANGUAGE plpgsql;

create trigger cr_keywords_update_tr after update on cr_keywords
for each row execute procedure cr_keywords_update_tr ();

-- show errors
