-- The index on container_id is not very good 
-- and in some cases can be quite detrimental
-- see http://openacs.org/forums/message-view?message_id=142769

drop index group_elem_idx_container_idx;

-- There is already a unique constraint on context_id, object_id so the explicitly added one 
-- is not needed...
--
drop index acs_objects_context_object_idx;

-- recreate acs_objects_get_tree_sortkey with isstrict, iscachable.
--
create or replace function acs_objects_get_tree_sortkey(integer) returns varbit as '
declare
  p_object_id    alias for $1;
begin
  return tree_sortkey from acs_objects where object_id = p_object_id;
end;' language 'plpgsql' with (isstrict, iscachable);


------------------------------------------------------------
--
--  Now update tree_sortkey in the process fix dups and add max_child_sortkey
--

-- We need a table for the new tree_sortkey
--
-- Get the root nodes specially
--
CREATE TABLE tmp_newtree as
  SELECT object_id, int_to_tree_key(object_id+1000) as tree_sortkey
    FROM acs_objects
   where context_id is null;

--now add an index on object_id since we need it for the next function...
create unique index tmp_newtree_idx on tmp_newtree(object_id);

create or replace function __tmp_newtree() returns integer as ' 
DECLARE
        ngen    integer;
        nrows   integer;
        totrows integer;
	rec     record; 
	childkey varbit;
	last_context integer;
BEGIN
    totrows := 0;
    ngen := 0;

    LOOP
        ngen := ngen + 1;
 	nrows := 0;
	last_context := -9999;

	-- loop over those which have a parent in newtree but are not themselves in newtree.
	FOR rec IN SELECT o.object_id, o.context_id, n.tree_sortkey
                     FROM acs_objects o, tmp_newtree n
                    WHERE n.object_id = o.context_id
                      and not exists (select 1 from tmp_newtree e where e.object_id = o.object_id)
                 ORDER BY o.context_id, o.object_id LOOP

	    if last_context = rec.context_id THEN 
		childkey := tree_increment_key(childkey);
            else
		childkey := tree_increment_key(null);
                last_context := rec.context_id;
	    end if;

	    insert into tmp_newtree values (rec.object_id, rec.tree_sortkey || childkey);

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

select __tmp_newtree();
drop function __tmp_newtree();

-- make sure unique constraint can be added 
ALTER TABLE tmp_newtree add constraint tmp_newtree_sk_un unique(tree_sortkey);

-- compute the new maxchilds.
CREATE TABLE tmp_maxchild as
    SELECT context_id as object_id, max(tree_leaf_key_to_int(t.tree_sortkey)) as max_child_sortkey
      FROM acs_objects o, tmp_newtree t where t.object_id = o.object_id 
     GROUP BY context_id;

create index tmp_maxchild_idx on tmp_maxchild(object_id);

-- we are going to use a unique constraint on this column now
drop index acs_objs_tree_skey_idx; 

-- Drop the triggers on acs_objects
--
-- these change anyway
--
drop trigger acs_objects_context_id_up_tr on acs_objects;
drop function acs_objects_context_id_up_tr();
drop trigger acs_objects_update_tr on acs_objects;
drop function acs_objects_update_tr();
drop trigger acs_objects_insert_tr on acs_objects;
drop function acs_objects_insert_tr();
--
-- dont want to mess up modification dates.
--
drop trigger acs_objects_last_mod_update_tr on acs_objects;
drop function acs_objects_last_mod_update_tr();


-- add the max_child_sortkey
--
alter table acs_objects add max_child_sortkey varbit;

-- Actually update the tree_sortkeys in acs_objects...
-- 
UPDATE acs_objects
   SET tree_sortkey = (select tree_sortkey from tmp_newtree n where n.object_id = acs_objects.object_id),
       max_child_sortkey = (select int_to_tree_key(max_child_sortkey) from tmp_maxchild n where n.object_id = acs_objects.object_id);

-- Drop the temp tables as we no longer need them...
--
drop table tmp_newtree;
drop table tmp_maxchild;

-- add back the unique not null constraint on tree_sortkey
-- 
ALTER TABLE acs_objects add constraint acs_objects_tree_sortkey_un unique(tree_sortkey);
ALTER TABLE acs_objects ALTER COLUMN tree_sortkey SET NOT NULL;



-- Recreate the triggers
--
create function acs_objects_last_mod_update_tr () returns opaque as '
begin
  new.last_modified := now();

  return new;

end;' language 'plpgsql';

create trigger acs_objects_last_mod_update_tr before update on acs_objects
for each row execute procedure acs_objects_last_mod_update_tr ();


