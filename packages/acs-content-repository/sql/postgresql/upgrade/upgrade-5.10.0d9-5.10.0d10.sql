--
-- use recursive query and bottom up logic to improve the performance of the query
--

-- function is_sub_folder
select define_function_args('content_folder__is_sub_folder','folder_id,target_folder_id');


--
-- procedure content_folder__is_sub_folder/2
--
CREATE OR REPLACE FUNCTION content_folder__is_sub_folder(
   is_sub_folder__folder_id integer,
   is_sub_folder__target_folder_id integer
) RETURNS boolean AS $$
DECLARE
  v_result                              integer;
BEGIN
  With RECURSIVE parents AS (
    select item_id, parent_id from cr_items where item_id = is_sub_folder__target_folder_id
    UNION ALL
    select cr_items.item_id, cr_items.parent_id from cr_items, parents
    where cr_items.item_id = parents.parent_id
  )
  select count(*) into v_result from parents where parent_id = is_sub_folder__folder_id limit 1;

  if v_result = 0 then
    return 'f';
  else
    return 't';
  end if;
END;
$$ LANGUAGE plpgsql;

