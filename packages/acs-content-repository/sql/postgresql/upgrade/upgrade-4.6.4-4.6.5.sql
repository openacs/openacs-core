create or replace function content_item__copy2 (integer,integer,integer,varchar)
returns integer as '
declare
  copy2__item_id                alias for $1;  
  copy2__target_folder_id       alias for $2;  
  copy2__creation_user          alias for $3;  
  copy2__creation_ip            alias for $4;  -- default null  
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
  v_storage_type                cr_items.storage_type%TYPE;
begin

  -- call content_folder.copy if the item is a folder
  if content_folder__is_folder(copy2__item_id) = ''t'' then
    PERFORM content_folder__copy(
        copy2__item_id,
        copy2__target_folder_id,
        copy2__creation_user,
        copy2__creation_ip
    );
  -- call content_symlink.copy if the item is a symlink
  else if content_symlink__is_symlink(copy2__item_id) = ''t'' then
    PERFORM content_symlink__copy(
        copy2__item_id,
        copy2__target_folder_id,
        copy2__creation_user,
        copy2__creation_ip
    );
  -- call content_extlink.copy if the item is an url
  else if content_extlink__is_extlink(copy2__item_id) = ''t'' then
    PERFORM content_extlink__copy(
        copy2__item_id,
        copy2__target_folder_id,
        copy2__creation_user,
        copy2__creation_ip
    );
  -- make sure the target folder is really a folder
  else if content_folder__is_folder(copy2__target_folder_id) = ''t'' then

    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy2__item_id;

    -- can''t copy to the same folder
    if copy2__target_folder_id != v_current_folder_id then

      select
        content_type, name, locale,
        coalesce(live_revision, latest_revision), storage_type
      into
        v_content_type, v_name, v_locale, v_revision_id, v_storage_type
      from
        cr_items
      where
        item_id = copy2__item_id;

      -- make sure the content type of the item is registered to the folder
      v_is_registered := content_folder__is_registered(
          copy2__target_folder_id,
          v_content_type,
          ''f''
      );

      if v_is_registered = ''t'' then
        -- create the new content item
        v_item_id := content_item__new(
            v_name,
            copy2__target_folder_id,
            null,
            v_locale,
            now(),
            copy2__creation_user,
            null,
            copy2__creation_ip,
            ''content_item'',            
            v_content_type,
            null,
            null,
            ''text/plain'',
            null,
            null,
            v_storage_type
        );

        -- get the latest revision of the old item
        select
          latest_revision into v_old_revision_id
        from
          cr_items
        where
          item_id = copy2__item_id;

        -- copy the latest revision (if any) to the new item
        if v_old_revision_id is not null then
          v_new_revision_id := content_revision__copy (
              v_old_revision_id,
              null,
              v_item_id,
              copy2__creation_user,
              copy2__creation_ip
          );
        end if;
      end if;


    end if;
  end if; end if; end if; end if;

  return v_item_id;
 
end;' language 'plpgsql';

create or replace function content_extlink__copy (integer,integer,integer,varchar)
returns integer as '
declare
  copy__extlink_id             alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null  
  v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_url                        cr_extlinks.url%TYPE;
  v_description                cr_extlinks.description%TYPE;
  v_label                      cr_extlinks.label%TYPE;
  v_extlink_id                 cr_extlinks.extlink_id%TYPE;
begin

  if content_folder__is_folder(copy__target_folder_id) = ''t'' then
    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy__extlink_id;

    -- can''t copy to the same folder
    if copy__target_folder_id != v_current_folder_id then

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

      if content_folder__is_registered(copy__target_folder_id,
        ''content_extlink'',''f'') = ''t'' then

        v_extlink_id := content_extlink__new(
            v_name,
            v_url,
            v_label,
            v_description,
            copy__target_folder_id,
            null,
            current_timestamp,
	    copy__creation_user,
	    copy__creation_ip
        );

      end if;
    end if;
  end if;

  return 0; 
end;' language 'plpgsql';

