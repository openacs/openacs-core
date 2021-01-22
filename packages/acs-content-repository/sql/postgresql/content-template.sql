-- Data model to support content repository of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create view content_template_globals as 
select -200 as c_root_folder_id;



--
-- procedure content_template__get_root_folder/0
--

select define_function_args('content_template__get_root_folder','');

CREATE OR REPLACE FUNCTION content_template__get_root_folder(

) RETURNS integer AS $$
DECLARE
  v_folder_id                 integer;
BEGIN
  select c_root_folder_id from content_template_globals into v_folder_id;
  return v_folder_id;
END;
$$ LANGUAGE plpgsql immutable;

-- create or replace package body content_template



--
-- procedure content_template__new/1
--
CREATE OR REPLACE FUNCTION content_template__new(
   new__name varchar
) RETURNS integer AS $$
--
-- content_template__new/1 maybe obsolete, when we define proper defaults for /8
--
DECLARE
BEGIN
        return content_template__new(new__name,
                                     null,
                                     null,
                                     now(),
                                     null,
                                     null
        );

END;
$$ LANGUAGE plpgsql;

-- function new



--
-- procedure content_template__new/6
--
CREATE OR REPLACE FUNCTION content_template__new(
   new__name varchar,
   new__parent_id integer,         -- default null
   new__template_id integer,       -- default null
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar        -- default null

) RETURNS integer AS $$
--
-- content_template__new/6 maybe obsolete, when we define proper defaults for /8
--
DECLARE
  v_template_id               cr_templates.template_id%TYPE;
  v_parent_id                 cr_items.parent_id%TYPE;
BEGIN

  if new__parent_id is null then
    select c_root_folder_id into v_parent_id from content_template_globals;
  else
    v_parent_id := new__parent_id;
  end if;

  -- make sure we're allowed to create a template in this folder
  if content_folder__is_folder(new__parent_id) = 't' and
    content_folder__is_registered(new__parent_id,'content_template','f') = 'f' then

    raise EXCEPTION '-20000: This folder does not allow templates to be created';

  else
    v_template_id := content_item__new (
        new__name, 
        v_parent_id,
        new__template_id,
        null,
        new__creation_date, 
        new__creation_user, 
        null,
        new__creation_ip,
        'content_item',
        'content_template',
        null,   -- title
        null,   -- description
        'text/plain',
        null,   -- nls_language
        null,   -- text
        null,   -- data
        null,   -- relation_tag
        'f',    -- is_live
        'text', -- storage_type
        null,   -- package_id
        't'     -- with_child_rels
    );  

    insert into cr_templates ( 
      template_id 
    ) values (
      v_template_id
    );

    return v_template_id;

  end if;
 
END;
$$ LANGUAGE plpgsql;




--
-- procedure content_template__new/3
--
CREATE OR REPLACE FUNCTION content_template__new(
   new__name varchar,
   new__text text,
   new__is_live bool
) RETURNS integer AS $$
--
-- content_template__new/3 maybe obsolete, when we define proper defaults for /8
--
DECLARE
BEGIN
        return content_template__new(new__name,
                                     null,
                                     null,
                                     now(),
                                     null,
                                     null,
                                     new__text,
                                     new__is_live
        );

END;
$$ LANGUAGE plpgsql;


-- old define_function_args('content_template__new','name,parent_id,template_id,creation_date;now,creation_user,creation_ip,text,is_live;f')
-- new
select define_function_args('content_template__new','name,parent_id;null,template_id;null,creation_date;now,creation_user;null,creation_ip;null,text;null,is_live;f');




--
-- procedure content_template__new/8
--
CREATE OR REPLACE FUNCTION content_template__new(
   new__name varchar,
   new__parent_id integer,         -- default null
   new__template_id integer,       -- default null
   new__creation_date timestamptz, -- default now() -- default 'now'
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__text text,                 -- default null
   new__is_live bool               -- default 'f'

) RETURNS integer AS $$
DECLARE
  v_template_id               cr_templates.template_id%TYPE;
  v_parent_id                 cr_items.parent_id%TYPE;
BEGIN

  if new__parent_id is null then
    select c_root_folder_id into v_parent_id from content_template_globals;
  else
    v_parent_id := new__parent_id;
  end if;

  -- make sure we're allowed to create a template in this folder
  if content_folder__is_folder(new__parent_id) = 't' and
    content_folder__is_registered(new__parent_id,'content_template','f') = 'f' then

    raise EXCEPTION '-20000: This folder does not allow templates to be created';

  else
    v_template_id := content_item__new (
        new__template_id,     -- new__item_id
        new__name,            -- new__name
        v_parent_id,          -- new__parent_id
        null,                 -- new__title
        new__creation_date,   -- new__creation_date
        new__creation_user,   -- new__creation_user
        null,                 -- new__context_id
        new__creation_ip,     -- new__creation_ip
        new__is_live,         -- new__is_live
        'text/plain',       -- new__mime_type
        new__text,            -- new__text
        'text',             -- new__storage_type
        't',                -- new__security_inherit_p
        'CR_FILES',         -- new__storage_area_key
        'content_item',     -- new__item_subtype
        'content_template'  -- new__content_type
    );

    insert into cr_templates ( 
      template_id 
    ) values (
      v_template_id
    );

    return v_template_id;

  end if;
 
END;
$$ LANGUAGE plpgsql;


-- procedure delete
select define_function_args('content_template__del','template_id');


--
-- procedure content_template__del/1
--
CREATE OR REPLACE FUNCTION content_template__del(
   delete__template_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  delete from cr_type_template_map
    where template_id = delete__template_id;

  delete from cr_item_template_map
    where template_id = delete__template_id;
 
  delete from cr_templates
    where template_id = delete__template_id;

  PERFORM content_item__delete(delete__template_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;

select define_function_args('content_template__delete','template_id');


--
-- procedure content_template__delete/1
--
CREATE OR REPLACE FUNCTION content_template__delete(
   delete__template_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
  PERFORM content_template__delete(delete__template_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;

-- function is_template
select define_function_args('content_template__is_template','template_id');


--
-- procedure content_template__is_template/1
--
CREATE OR REPLACE FUNCTION content_template__is_template(
   is_template__template_id integer
) RETURNS boolean AS $$
DECLARE
BEGIN
  
  return count(*) > 0 from cr_templates
    where template_id = is_template__template_id;
 
END;
$$ LANGUAGE plpgsql stable;

-- function get_path

-- old define_function_args('content_template__get_path','template_id,root_folder_id')
-- new
select define_function_args('content_template__get_path','template_id,root_folder_id;content_template_globals.c_root_folder_id');



--
-- procedure content_template__get_path/2
--
CREATE OR REPLACE FUNCTION content_template__get_path(
   template_id integer,
   root_folder_id integer -- default content_template_globals.c_root_folder_id

) RETURNS varchar AS $$
DECLARE
                                        
BEGIN

  return content_item__get_path(template_id, root_folder_id);

END;
$$ LANGUAGE plpgsql stable;



-- show errors
