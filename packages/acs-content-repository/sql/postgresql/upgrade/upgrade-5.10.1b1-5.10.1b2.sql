
-- Fix content_item__get_virtual_path so that
-- get_virtual_path__root_folder_id is not ignored

select define_function_args('content_item__get_virtual_path','item_id,root_folder_id;null');

CREATE OR REPLACE FUNCTION content_item__get_virtual_path(
   get_virtual_path__item_id integer,
   get_virtual_path__root_folder_id integer
) RETURNS varchar AS $$
DECLARE
  v_path                                  varchar;
  v_item_id                               cr_items.item_id%TYPE;
  v_is_folder                             boolean;
  v_index                                 cr_items.item_id%TYPE;
BEGIN
  -- first resolve the item
  v_item_id := content_symlink__resolve(get_virtual_path__item_id);

  v_is_folder := content_folder__is_folder(v_item_id);
  v_index := content_folder__get_index_page(v_item_id);

  -- if the folder has an index page
  if v_is_folder = 't' and v_index is not null then
    v_path := content_item__get_path(content_symlink__resolve(v_index), get_virtual_path__root_folder_id);
  else
    v_path := content_item__get_path(v_item_id, get_virtual_path__root_folder_id);
  end if;

  return v_path;

END;
$$ LANGUAGE plpgsql;
