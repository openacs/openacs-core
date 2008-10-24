-- 
-- 
-- 
-- @author Victor Guerra (vguerra@wu-wien.ac.at)
-- @creation-date 2008-10-21
-- @cvs-id $Id$
--

create or replace function content_folder__copy (integer,integer,integer,varchar,varchar)
returns integer as '
declare
  copy__folder_id              alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null
  copy__name                   alias for $5; -- default null
  v_valid_folders_p            integer;
  v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_label                      cr_folders.label%TYPE;
  v_description                cr_folders.description%TYPE;
  v_new_folder_id              cr_folders.folder_id%TYPE;
  v_folder_contents_val        record;
begin

  if copy__folder_id = content_item__get_root_folder(null) 
     or copy__folder_id = content_template__get_root_folder() then
     raise EXCEPTION ''-20000: content_folder.copy - Not allowed to copy root folder'';
  end if;

  select 
    count(*)
  into 
    v_valid_folders_p
  from 
    cr_folders
  where
    folder_id = copy__target_folder_id
  or 
    folder_id = copy__folder_id;

  if v_valid_folders_p != 2 then 
    raise EXCEPTION ''-20000: content_folder.copy - Invalid folder(s)'';
  end if;

  if copy__target_folder_id = copy__folder_id then 
    raise EXCEPTION ''-20000: content_folder.copy - Cannot copy folder to itself'';
  end if;
  
  if content_folder__is_sub_folder(copy__folder_id, copy__target_folder_id) = ''t'' then
    raise EXCEPTION ''-20000: content_folder.copy - Destination folder is subfolder'';
  end if;

  if content_folder__is_registered(copy__target_folder_id,''content_folder'',''f'') != ''t'' then
    raise EXCEPTION ''-20000: content_folder.copy - Destination folder does not allow subfolders'';
  end if;

  -- get the source folder info
  select
    name, label, description, parent_id
  into
    v_name, v_label, v_description, v_current_folder_id
  from 
    cr_items i, cr_folders f
  where
    f.folder_id = i.item_id
  and
    f.folder_id = copy__folder_id;

  -- would be better to check if the copy__name alredy exists in the destination folder.

  if v_current_folder_id = copy__target_folder_id and (v_name = copy__name or copy__name is null) then
    raise EXCEPTION ''-20000: content_folder.copy - Destination folder is parent folder and folder alredy exists'';
  end if;

      -- create the new folder
      v_new_folder_id := content_folder__new(
          coalesce (copy__name, v_name),
	  v_label,
	  v_description,
	  copy__target_folder_id,
	  copy__target_folder_id,
          null,
          now(),
	  copy__creation_user,
	  copy__creation_ip,
          ''t'',
          null
      );

      -- copy attributes of original folder
      insert into cr_folder_type_map
        select 
          v_new_folder_id as folder_id, content_type
        from
          cr_folder_type_map map
        where
          folder_id = copy__folder_id
        and
	  -- do not register content_type if it is already registered
          not exists ( select 1 from cr_folder_type_map
	               where folder_id = v_new_folder_id 
		       and content_type = map.content_type ) ;

      -- for each item in the folder, copy it
      for v_folder_contents_val in select
                                     item_id
                                   from
                                     cr_items
                                   where
                                     parent_id = copy__folder_id 
      LOOP
        
	PERFORM content_item__copy(
	    v_folder_contents_val.item_id,
	    v_new_folder_id,
	    copy__creation_user,
	    copy__creation_ip,
            null
	);

      end loop;

  return 0; 
end;' language 'plpgsql';
