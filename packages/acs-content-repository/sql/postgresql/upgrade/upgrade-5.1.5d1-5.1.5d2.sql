-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2005-01-13
-- @arch-tag: aa216b34-3586-400c-a3d3-50ca61ea5855
-- @cvs-id $Id$
--

create or replace function content_folder__is_sub_folder (integer,integer)
returns boolean as '
declare
  is_sub_folder__folder_id              alias for $1;  
  is_sub_folder__target_folder_id       alias for $2;  
  v_parent_id                           integer default 0;       
  v_sub_folder_p                        boolean default ''f'';           
  v_rec                                 record;
begin

  if is_sub_folder__folder_id = content_item__get_root_folder(null) or
    is_sub_folder__folder_id = content_template__get_root_folder() then

    v_sub_folder_p := ''t'';
  end if;

--               select
--                 parent_id
--               from 
--                 cr_items
--               connect by
--                 prior parent_id = item_id
--               start with
--                 item_id = is_sub_folder__target_folder_id

  for v_rec in select i2.parent_id
               from cr_items i1, cr_items i2
               where i1.item_id = is_sub_folder__target_folder_id
                 and i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey)
               order by i2.tree_sortkey desc
  LOOP
    v_parent_id := v_rec.parent_id;
    exit when v_parent_id = is_sub_folder__folder_id;
    -- we did not find the folder, reset v_parent_id
    v_parent_id := 0;
  end LOOP;

  if v_parent_id != 0 then 
    v_sub_folder_p := ''t'';
  end if;

  return v_sub_folder_p;
 
end;' language 'plpgsql'; 
