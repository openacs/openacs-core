-- 
-- 
-- 
-- @author Rocael Hernandez (roc@viaro.net)
-- @creation-date 2004-09-02
-- @arch-tag: d5184853-cbe4-4860-94a8-9a60587b36eb
-- @cvs-id $Id$
--

-- create index cr_items_name on cr_items(name);

drop trigger cr_items_tree_insert_tr on cr_items;

drop function cr_items_tree_insert_tr ();

create function cr_items_tree_insert_tr () returns opaque as '
declare
    v_parent_sk      varbit default null;
    v_max_value      integer;
    v_parent_id      integer;
begin
    -- Lars: If the parent is not a cr_item, we treat it as if it was null.
    select item_id
    into   v_parent_id
    from   cr_items
    where  item_id = new.parent_id;

    if v_parent_id is null then 

        -- Lars: Treat all items with a non-cr_item parent as one big pool wrt tree_sortkeys
        -- The old algorithm had tree_sortkeys start from zero for each different parent

        select max(tree_leaf_key_to_int(child.tree_sortkey)) into v_max_value 
          from cr_items child
         where not exists (select 1 from cr_items where child.parent_id = item_id);
    else 
        select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value 
          from cr_items 
         where parent_id = new.parent_id;

        select tree_sortkey into v_parent_sk 
          from cr_items 
         where item_id = new.parent_id;
    end if;

    new.tree_sortkey := tree_next_key(v_parent_sk, v_max_value);

    return new;
end;' language 'plpgsql';

create trigger cr_items_tree_insert_tr before insert 
on cr_items for each row 
execute procedure cr_items_tree_insert_tr ();

drop trigger cr_items_tree_update_tr on cr_items;

drop function cr_items_tree_update_tr ();

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
                 where not exists (select 1 from cr_items where child.parent_id = item_id);
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
