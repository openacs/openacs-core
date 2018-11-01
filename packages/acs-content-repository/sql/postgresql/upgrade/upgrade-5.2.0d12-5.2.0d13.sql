--
-- daveb fixes for content_folder__move.
-- 
select define_function_args('content_folder__move','folder_id,target_folder_id,name;NULL');

create or replace function content_folder__move (integer,integer,varchar)
returns integer as '
declare
  move__folder_id              alias for $1;  
  move__target_folder_id       alias for $2;
  move__name                   alias for $3;
  v_source_folder_id           integer;       
  v_valid_folders_p            integer;
begin

  select 
    count(*)
  into 
    v_valid_folders_p
  from 
    cr_folders
  where
    folder_id = move__target_folder_id
  or 
    folder_id = move__folder_id;

  if v_valid_folders_p != 2 then
    raise EXCEPTION ''-20000: content_folder.move - Not valid folder(s)'';
  end if;

  if move__folder_id = content_item__get_root_folder(null) or
    move__folder_id = content_template__get_root_folder() then
    raise EXCEPTION ''-20000: content_folder.move - Cannot move root folder'';
  end if;
  
  if move__target_folder_id = move__folder_id then
    raise EXCEPTION ''-20000: content_folder.move - Cannot move a folder to itself'';
  end if;

  if content_folder__is_sub_folder(move__folder_id, move__target_folder_id) = ''t'' then
    raise EXCEPTION ''-20000: content_folder.move - Destination folder is subfolder'';
  end if;

  if content_folder__is_registered(move__target_folder_id,''content_folder'',''f'') != ''t'' then
    raise EXCEPTION ''-20000: content_folder.move - Destination folder does not allow subfolders'';
  end if;

  select parent_id into v_source_folder_id from cr_items 
    where item_id = move__folder_id;

   -- update the parent_id for the folder
   update cr_items 
     set parent_id = move__target_folder_id,
         name = coalesce ( move__name, name )
     where item_id = move__folder_id;

  -- update the has_child_folders flags

  -- update the source
  update cr_folders set has_child_folders = ''f'' 
    where folder_id = v_source_folder_id and not exists (
      select 1 from cr_items 
        where parent_id = v_source_folder_id 
          and content_type = ''content_folder'');

  -- update the destination
  update cr_folders set has_child_folders = ''t''
    where folder_id = move__target_folder_id;

  return 0; 
end;' language 'plpgsql';

create or replace function content_folder__move (integer,integer)
returns integer as '
declare
  move__folder_id              alias for $1;  
  move__target_folder_id       alias for $2;  
begin

  perform content_folder__move (
                                move__folder_id,
                                move__target_folder_id,
                                NULL
                               );
  return null;
end;' language 'plpgsql';


create or replace function content_folder__copy (integer,integer,integer,varchar)
returns integer as '
declare
  copy__folder_id              alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null  
  v_valid_folders_p            integer;        
  v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_label                      cr_folders.label%TYPE;
  v_description                cr_folders.description%TYPE;
  v_new_folder_id              cr_folders.folder_id%TYPE;
  v_folder_contents_val        record;
begin
	v_new_folder_id := content_folder__copy (
			copy__folder_id,
			copy__target_folder_id,
			copy__creation_user,
			copy__creation_ip,
			NULL
			);
	return v_new_folder_id;
