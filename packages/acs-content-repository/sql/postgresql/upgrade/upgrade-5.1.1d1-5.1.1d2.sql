-- 

-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2004-05-05
-- @cvs-id $Id$
--
-- fix typo in trigger function bug#1791
drop trigger cr_items_tree_update_tr on cr_items;
drop function cr_items_tree_update_tr();
create function cr_items_tree_update_tr () returns opaque as '
declare
        v_parent_sk     varbit default null;
        v_max_value     integer;
        p_id            integer;
        v_rec           record;
        clr_keys_p      boolean default ''t'';
begin
        if new.item_id = old.item_id and 
           ((new.parent_id = old.parent_id) or
            (new.parent_id is null and old.parent_id is null)) then

           return new;

        end if;

        for v_rec in select item_id
                       from cr_items 
                      where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey)
                   order by tree_sortkey
        LOOP
            if clr_keys_p then
               update cr_items set tree_sortkey = null
               where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);
               clr_keys_p := ''f'';
            end if;
            
            -- Lars: If the parent is not a cr_item, we treat it as if it was null.
            select parent.item_id 
              into p_id
              from cr_items parent, 
                   cr_items child
             where child.item_id = v_rec.item_id
             and   parent.item_id = child.parent_id;

            if p_id is null then 

                -- Lars: Treat all items with a non-cr_item parent as one big pool wrt tree_sortkeys
                -- The old algorithm had tree_sortkeys start from zero for each different parent

                select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
                  from cr_items child
                 where child.parent_id not in (select item_id from cr_items);
            else 
                select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
                  from cr_items 
                 where parent_id = p_id;

                select tree_sortkey into v_parent_sk 
                  from cr_items 
                 where item_id = p_id;
            end if;

            update cr_items 
               set tree_sortkey = tree_next_key(v_parent_sk, v_max_value)
             where item_id = v_rec.item_id;

        end LOOP;

        return new;

end;' language 'plpgsql';

create trigger cr_items_tree_update_tr after update 
on cr_items
for each row 
execute procedure cr_items_tree_update_tr ();

-- Fix typo in function and invalid parameter reference. Bug #1793

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
