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
                        references acs_objects (object_id),
        tree_sortkey    varbit
);

create index site_nodes_object_id_idx on site_nodes (object_id);
create index site_nodes_parent_object_node_id_idx on site_nodes(parent_id, object_id, node_id);
create index site_nodes_tree_skey_idx on site_nodes (tree_sortkey);
create index site_nodes_parent_id_idx on site_nodes(parent_id);


--
-- procedure site_node_get_tree_sortkey/1
--
select define_function_args('site_node_get_tree_sortkey','node_id');

CREATE OR REPLACE FUNCTION site_node_get_tree_sortkey(
   p_node_id integer
) RETURNS varbit AS $$
DECLARE
BEGIN
  return tree_sortkey from site_nodes where node_id = p_node_id;
END;
$$ LANGUAGE plpgsql stable strict;



--
-- procedure site_node_insert_tr/0
--
CREATE OR REPLACE FUNCTION site_node_insert_tr(

) RETURNS trigger AS $$
DECLARE
        v_parent_sk     varbit default null;
        v_max_value     integer;
BEGIN
        if new.parent_id is null then
            select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value 
              from site_nodes 
             where parent_id is null;
        else
            select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value 
              from site_nodes 
             where parent_id = new.parent_id;

            select tree_sortkey into v_parent_sk 
              from site_nodes 
             where node_id = new.parent_id;
        end if;

        new.tree_sortkey := tree_next_key(v_parent_sk, v_max_value);

        return new;

END;
$$ LANGUAGE plpgsql;

create trigger site_node_insert_tr before insert 
on site_nodes for each row 
execute procedure site_node_insert_tr ();



--
-- procedure site_node_update_tr/0
--
CREATE OR REPLACE FUNCTION site_node_update_tr(

) RETURNS trigger AS $$
DECLARE
        v_parent_sk     varbit default null;
        v_max_value     integer;
        p_id            integer;
        v_rec           record;
        clr_keys_p      boolean default 't';
BEGIN
        if new.node_id = old.node_id and 
           ((new.parent_id = old.parent_id) or 
            (new.parent_id is null and old.parent_id is null)) then

           return new;

        end if;

        for v_rec in select node_id
                       from site_nodes 
                      where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey)
                   order by tree_sortkey
        LOOP
            if clr_keys_p then
               update site_nodes set tree_sortkey = null
               where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);
               clr_keys_p := 'f';
            end if;
            
            select parent_id into p_id
              from site_nodes 
             where node_id = v_rec.node_id;

            if p_id is null then
                select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
                  from site_nodes
                 where parent_id is null;
            else
                select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
                  from site_nodes 
                 where parent_id = p_id;

                select tree_sortkey into v_parent_sk 
                  from site_nodes 
                 where node_id = p_id;
            end if;

            update site_nodes 
               set tree_sortkey = tree_next_key(v_parent_sk, v_max_value)
             where node_id = v_rec.node_id;

        end LOOP;

        return new;

END;
$$ LANGUAGE plpgsql;

create trigger site_node_update_tr after update 
on site_nodes
for each row 
execute procedure site_node_update_tr ();


-- create or replace package site_node
-- as
-- 
--   -- Create a new site node. If you set directory_p to be 'f' then you
--   -- cannot create nodes that have this node as their parent.
-- 
--   function new (
--     node_id             in site_nodes.node_id%TYPE default null,
--     parent_id           in site_nodes.node_id%TYPE default null,
--     name                in site_nodes.name%TYPE,
--     object_id           in site_nodes.object_id%TYPE default null,
--     directory_p         in site_nodes.directory_p%TYPE,
--     pattern_p           in site_nodes.pattern_p%TYPE default 'f',
--     creation_user       in acs_objects.creation_user%TYPE default null,
--     creation_ip         in acs_objects.creation_ip%TYPE default null
--   ) return site_nodes.node_id%TYPE;
-- 
--   -- Delete a site node.
-- 
--   procedure delete (
--     node_id             in site_nodes.node_id%TYPE
--   );
-- 
--   -- Return the node_id of a url. If the url begins with '/' then the
--   -- parent_id must be null. This will raise the no_data_found
--   -- exception if there is no mathing node in the site_nodes table.
--   -- This will match directories even if no trailing slash is included
--   -- in the url.
-- 
--   function node_id (
--     url                 in varchar2,
--     parent_id   in site_nodes.node_id%TYPE default null
--   ) return site_nodes.node_id%TYPE;
-- 
--   -- Return the url of a node_id.
-- 
--   function url (
--     node_id             in site_nodes.node_id%TYPE
--   ) return varchar2;
-- 
-- end;

-- show errors


-- old define_function_args ('site_node__new', 'node_id,parent_id,name,object_id,directory_p,pattern_p,creation_user,creation_ip')
-- new
select define_function_args('site_node__new','node_id;null,parent_id;null,name,object_id;null,directory_p,pattern_p;f,creation_user;null,creation_ip;null');




--
-- procedure site_node__new/8
--
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
        BEGIN
            return ( With RECURSIVE site_nodes_recursion(parent_id, path, directory_p, node_id) as (
            
                select parent_id, ARRAY[name || case when directory_p then '/' else ' ' end]::text[] as path, directory_p, node_id
                from site_nodes where node_id = url__node_id
            
                UNION ALL
            
                select sn.parent_id, sn.name::text || snr.path , sn.directory_p, snr.parent_id
                from site_nodes sn join site_nodes_recursion snr on sn.node_id = snr.parent_id 
                where snr.parent_id is not null    

            ) select array_to_string(path,'/') from site_nodes_recursion where parent_id is null
        );
        END; 
        $$ LANGUAGE plpgsql; 

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