end;' language 'plpgsql';

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

  select
    parent_id
  into
    v_current_folder_id
  from
    cr_items
  where
    item_id = copy__folder_id;  

  if copy__folder_id = content_item__get_root_folder(null) 
     or copy__folder_id = content_template__get_root_folder() 
     or copy__target_folder_id = copy__folder_id then
    v_valid_folders_p := 0;
  end if;

    -- get the source folder info
    select
      name, label, description
    into
      v_name, v_label, v_description
    from 
      cr_items i, cr_folders f
    where
      f.folder_id = i.item_id
    and
      f.folder_id = copy__folder_id;

  if v_valid_folders_p = 2 then 

    if content_folder__is_sub_folder(copy__folder_id, copy__target_folder_id) != ''t'' or v_current_folder_id != copy__target_folder_id or (v_name != copy__name and copy__name is not null) then 

      -- create the new folder
      v_new_folder_id := content_folder__new (
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
    end if;
  end if;

  return 0; 
end;' language 'plpgsql';


create or replace function content_revision__copy (integer,integer,integer,integer,varchar)
returns integer as '
declare
  copy__revision_id            alias for $1;  
  copy__copy_id                alias for $2;  -- default null  
  copy__target_item_id         alias for $3;  -- default null
  copy__creation_user          alias for $4;  -- default null
  copy__creation_ip            alias for $5;  -- default null
  v_copy_id                    cr_revisions.revision_id%TYPE;
  v_target_item_id             cr_items.item_id%TYPE;
  type_rec                     record;
begin
  -- use the specified item_id or the item_id of the original revision 
  --   if none is specified
  if copy__target_item_id is null then
    select item_id into v_target_item_id from cr_revisions 
      where revision_id = copy__revision_id;
  else
    v_target_item_id := copy__target_item_id;
  end if;

  -- use the copy_id or generate a new copy_id if none is specified
  --   the copy_id is a revision_id
  if copy__copy_id is null then
    select acs_object_id_seq.nextval into v_copy_id from dual;
  else
    v_copy_id := copy__copy_id;
  end if;

  -- create the basic object
  insert into acs_objects (
                 object_id,
                 object_type,
                 context_id,
                 security_inherit_p,
                 creation_user,
                 creation_date,
                 creation_ip,
                 last_modified,
                 modifying_user,
                 modifying_ip,
                 title,
                 package_id)
       select
         v_copy_id as object_id,
         object_type,
         v_target_item_id,
         security_inherit_p,
         copy__creation_user as creation_user,
         now() as creation_date,
         copy__creation_ip as creation_ip,
         now() as last_modified,
         copy__creation_user as modifying_user,
         copy__creation_ip as modifying_ip,
         title,
         package_id
       from
         acs_objects
       where
         object_id = copy__revision_id;

  -- create the basic revision (using v_target_item_id)
  insert into cr_revisions 
      select 
        v_copy_id as revision_id, 
        v_target_item_id as item_id, 
        title, 
        description, 
        publish_date, 
        mime_type, 
        nls_language, 
        lob,
	content,
        content_length
      from 
        cr_revisions 
      where
        revision_id = copy__revision_id;

  -- iterate over the ancestor types and copy attributes
  for type_rec in select ot2.object_type, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2, acs_objects o
                  where ot2.object_type <> ''acs_object''                       
                    and ot2.object_type <> ''content_revision''
                    and o.object_id = copy__revision_id 
                    and ot1.object_type = o.object_type 
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by level desc
  LOOP
    PERFORM content_revision__copy_attributes(type_rec.object_type, 
                                              copy__revision_id, v_copy_id);
  end loop;

  return v_copy_id;
 
end;' language 'plpgsql';



select define_function_args('content_item__copy','item_id,target_folder_id,creation_user,creation_ip,name');
create or replace function content_item__copy (
	integer,
	integer,
	integer,
	varchar,
	varchar
) returns integer as '
declare
  copy__item_id                alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null  
  copy__name                   alias for $5; -- default null
  v_current_folder_id           cr_folders.folder_id%TYPE;
  v_num_revisions               integer;       
  v_name                        cr_items.name%TYPE;
  v_content_type                cr_items.content_type%TYPE;
  v_locale                      cr_items.locale%TYPE;
  v_item_id                     cr_items.item_id%TYPE;
  v_revision_id                 cr_revisions.revision_id%TYPE;
  v_is_registered               boolean;
  v_old_revision_id             cr_revisions.revision_id%TYPE;
  v_new_revision_id             cr_revisions.revision_id%TYPE;
  v_old_live_revision_id             cr_revisions.revision_id%TYPE;
  v_new_live_revision_id             cr_revisions.revision_id%TYPE;
  v_storage_type                cr_items.storage_type%TYPE;
begin

  -- call content_folder.copy if the item is a folder
  if content_folder__is_folder(copy__item_id) = ''t'' then
    PERFORM content_folder__copy(
        copy__item_id,
        copy__target_folder_id,
        copy__creation_user,
        copy__creation_ip,
	copy__name
    ); 

  -- call content_symlink.copy if the item is a symlink
  else if content_symlink__is_symlink(copy__item_id) = ''t'' then
    PERFORM content_symlink__copy(
        copy__item_id,
        copy__target_folder_id,
        copy__creation_user,
        copy__creation_ip,
	copy__name
    );

  -- call content_extlink.copy if the item is a URL
  else if content_extlink__is_extlink(copy__item_id) = ''t'' then
    PERFORM content_extlink__copy(
        copy__item_id,
        copy__target_folder_id,
        copy__creation_user,
        copy__creation_ip,
	copy__name
    );

  -- make sure the target folder is really a folder
  else if content_folder__is_folder(copy__target_folder_id) = ''t'' then

    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy__item_id;

    select
      content_type, name, locale,
      coalesce(live_revision, latest_revision), storage_type
    into
      v_content_type, v_name, v_locale, v_revision_id, v_storage_type
    from
      cr_items
    where
      item_id = copy__item_id;

-- copy to a different folder, or allow copy to the same folder
-- with a different name

    if copy__target_folder_id != v_current_folder_id  or ( v_name != copy__name and copy__name is not null ) then
      -- make sure the content type of the item is registered to the folder
      v_is_registered := content_folder__is_registered(
          copy__target_folder_id,
          v_content_type,
          ''f''
      );

      if v_is_registered = ''t'' then
        -- create the new content item
        v_item_id := content_item__new(
            coalesce (copy__name, v_name),
            copy__target_folder_id,
            null,
            v_locale,
            now(),
            copy__creation_user,
            null,
            copy__creation_ip,
            ''content_item'',            
            v_content_type,
            null,
            null,
            ''text/plain'',
            null,
            null,
            v_storage_type
        );

	select
          latest_revision, live_revision into v_old_revision_id, v_old_live_revision_id
        from
       	  cr_items
        where
       	  item_id = copy__item_id;
	end if;

        -- copy the latest revision (if any) to the new item
	if v_old_revision_id is not null then
          v_new_revision_id := content_revision__copy (
              v_old_revision_id,
              null,
              v_item_id,
              copy__creation_user,
              copy__creation_ip
          );
        end if;

        -- copy the live revision (if there is one and it differs from the latest) to the new item
	if v_old_live_revision_id is not null then
          if v_old_live_revision_id <> v_old_revision_id then
            v_new_live_revision_id := content_revision__copy (
              v_old_live_revision_id,
              null,
              v_item_id,
              copy__creation_user,
              copy__creation_ip
            );
          else
            v_new_live_revision_id := v_new_revision_id;
          end if;
        end if;

        update cr_items set live_revision = v_new_live_revision, latest_revision = v_new_revision_id where item_id = v_item_id;

    end if;

  end if; end if; end if; end if;

  return v_item_id;

end;' language 'plpgsql';
