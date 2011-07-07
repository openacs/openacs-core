-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)
-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- create or replace package body content_symlink
-- function new


-- old define_function_args('content_symlink__new','name,label,target_id,parent_id,symlink_id,creation_date;now,creation_user,creation_ip,package_id')
-- new
select define_function_args('content_symlink__new','name;null,label;null,target_id,parent_id,symlink_id;null,creation_date;now,creation_user;null,creation_ip;null,package_id;null');




--
-- procedure content_symlink__new/9
--
CREATE OR REPLACE FUNCTION content_symlink__new(
   new__name varchar,              -- default null
   new__label varchar,             -- default null
   new__target_id integer,
   new__parent_id integer,
   new__symlink_id integer,        -- default null
   new__creation_date timestamptz, -- default now() -- default 'now'
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__package_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_symlink_id                cr_symlinks.symlink_id%TYPE;
  v_package_id                acs_objects.package_id%TYPE;
  v_name                      cr_items.name%TYPE;
  v_label                     cr_symlinks.label%TYPE;
  v_ctype                     varchar;
BEGIN

  -- SOME CHECKS --

  -- 1) check that the target is now a symlink
  if content_symlink__is_symlink(new__target_id) = 't' then
    raise EXCEPTION '-20000: Cannot create a symlink to a symlink %', new__target_id;
  end if;

  -- 2) check that the parent is a folder
  if content_folder__is_folder(new__parent_id) = 'f' then
    raise EXCEPTION '-20000: The parent is not a folder';
  end if;

  -- 3) check that parent folder supports symlinks
  if content_folder__is_registered(new__parent_id,'content_symlink','f') = 'f' then
    raise EXCEPTION '-20000: This folder does not allow symlinks to be created';
  end if;

  -- 4) check that the content folder supports the target items content type
  if content_folder__is_registered(new__parent_id, content_item__get_content_type(new__target_id), 'f') = 'f' then

    v_ctype := content_item__get_content_type(new__target_id);
    raise EXCEPTION '-20000: This folder does not allow symlinks to items of type % to be created', v_ctype;
  end if;

  -- PASSED ALL CHECKS --

  -- Select default name if the name is null
  if  new__name is null or new__name = '' then
    select 
      'symlink_to_' ||  name into v_name
    from 
      cr_items
    where
       item_id =  new__target_id;
  
    if NOT FOUND then 
       v_name := null;
    end if;
  else
    v_name :=  new__name;
  end if;

  -- Select default label if the label is null
  if new__label is null then
    v_label := 'Symlink to ' || v_name;
  else
    v_label := new__label;
  end if;

  if new__package_id is null then
    v_package_id := acs_object__package_id(new__parent_id);
  else
    v_package_id := new__package_id;
  end if;

  v_symlink_id := content_item__new(
      v_name, 
      new__parent_id,
      new__symlink_id,
      null,
      new__creation_date, 
      new__creation_user, 
      null,
      new__creation_ip, 
      'content_item',
      'content_symlink', 
      null,
      null,
      'text/plain',
      null,
      null,
      'text',
      v_package_id
  );

  insert into cr_symlinks
    (symlink_id, target_id, label)
  values
    (v_symlink_id, new__target_id, v_label);

  update acs_objects
  set title = v_label
  where object_id = v_symlink_id;

  return v_symlink_id;

END;
$$ LANGUAGE plpgsql;




--
-- procedure content_symlink__new/8
--
CREATE OR REPLACE FUNCTION content_symlink__new(
   new__name varchar,              -- default null
   new__label varchar,             -- default null
   new__target_id integer,
   new__parent_id integer,
   new__symlink_id integer,        -- default null
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar        -- default null

) RETURNS integer AS $$
--
-- content_symlink__new/8 maybe obsolete, when we define proper defaults for /9
--
DECLARE
BEGIN
  return content_extlink__new(new__name,
                              new__label,
                              new__target_id,
                              new__parent_id,
                              new__symlink_id,
                              new__creation_date,
                              new__creation_user,
                              new__creation_ip,
                              null
  );

END;
$$ LANGUAGE plpgsql;

-- procedure delete
select define_function_args('content_symlink__delete','symlink_id');


