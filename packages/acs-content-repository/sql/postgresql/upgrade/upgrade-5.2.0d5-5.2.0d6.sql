create or replace function content_item__move (integer,integer,varchar)
returns integer as '
declare
  move__item_id                alias for $1;  
  move__target_folder_id       alias for $2;
  move__name                   alias for $3;
begin

  if move__target_folder_id is null then 
	raise exception ''attempt to move item_id % to null folder_id'', move__item_id;
  end if;

  if content_folder__is_folder(move__item_id) = ''t'' then

    PERFORM content_folder__move(move__item_id, move__target_folder_id,move__name);

  elsif content_folder__is_folder(move__target_folder_id) = ''t'' then
   

    if content_folder__is_registered(move__target_folder_id,
          content_item__get_content_type(move__item_id),''f'') = ''t'' and
       content_folder__is_registered(move__target_folder_id,
          content_item__get_content_type(content_symlink__resolve(move__item_id)),''f'') = ''t''
      then
    -- update the parent_id for the item

    update cr_items 
      set parent_id = move__target_folder_id,
          name = coalesce(move__name, name)
      where item_id = move__item_id;
    end if;

    if move__name is not null then
      update acs_objects
        set title = move__name
        where object_id = move__item_id;
    end if;

  end if;

  return 0; 
end;' language 'plpgsql';
