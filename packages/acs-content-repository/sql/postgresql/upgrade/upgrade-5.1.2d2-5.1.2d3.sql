create or replace function content_item__get_context (integer)
returns integer as '
declare
  get_context__item_id                alias for $1;  
  v_context_id                        acs_objects.context_id%TYPE;
begin

  select
    context_id
  into
    v_context_id
  from
    acs_objects
  where
    object_id = get_context__item_id;

  if NOT FOUND then 
     raise EXCEPTION ''-20000: Content item % does not exist in content_item.get_context'', get_context__item_id;
  end if;

  return v_context_id;
 
end;' language 'plpgsql' stable;


-- 1) make sure we are not moving the item to an invalid location:
--   that is, the destination folder exists and is a valid folder
-- 2) make sure the content type of the content item is registered
--   to the target folder
-- 3) update the parent_id for the item
create or replace function content_item__move (integer,integer)
returns integer as '
declare
  move__item_id                alias for $1;  
  move__target_folder_id       alias for $2;
begin
  perform content_item__move(
	move__item_id,
	move__target_folder_id,
	NULL
	);
return null;
end;' language 'plpgsql';

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

  end if;

  return 0; 
end;' language 'plpgsql';