create function acs_objects_insert_tr() returns opaque as '
declare
        v_parent_sk             varbit default null;
        v_max_child_sortkey     varbit;
begin
        if new.context_id is null then
            new.tree_sortkey := int_to_tree_key(new.object_id+1000);
        else
            SELECT tree_sortkey, tree_increment_key(max_child_sortkey)
            INTO v_parent_sk, v_max_child_sortkey
            FROM acs_objects
            WHERE object_id = new.context_id
            FOR UPDATE;

            UPDATE acs_objects
            SET max_child_sortkey = v_max_child_sortkey
            WHERE object_id = new.context_id;

            new.tree_sortkey := v_parent_sk || v_max_child_sortkey;
        end if;

        new.max_child_sortkey := null;
        return new;
end;' language 'plpgsql';

create trigger acs_objects_insert_tr before insert
on acs_objects for each row
execute procedure acs_objects_insert_tr ();

--
-- 

create function acs_objects_update_tr() returns opaque as '
declare
        v_parent_sk     varbit default null;
        v_max_child_sortkey	varbit;
        v_old_parent_length	integer;
begin
        if new.object_id = old.object_id and ( new.context_id = old.context_id
            or (new.context_id is null and old.context_id is null) ) then
           return new;
        end if;

	-- the tree sortkey is going to change so get the new one and update it and all its
	-- children to have the new prefix...
	v_old_parent_length := length(new.tree_sortkey) + 1;

	if new.context_id is null then
            v_parent_sk := int_to_tree_key(new.object_id+1000);
        else
	    SELECT tree_sortkey, tree_increment_key(max_child_sortkey)
	    INTO v_parent_sk, v_max_child_sortkey
            FROM acs_objects
            WHERE object_id = new.context_id
            FOR UPDATE;

	    UPDATE acs_objects
            SET max_child_sortkey = v_max_child_sortkey
  	    WHERE object_id = new.context_id;

  	    v_parent_sk := v_parent_sk || v_max_child_sortkey;
	end if;

	UPDATE acs_objects
	SET tree_sortkey = v_parent_sk || substring(tree_sortkey, v_old_parent_length)
        WHERE tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);

        return new;
end;' language 'plpgsql';

create trigger acs_objects_update_tr after update
on acs_objects
for each row
execute procedure acs_objects_update_tr ();



create or replace function acs_objects_context_id_up_tr () returns opaque as '
declare
        pair    record;
        outer record;
        inner record;
        security_context_root integer;
begin
  if new.object_id = old.object_id
     and ((new.context_id = old.context_id)
	  or (new.context_id is null and old.context_id is null))
     and new.security_inherit_p = old.security_inherit_p then
    return new;
  end if;

  -- Remove my old ancestors from my descendants.
  for outer in select object_id from acs_object_context_index where 
               ancestor_id = old.object_id and object_id <> old.object_id loop
    for inner in select ancestor_id from acs_object_context_index where
                 object_id = old.object_id and ancestor_id <> old.object_id loop
      delete from acs_object_context_index
      where object_id = outer.object_id
        and ancestor_id = inner.ancestor_id;
    end loop;
  end loop;

  -- Kill all my old ancestors.
  delete from acs_object_context_index
  where object_id = old.object_id;

  insert into acs_object_context_index
   (object_id, ancestor_id, n_generations)
  values
   (new.object_id, new.object_id, 0);

  if new.context_id is not null and new.security_inherit_p = ''t'' then
     -- Now insert my new ancestors for my descendants.
    for pair in select *
		 from acs_object_context_index
		 where ancestor_id = new.object_id 
    LOOP
      insert into acs_object_context_index
       (object_id, ancestor_id, n_generations)
      select
       pair.object_id, ancestor_id,
       n_generations + pair.n_generations + 1 as n_generations
      from acs_object_context_index
      where object_id = new.context_id;
    end loop;
  else
    security_context_root = acs__magic_object_id(''security_context_root'');
    if new.object_id != security_context_root then
    -- We need to make sure that new.OBJECT_ID and all of its
    -- children have security_context_root as an ancestor.
    for pair in  select *
		 from acs_object_context_index
		 where ancestor_id = new.object_id 
      LOOP
        insert into acs_object_context_index
         (object_id, ancestor_id, n_generations)
        values
         (pair.object_id, security_context_root, pair.n_generations + 1);
      end loop;
    end if;
  end if;

  return new;

end;' language 'plpgsql';

create trigger acs_objects_context_id_up_tr after update on acs_objects
for each row execute procedure acs_objects_context_id_up_tr ();
