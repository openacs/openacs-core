------------------------------------------------------------
--  Upgrade to enhance the performance of the acs-content-repository when adding / editing an 
--  cr_item, special fix for postgres to avoid using max() which is quite slow.
--  Now update tree_sortkey in the process fix dups and add max_child_sortkey
--

-- We need a table for the new tree_sortkey
--
-- Get the root nodes specially
-- Both cases, when the parent is 0  but is an cr_item, and when the parent is a non cr_item
CREATE TABLE tmp_crnewtree as
  SELECT item_id, int_to_tree_key(item_id+1000) as tree_sortkey
    FROM cr_items
   where parent_id = 0
  UNION
  SELECT cr.item_id, int_to_tree_key(cr.parent_id+1000) || int_to_tree_key(cr.item_id+1000) as tree_sortkey
    FROM cr_items cr
   where cr.parent_id <> 0
   and not exists (select 1 from cr_items cri where cri.item_id = cr.parent_id)
;

--now add an index on item_id since we need it for the next function...
create unique index tmp_crnewtree_idx on tmp_crnewtree(item_id);

create or replace function __tmp_crnewtree() returns integer as ' 
DECLARE
        ngen    integer;
        nrows   integer;
        totrows integer;
	rec     record; 
	childkey varbit;
	last_parent integer;
BEGIN
    totrows := 0;
    ngen := 0;

    LOOP
        ngen := ngen + 1;
 	nrows := 0;
	last_parent := -9999;

	-- loop over those which have a parent in crnewtree but are not themselves in crnewtree.
	FOR rec IN SELECT cr.item_id, cr.parent_id, n.tree_sortkey
                     FROM cr_items cr, tmp_crnewtree n
                    WHERE n.item_id = cr.parent_id
                      and not exists (select 1 from tmp_crnewtree e where e.item_id = cr.item_id)
                 ORDER BY cr.parent_id, cr.tree_sortkey LOOP

	    if last_parent = rec.parent_id THEN 
		childkey := tree_increment_key(childkey);
            else
		childkey := tree_increment_key(null);
                last_parent := rec.parent_id;
	    end if;

	    insert into tmp_crnewtree values (rec.item_id, rec.tree_sortkey || childkey);

	    if (nrows % 5000) = 0 and nrows > 0 then 
               raise notice ''ngen % row %'',ngen,nrows;
	    end if;
	    nrows := nrows + 1;
        END LOOP;

	totrows := totrows + nrows;
        raise notice ''ngen % totrows %'',ngen,nrows;

	if nrows = 0 then 
	    exit;
	end if;
    END LOOP;

    return totrows;
end;' language plpgsql;

select __tmp_crnewtree();
drop function __tmp_crnewtree();

-- make sure unique constraint can be added 
ALTER TABLE tmp_crnewtree add constraint tmp_crnewtree_sk_un unique(tree_sortkey);

-- compute the new maxchilds.
CREATE TABLE tmp_crmaxchild as
    SELECT parent_id as item_id, max(tree_leaf_key_to_int(t.tree_sortkey)) as max_child_sortkey
      FROM cr_items cr, tmp_crnewtree t where t.item_id = cr.item_id 
     GROUP BY parent_id;

create index tmp_crmaxchild_idx on tmp_crmaxchild(item_id);

-- we are going to use a unique constraint on this column now
drop index cr_sortkey_idx; 

-- Drop the related triggers on cr_items
--
drop trigger cr_items_tree_update_tr on cr_items;
drop function cr_items_tree_update_tr();
drop trigger cr_items_tree_insert_tr on cr_items;
drop function cr_items_tree_insert_tr();
--

-- add the max_child_sortkey
--
alter table cr_items add max_child_sortkey varbit;

-- Update the tree_sortkeys in cr_items...
-- 
UPDATE cr_items
   SET tree_sortkey = (select tree_sortkey from tmp_crnewtree n where n.item_id = cr_items.item_id),
       max_child_sortkey = (select int_to_tree_key(max_child_sortkey) from tmp_crmaxchild n where n.item_id = cr_items.item_id);

-- Drop the temp tables as we no longer need them...
--
drop table tmp_crnewtree;
drop table tmp_crmaxchild;

-- add back the unique not null constraint on tree_sortkey
-- 
ALTER TABLE cr_items add constraint cr_items_tree_sortkey_un unique(tree_sortkey);
ALTER TABLE cr_items ALTER COLUMN tree_sortkey SET NOT NULL;



-- Recreate the triggers
--

create function cr_items_tree_insert_tr () returns opaque as '
declare
    v_parent_sk      	varbit default null;
    v_max_child_sortkey varbit;
    v_parent_id      	integer default null;
begin
    select item_id
    into   v_parent_id
    from   cr_items
    where  item_id = new.parent_id;

    if new.parent_id = 0 then
	
	new.tree_sortkey := int_to_tree_key(new.item_id+1000);

    elsif v_parent_id is null then 

	new.tree_sortkey := int_to_tree_key(new.parent_id+1000) || int_to_tree_key(new.item_id+1000);

    else

	SELECT tree_sortkey, tree_increment_key(max_child_sortkey)
	INTO v_parent_sk, v_max_child_sortkey
	FROM cr_items
	WHERE item_id = new.parent_id 
	FOR UPDATE;

	UPDATE cr_items
	SET max_child_sortkey = v_max_child_sortkey
	WHERE item_id = new.parent_id;

	new.tree_sortkey := v_parent_sk || v_max_child_sortkey;

    end if;

    return new;
end;' language 'plpgsql';


create trigger cr_items_tree_insert_tr before insert 
on cr_items for each row 
execute procedure cr_items_tree_insert_tr ();

--
-- 

create function cr_items_tree_update_tr () returns opaque as '
declare
        v_parent_sk     	varbit default null;
        v_max_child_sortkey     varbit;
        v_parent_id            	integer default null;
        v_old_parent_length	integer;
begin
        if new.item_id = old.item_id and 
           ((new.parent_id = old.parent_id) or
            (new.parent_id is null and old.parent_id is null)) then

           return new;

        end if;

        select item_id
    	into   v_parent_id
	from   cr_items
	where  item_id = new.parent_id;

	-- the tree sortkey is going to change so get the new one and update it and all its
	-- children to have the new prefix...
	v_old_parent_length := length(new.tree_sortkey) + 1;

        if new.parent_id = 0 then
            v_parent_sk := int_to_tree_key(new.item_id+1000);
	elsif v_parent_id is null then 
            v_parent_sk := int_to_tree_key(new.parent_id+1000) || int_to_tree_key(new.item_id+1000);
        else
	    SELECT tree_sortkey, tree_increment_key(max_child_sortkey)
	    INTO v_parent_sk, v_max_child_sortkey
	    FROM cr_items
	    WHERE item_id = new.parent_id 
	    FOR UPDATE;

	    UPDATE cr_items
	    SET max_child_sortkey = v_max_child_sortkey
	    WHERE item_id = new.parent_id;

	    v_parent_sk := v_parent_sk || v_max_child_sortkey;
        end if;

	UPDATE cr_items
	SET tree_sortkey = v_parent_sk || substring(tree_sortkey, v_old_parent_length)
	WHERE tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);

        return new;

end;' language 'plpgsql';

create trigger cr_items_tree_update_tr after update 
on cr_items
for each row 
execute procedure cr_items_tree_update_tr ();

