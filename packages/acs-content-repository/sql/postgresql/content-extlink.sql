-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html


-- old define_function_args('content_extlink__new','name,url,label,description,parent_id,extlink_id,creation_date;now,creation_user,creation_ip,package_id')
-- new
select define_function_args('content_extlink__new','name;null,url,label;null,description;null,parent_id,extlink_id;null,creation_date;now,creation_user;null,creation_ip;null,package_id;null');




--
-- procedure content_extlink__new/10
--
CREATE OR REPLACE FUNCTION content_extlink__new(
   new__name varchar,              -- default null
   new__url varchar,
   new__label varchar,             -- default null
   new__description varchar,       -- default null
   new__parent_id integer,
   new__extlink_id integer,        -- default null
   new__creation_date timestamptz, -- default now() -- default 'now'
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__package_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_extlink_id                cr_extlinks.extlink_id%TYPE;
  v_package_id                acs_objects.package_id%TYPE;
  v_label                     cr_extlinks.label%TYPE;
  v_name                      cr_items.name%TYPE;
BEGIN

  if new__label is null then
    v_label := new__url;
  else
    v_label := new__label;
  end if;

  if new__name is null then
    select nextval('t_acs_object_id_seq') into v_extlink_id from dual;
    v_name := 'link' || v_extlink_id;
  else
    v_name := new__name;
  end if;

  if new__package_id is null then
    v_package_id := acs_object__package_id(new__parent_id);
  else
    v_package_id := new__package_id;
  end if;

  v_extlink_id := content_item__new(
      v_name, 
      new__parent_id,
      new__extlink_id,
      null,
      new__creation_date, 
      new__creation_user, 
      null,
      new__creation_ip, 
      'content_item',
      'content_extlink', 
      null,
      null,
      'text/plain',
      null,      
      null,
      null,  -- data
      null,  -- relation_tag
      'f',   -- is_live      
      'text',
      v_package_id,
      't'    -- with_child_rels
  );

  insert into cr_extlinks
    (extlink_id, url, label, description)
  values
    (v_extlink_id, new__url, v_label, new__description);

  update acs_objects
  set title = v_label
  where object_id = v_extlink_id;

  return v_extlink_id;

END;
$$ LANGUAGE plpgsql;



--
-- procedure content_extlink__new/9
--
CREATE OR REPLACE FUNCTION content_extlink__new(
   new__name varchar,              -- default null
   new__url varchar,
   new__label varchar,             -- default null
   new__description varchar,       -- default null
   new__parent_id integer,
   new__extlink_id integer,        -- default null
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar        -- default null

) RETURNS integer AS $$
--
-- content_extlink__new/9 maybe obsolete, when we define proper defaults for /10
--
DECLARE
BEGIN
  return content_extlink__new(new__name,
                              new__url,
                              new__label,
                              new__description,
                              new__parent_id,
                              new__extlink_id,
                              new__creation_date,
                              new__creation_user,
                              new__creation_ip,
                              null
  );

END;
$$ LANGUAGE plpgsql;

select define_function_args('content_extlink__delete','extlink_id');



--
-- procedure content_extlink__delete/1
--
CREATE OR REPLACE FUNCTION content_extlink__delete(
   delete__extlink_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  delete from cr_extlinks
    where extlink_id = delete__extlink_id;

  PERFORM content_item__delete(delete__extlink_id);

return 0; 
END;
$$ LANGUAGE plpgsql;

select define_function_args('content_extlink__is_extlink','item_id');


--
-- procedure content_extlink__is_extlink/1
--
CREATE OR REPLACE FUNCTION content_extlink__is_extlink(
   is_extlink__item_id integer
) RETURNS boolean AS $$
DECLARE
  v_extlink_p                        boolean;
BEGIN

  select 
    count(1) = 1 into v_extlink_p
  from 
    cr_extlinks
  where 
    extlink_id = is_extlink__item_id;
  
  return v_extlink_p;
 
END;
$$ LANGUAGE plpgsql;



--
-- procedure content_extlink__copy/4
--
CREATE OR REPLACE FUNCTION content_extlink__copy(
   copy__extlink_id integer,
   copy__target_folder_id integer,
   copy__creation_user integer,
   copy__creation_ip varchar -- default null

) RETURNS integer AS $$
--
-- content_extlink__copy/4 maybe obsolete, when we define proper defaults for /5
--
DECLARE
  v_extlink_id                 cr_extlinks.extlink_id%TYPE;
BEGIN
	v_extlink_id := content_extlink__copy (
		copy__extlink_id,
		copy__target_folder_id,
		copy__creation_user,
		copy__creation_ip,
		NULL
	);
	return 0;
END;
$$ LANGUAGE plpgsql stable;


-- old define_function_args('content_extlink__copy','extlink_id,target_folder_id,creation_user,creation_ip,name')
-- new
select define_function_args('content_extlink__copy','extlink_id,target_folder_id,creation_user,creation_ip;null,name');



--
-- procedure content_extlink__copy/5
--
CREATE OR REPLACE FUNCTION content_extlink__copy(
   copy__extlink_id integer,
   copy__target_folder_id integer,
   copy__creation_user integer,
   copy__creation_ip varchar, -- default null
   copy__name varchar

) RETURNS integer AS $$
DECLARE
  v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_url                        cr_extlinks.url%TYPE;
  v_description                cr_extlinks.description%TYPE;
  v_label                      cr_extlinks.label%TYPE;
  v_extlink_id                 cr_extlinks.extlink_id%TYPE;
BEGIN

  if content_folder__is_folder(copy__target_folder_id) = 't' then
    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy__extlink_id;

    -- can't copy to the same folder

    select
      i.name, e.url, e.description, e.label
    into
      v_name, v_url, v_description, v_label
    from
      cr_extlinks e, cr_items i
    where
      e.extlink_id = i.item_id
    and
      e.extlink_id = copy__extlink_id;
	
	-- copy to a different folder, or same folder if name
	-- is different
    if copy__target_folder_id != v_current_folder_id  or ( v_name <> copy__name and copy__name is not null ) then

      if content_folder__is_registered(copy__target_folder_id,
        'content_extlink','f') = 't' then

        v_extlink_id := content_extlink__new(
            coalesce (copy__name, v_name),
            v_url,
            v_label,
            v_description,
            copy__target_folder_id,
            null,
            current_timestamp,
	    copy__creation_user,
	    copy__creation_ip,
            null
        );

      end if;
    end if;
  end if;

  return 0; 
END;
$$ LANGUAGE plpgsql stable;




