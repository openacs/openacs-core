--
-- Replace obsolete function bittoint4() by cast
---
-- ... but keep emulation function still around in case somebodes uses
-- this still....
--


--
-- procedure tree_key_to_int/2
--
CREATE OR REPLACE FUNCTION tree_key_to_int(
   p_tree_key varbit,
   p_level integer
) RETURNS integer AS $$
-- Convert the compressed key for the node at the given level to an 
-- integer.
DECLARE
  v_level         integer default 0;
  v_parent_pos    integer default 1;
  v_pos           integer default 1;
BEGIN

  -- Find the right key first
  while v_pos < length(p_tree_key) and v_level < p_level loop
    v_parent_pos := v_pos;
    v_level := v_level + 1;
    if substring(p_tree_key, v_pos, 1) = '1' then
      v_pos := v_pos + 32;
    else
      v_pos := v_pos + 8;
    end if;
  end loop;

  if v_level < p_level then
    raise exception 'tree_key_to_int: key is at a level less than %', p_level;
  end if;

  if substring(p_tree_key, v_parent_pos, 1) = '1' then
    return substring(p_tree_key, v_parent_pos + 1, 31)::bit(31)::integer;
  else
    return substring(p_tree_key, v_parent_pos, 8)::bit(8)::integer;
  end if;

END;
$$ LANGUAGE plpgsql immutable strict;

--
-- procedure tree_leaf_key_to_int/1
--
CREATE OR REPLACE FUNCTION tree_leaf_key_to_int(
   p_tree_key varbit
) RETURNS integer AS $$
-- Convert the bitstring for the last, or leaf, node represented by this key
-- to an integer.
DECLARE
  v_leaf_pos      integer default 1;
  v_pos           integer default 1;
BEGIN

  -- Find the leaf key first
  while v_pos < length(p_tree_key) loop
    v_leaf_pos := v_pos;
    if substring(p_tree_key, v_pos, 1) = '1' then
      v_pos := v_pos + 32;
    else
      v_pos := v_pos + 8;
    end if;
  end loop;

  if substring(p_tree_key, v_leaf_pos, 1) = '1' then
    return substring(p_tree_key, v_leaf_pos + 1, 31)::bit(31)::integer;
  else
    return substring(p_tree_key, v_leaf_pos, 8)::bit(8)::integer;
  end if;

END;
$$ LANGUAGE plpgsql immutable strict;
