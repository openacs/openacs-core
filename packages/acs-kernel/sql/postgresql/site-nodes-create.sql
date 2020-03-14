--
-- packages/acs-kernel/sql/site-nodes-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-09-05
-- @cvs-id $Id$
--


--
-- procedure inline_0/0
--
CREATE OR REPLACE FUNCTION inline_0(

) RETURNS integer AS $$
DECLARE
        dummy   integer;
BEGIN
  PERFORM acs_object_type__create_type (
    'site_node',
    'Site Node',
    'Site Nodes',
    'acs_object',
    'site_nodes',
    'node_id',
    'site_node',
    'f',
    null,
    null
    );

  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_0 ();

drop function inline_0 ();


-- This table allows urls to be mapped to a node_ids.

create table site_nodes (
        node_id         integer constraint site_nodes_node_id_fk
                        references acs_objects (object_id)
                        constraint site_nodes_node_id_pk
                        primary key,
        parent_id       integer constraint site_nodes_parent_id_fk
                        references site_nodes (node_id),
        name            text
                        constraint site_nodes_name_ck
                        check (name not like '%/%'),
        constraint site_nodes_un
        unique (parent_id, name),
        -- Is it legal to create a child node?
        directory_p     boolean not null,
        -- Should urls that are logical children of this node be
        -- mapped to this node?
        pattern_p       boolean default false not null,
        object_id       integer constraint site_nodes_object_id_fk
                        references acs_objects (object_id)
);

create index site_nodes_object_id_idx on site_nodes (object_id);
create index site_nodes_parent_object_node_id_idx on site_nodes(parent_id, object_id, node_id);
create index site_nodes_parent_id_idx on site_nodes(parent_id);

-- 
-- procedure site_node__new/8
-- 

select define_function_args('site_node__new','node_id;null,parent_id;null,name,object_id;null,directory_p,pattern_p;f,creation_user;null,creation_ip;null');


CREATE OR REPLACE FUNCTION site_node__new(
   new__node_id integer,       -- default null
   new__parent_id integer,     -- default null
   new__name varchar,
   new__object_id integer,     -- default null
   new__directory_p boolean,
   new__pattern_p boolean,     -- default 'f'
   new__creation_user integer, -- default null
   new__creation_ip varchar    -- default null

) RETURNS integer AS $$
DECLARE
  v_node_id                   site_nodes.node_id%TYPE;
  v_directory_p               site_nodes.directory_p%TYPE;
BEGIN
    if new__parent_id is not null then
      select directory_p into v_directory_p
      from site_nodes
      where node_id = new__parent_id;

      if v_directory_p = 'f' then
        raise EXCEPTION '-20000: Node % is not a directory', new__parent_id;
      end if;
    end if;

    v_node_id := acs_object__new (
      new__node_id,
      'site_node',
      now(),
      new__creation_user,
      new__creation_ip,
      null,
      't',
      new__name,
      new__object_id
    );

    insert into site_nodes
     (node_id, parent_id, name, object_id, directory_p, pattern_p)
    values
     (v_node_id, new__parent_id, new__name, new__object_id,
      new__directory_p, new__pattern_p);

     return v_node_id;
   
END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('site_node__delete','node_id');

--
-- procedure site_node__delete/1
--
CREATE OR REPLACE FUNCTION site_node__delete(
   delete__node_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    delete from site_nodes
    where node_id = delete__node_id;

    PERFORM acs_object__delete(delete__node_id);

    return 0; 
END;
$$ LANGUAGE plpgsql;


-- function find_pattern


-- added
select define_function_args('site_node__find_pattern','node_id');

--
-- procedure site_node__find_pattern/1
--
CREATE OR REPLACE FUNCTION site_node__find_pattern(
   find_pattern__node_id integer
) RETURNS integer AS $$
DECLARE
  v_pattern_p                   site_nodes.pattern_p%TYPE;
  v_parent_id                   site_nodes.node_id%TYPE;
BEGIN
    if find_pattern__node_id is null then
--      raise no_data_found;
        raise exception 'NO DATA FOUND';
    end if;

    select pattern_p, parent_id into v_pattern_p, v_parent_id
    from site_nodes
    where node_id = find_pattern__node_id;

    if v_pattern_p = 't' then
      return find_pattern__node_id;
    else
      return site_node__find_pattern(v_parent_id);
    end if;
   
END;
$$ LANGUAGE plpgsql;



select define_function_args('site_node__node_id','url,parent_id;null');
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
      -- No slash found
      --
      v_first := v_url;
      v_rest := null;
    else
      --
      -- Split URL
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



select define_function_args('site_node__url','node_id');
--
-- procedure site_node__url/1
--

CREATE FUNCTION inline_0()
RETURNS integer AS $inline_0$
BEGIN

    raise notice 'starting site-nodes doing the recursive part -- vguerra';

    IF cmp_pg_version('8.4') >= 0 THEN
        -- recursive site_nodes recursive - START

        CREATE OR REPLACE FUNCTION site_node__url(
           url__node_id integer
        ) RETURNS varchar AS $$

            WITH RECURSIVE site_nodes_path(parent_id, path, directory_p, node_id) as (
            
                select parent_id, ARRAY[name || case when directory_p then '/' else ' ' end]::text[] as path, directory_p, node_id
                from site_nodes where node_id = url__node_id
            
                UNION ALL
            
                select sn.parent_id, sn.name::text || snr.path , sn.directory_p, snr.parent_id
                from site_nodes sn join site_nodes_path snr on sn.node_id = snr.parent_id 
                where snr.parent_id is not null    

            ) select array_to_string(path,'/') from site_nodes_path where parent_id is null

        $$ LANGUAGE sql strict stable; 

        -- recursive site_nodes END
    
    ELSE

        CREATE OR REPLACE FUNCTION site_node__url(
           url__node_id integer
        ) RETURNS varchar AS $$
        DECLARE
          v_parent_id            site_nodes.node_id%TYPE;
          v_name                 site_nodes.name%TYPE;
          v_directory_p          site_nodes.directory_p%TYPE;
        BEGIN
            if url__node_id is null then
              return '';
            end if;

            select parent_id, name, directory_p into
                   v_parent_id, v_name, v_directory_p
            from site_nodes
            where node_id = url__node_id;

            if v_directory_p = 't' then
              return site_node__url(v_parent_id) || v_name || '/';
            else
              return site_node__url(v_parent_id) || v_name;
            end if;
           
        END;
        $$ LANGUAGE plpgsql;

    END IF;
    
    return null;
END; 
$inline_0$ LANGUAGE plpgsql;

select inline_0();
drop function inline_0();