--
-- procedure content_symlink__delete/1
--
CREATE OR REPLACE FUNCTION content_symlink__delete(
   delete__symlink_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  PERFORM content_symlink__del(delete__symlink_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;


select define_function_args('content_symlink__del','symlink_id');


--
-- procedure content_symlink__del/1
--
CREATE OR REPLACE FUNCTION content_symlink__del(
   del__symlink_id integer
) RETURNS integer AS $$
DECLARE
BEGIN

  delete from cr_symlinks
    where symlink_id = del__symlink_id;

  PERFORM content_item__delete(del__symlink_id);

  return 0; 
END;
$$ LANGUAGE plpgsql;



-- function is_symlink
select define_function_args('content_symlink__is_symlink','item_id');


--
-- procedure content_symlink__is_symlink/1
--
CREATE OR REPLACE FUNCTION content_symlink__is_symlink(
   is_symlink__item_id integer
) RETURNS boolean AS $$
DECLARE
  v_symlink_p                        boolean;
BEGIN

  select 
    count(*) = 1 into v_symlink_p
  from 
    cr_symlinks
  where 
    symlink_id = is_symlink__item_id;

  return v_symlink_p;  
 
END;
$$ LANGUAGE plpgsql stable;


-- procedure copy

-- old define_function_args('content_symlink__copy','symlink_id,target_folder_id,creation_user,creation_ip,name')
-- new
select define_function_args('content_symlink__copy','symlink_id,target_folder_id,creation_user,creation_ip;null,name;null');



--
-- procedure content_symlink__copy/5
--
CREATE OR REPLACE FUNCTION content_symlink__copy(
   copy__symlink_id integer,
   copy__target_folder_id integer,
   copy__creation_user integer,
   copy__creation_ip varchar, -- default null
   copy__name varchar         -- default null

) RETURNS integer AS $$
DECLARE
v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_target_id                  cr_items.item_id%TYPE;
  v_label                      cr_symlinks.label%TYPE;
  v_symlink_id                 cr_symlinks.symlink_id%TYPE;
BEGIN
  -- XXX: bug if target is not a folder this will silently fail.

  if content_folder__is_folder(copy__target_folder_id) = 't' then
    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy__symlink_id;

    -- can't copy to the same folder unless name is different

    select
      i.name, content_symlink__resolve(i.item_id), s.label
    into
      v_name, v_target_id, v_label
    from
      cr_symlinks s, cr_items i
    where
      s.symlink_id = i.item_id
    and
      s.symlink_id = copy__symlink_id;

	-- copy to a different folder, or same folder if name
	-- is different
    if copy__target_folder_id != v_current_folder_id  or ( v_name <> copy_name and copy_name is not null ) then
      if content_folder__is_registered(copy__target_folder_id,
        'content_symlink','f') = 't' then
        if content_folder__is_registered(copy__target_folder_id,
          content_item__get_content_type(content_symlink__resolve(copy__symlink_id)),'f') = 't' then

	  v_symlink_id := content_symlink__new(
              coalesce (copy__name,v_name),
	      v_label,
              v_target_id,
              copy__target_folder_id,
              null,
              now(),
	      copy__creation_user,
	      copy__creation_ip,
              null
          );


	end if;
      end if;
    end if;
  end if;

  return v_symlink_id; 
END;
$$ LANGUAGE plpgsql;



--
-- procedure content_symlink__copy/4
--
CREATE OR REPLACE FUNCTION content_symlink__copy(
   copy__symlink_id integer,
   copy__target_folder_id integer,
   copy__creation_user integer,
   copy__creation_ip varchar -- default null

) RETURNS integer AS $$
--
-- content_symlink__copy/4 maybe obsolete, when we define proper defaults for /5
--
DECLARE
  v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_target_id                  cr_items.item_id%TYPE;
  v_label                      cr_symlinks.label%TYPE;
  v_symlink_id                 cr_symlinks.symlink_id%TYPE;
BEGIN
	v_symlink_id := content_symlink__copy (
		copy__symlink_id,
		copy__target_folder_id,
	        copy__creation_user,
                copy__creation_ip,
                NULL
                );
	return v_symlink_id;
END;
$$ LANGUAGE plpgsql;

-- function resolve
select define_function_args('content_symlink__resolve','item_id');


--
-- procedure content_symlink__resolve/1
--
CREATE OR REPLACE FUNCTION content_symlink__resolve(
   resolve__item_id integer
) RETURNS integer AS $$
DECLARE
  v_target_id                     cr_items.item_id%TYPE;
BEGIN

  select
    target_id into v_target_id
  from
    cr_symlinks
  where
    symlink_id = resolve__item_id;
  
  if NOT FOUND then
     return resolve__item_id;
  else
     return v_target_id;
  end if;

END;
$$ LANGUAGE plpgsql stable strict;


-- function resolve_content_type
select define_function_args('content_symlink__resolve_content_type','item_id');


--
-- procedure content_symlink__resolve_content_type/1
--
CREATE OR REPLACE FUNCTION content_symlink__resolve_content_type(
   resolve_content_type__item_id integer
) RETURNS varchar AS $$
DECLARE
  v_content_type                               cr_items.content_type%TYPE;
BEGIN

  select 
    content_item__get_content_type(target_id) into v_content_type
  from
    cr_symlinks
  where
    symlink_id = resolve_content_type__item_id;

  return v_content_type;
 
END;
$$ LANGUAGE plpgsql stable strict;



-- show errors

-- Convenience view to simply access to symlink targets

create view cr_resolved_items as
  select
    i.parent_id, i.item_id, i.name, 
    case when s.target_id is NULL then 'f' else 't' end as is_symlink,
    coalesce(s.target_id, i.item_id) as resolved_id, s.label
  from
    cr_items i left outer join cr_symlinks s on (i.item_id = s.symlink_id);
