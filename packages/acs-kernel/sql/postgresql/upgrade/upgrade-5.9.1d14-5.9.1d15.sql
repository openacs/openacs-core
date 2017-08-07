--
-- Changes:
--  * remove length limitation on URL segments from the data model (PostgreSQL only)
--  * function site_node__node_id()
--    + use built-in string functions instead of characterwise loop
--    + use default for last argument
--    + Improve source-code documentation
--

ALTER table site_nodes alter COLUMN name TYPE text;



DROP FUNCTION IF EXISTS site_node__node_id(varchar, integer);
--
-- procedure site_node__node_id/2
--
CREATE OR REPLACE FUNCTION site_node__node_id(
   p_url varchar,
   p_parent_id integer default null
) RETURNS integer AS $$
DECLARE
  v_pos                  integer;
  v_first                site_nodes.name%TYPE;
  v_rest                 text; 
  v_node_id              integer;       
  v_pattern_p            site_nodes.pattern_p%TYPE;
  v_url                  text; 
  v_directory_p          site_nodes.directory_p%TYPE;
  v_trailing_slash_p     boolean;       
BEGIN
    v_url := p_url;

    if substr(v_url, length(v_url), 1) = '/' then
      --
      -- The URL ends with a / so it must be a directory. Strip the
      -- trailing slash.
      --
      v_trailing_slash_p := true;
      v_url := substr(v_url, 1, length(v_url) - 1);
    end if;

    --
    -- Split the URL on the first "/" into v_first and v_rest. 
    --
    select position('/' in v_url) into v_pos;

    if v_pos = 0 then
      --
      -- No slash found.
      --
      v_first := v_url;
      v_rest := null;
    else
      --
      -- Split URL.
      --
      v_first := substr(v_url, 1, v_pos - 1);
      v_rest := substr(v_url, v_pos + 1);
    end if;

    if p_parent_id is not null then 
      select node_id, directory_p into v_node_id, v_directory_p
      from site_nodes
      where parent_id = p_parent_id
      and name = v_first;
    else
      --
      -- This is typically just the query on the (empty) top-node.
      --
      select node_id, directory_p into v_node_id, v_directory_p
      from site_nodes
      where parent_id is null 
      and name = v_first;
    end if;

    if NOT FOUND then 
        return site_node__find_pattern(p_parent_id);
    end if;

    --
    -- v_first was found. 
    --
    if v_rest is null then
      --
      -- We are at the end of the URL. If we have a trailing slash and
      -- the site node is not a directory, return the result of
      -- find_pattern(). Otherwise, return the found node_id
      --
      if v_trailing_slash_p is true and v_directory_p is false then
        return site_node__find_pattern(p_parent_id);
      else
        return v_node_id;
      end if;
    else
      --
      -- Call the function recursively on the v_rest chunk
      --
      return site_node__node_id(v_rest, v_node_id);
    end if;
END;
$$ LANGUAGE plpgsql;
