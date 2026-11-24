-- Restore full constructors missing on some historically upgraded sites.
-- Keep the shorter signatures for existing direct callers.
select define_function_args('content_extlink__new','name;null,url,label;null,description;null,parent_id,extlink_id;null,creation_date;now,creation_user;null,creation_ip;null,package_id;null');

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

select define_function_args('content_symlink__new','name;null,label;null,target_id,parent_id,symlink_id;null,creation_date;now,creation_user;null,creation_ip;null,package_id;null');

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

select define_function_args('content_symlink__copy','symlink_id,target_folder_id,creation_user,creation_ip;null,name;null');

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
    if copy__target_folder_id != v_current_folder_id  or ( v_name <> copy__name and copy__name is not null ) then
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

-- The scratch content test is not part of normal repository installs.
delete from acs_function_args a
 where a.function in (
     'CONTENT_TEST__SAVE_VAL'
 )
   and not exists (
       select 1 from pg_proc p where p.proname = lower(a.function)
   );

-- CMS used to leave permission function registrations behind.
delete from acs_function_args a
 where a.function in (
     'CONTENT_PERMISSION__GRANT_PERMISSION',
     'CONTENT_PERMISSION__GRANT_PERMISSION_H',
     'CONTENT_PERMISSION__HAS_GRANT_AUTHORITY',
     'CONTENT_PERMISSION__HAS_REVOKE_AUTHORITY',
     'CONTENT_PERMISSION__INHERIT_PERMISSIONS',
     'CONTENT_PERMISSION__PERMISSION_P',
     'CONTENT_PERMISSION__REVOKE_PERMISSION',
     'CONTENT_PERMISSION__REVOKE_PERMISSION_H'
 )
   and not exists (
       select 1 from pg_proc p where p.proname = lower(a.function)
   )
   and not exists (
       select 1 from apm_package_versions where package_key = 'cms' and installed_p = 't'
   )
   and not exists (
       select 1 from apm_packages where package_key = 'cms'
   );
