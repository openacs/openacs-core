--
-- Use stable and strict SQL functions for
--
--   * content_folder__is_folder
--   * content_folder__is_sub_folder, and
--   * content_folder__is_empty
--
-- with simpler boolean result.
--

--
-- procedure content_folder__is_folder/1
--
select define_function_args('content_folder__is_folder','item_id');

CREATE OR REPLACE FUNCTION content_folder__is_folder(
   item_id integer
) RETURNS boolean AS $$

  SELECT EXISTS (
    SELECT 1 from cr_folders where folder_id = item_id
  );

$$ LANGUAGE sql stable strict;

--
-- procedure content_folder__is_sub_folder/2
--
select define_function_args('content_folder__is_sub_folder','folder_id,target_folder_id');

CREATE OR REPLACE FUNCTION content_folder__is_sub_folder(
   is_sub_folder__folder_id integer,
   is_sub_folder__target_folder_id integer
) RETURNS boolean AS $$

  WITH RECURSIVE parents AS (
       select item_id, parent_id from cr_items where item_id = is_sub_folder__target_folder_id
    UNION ALL
       select cr_items.item_id, cr_items.parent_id from cr_items, parents
       where cr_items.item_id = parents.parent_id
  )
  SELECT EXISTS (
    SELECT 1 FROM parents WHERE parent_id = is_sub_folder__folder_id
  );
$$ LANGUAGE sql stable strict;


--
-- procedure content_folder__is_empty/1
--
select define_function_args('content_folder__is_empty','folder_id');

CREATE OR REPLACE FUNCTION content_folder__is_empty(
   is_empty__folder_id integer
) RETURNS boolean AS $$

  SELECT NOT EXISTS (
    SELECT 1 from cr_items where parent_id = is_empty__folder_id
  );

$$ LANGUAGE sql stable strict;
