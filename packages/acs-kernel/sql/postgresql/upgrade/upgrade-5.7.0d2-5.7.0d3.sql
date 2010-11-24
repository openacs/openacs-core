-- 
-- 
-- 
-- @author Victor Guerra (vguerra@gmail.com)
-- @creation-date 2010-11-15
-- @cvs-id $Id$
--

-- Avoiding the usage of the coalesce function 
-- on the site_nodes columns in the where clause
-- because this leads to usage of a sequencial scan, 
-- instead we enforce the usage of an index scan
-- by issolating the case on which we need to compare null values
-- and using the equal operator.

-- function node_id
create or replace function site_node__node_id (varchar,integer)
returns integer as '
declare
  node_id__url           alias for $1;  
  node_id__parent_id     alias for $2;  -- default null  
  v_pos                  integer;       
  v_first                site_nodes.name%TYPE;
  v_rest                 text; 
  v_node_id              integer;       
  v_pattern_p            site_nodes.pattern_p%TYPE;
  v_url                  text; 
  v_directory_p          site_nodes.directory_p%TYPE;
  v_trailing_slash_p     boolean;       
begin
    v_url := node_id__url;

    if substr(v_url, length(v_url), 1) = ''/'' then
      -- It ends with a / so it must be a directory.
      v_trailing_slash_p := ''t'';
      v_url := substr(v_url, 1, length(v_url) - 1);
    end if;

    v_pos := 1;

    while v_pos <= length(v_url) and substr(v_url, v_pos, 1) <> ''/'' loop
      v_pos := v_pos + 1;
    end loop;

    if v_pos = length(v_url) then
      v_first := v_url;
      v_rest := null;
    else
      v_first := substr(v_url, 1, v_pos - 1);
      v_rest := substr(v_url, v_pos + 1);
    end if;

    if node_id__parent_id is not null then 
      select node_id, directory_p into v_node_id, v_directory_p
      from site_nodes
      where parent_id = node_id__parent_id
      and name = v_first;
    else 
      select node_id, directory_p into v_node_id, v_directory_p
      from site_nodes
      where parent_id is null 
      and name = v_first;
    end if;

    if NOT FOUND then 
        return site_node__find_pattern(node_id__parent_id);
    end if;

    if v_rest is null then
      if v_trailing_slash_p = ''t'' and v_directory_p = ''f'' then
        return site_node__find_pattern(node_id__parent_id);
      else
        return v_node_id;
      end if;
    else
      return site_node__node_id(v_rest, v_node_id);
    end if;


end;' language 'plpgsql';

