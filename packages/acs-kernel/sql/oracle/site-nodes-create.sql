--
-- packages/acs-kernel/sql/site-nodes-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-09-05
-- @cvs-id $Id$
--

begin
  acs_object_type.create_type (
    object_type => 'site_node',
    pretty_name => 'Site Node',
    pretty_plural => 'Site Nodes',
    table_name => 'site_nodes',
    id_column => 'node_id',
    package_name => 'site_node'
  );
end;
/
show errors

-- This table allows urls to be mapped to a node_ids.

create table site_nodes (
        node_id         constraint site_nodes_node_id_fk
                        references acs_objects (object_id)
                        constraint site_nodes_node_id_pk
                        primary key,
        parent_id       constraint site_nodes_parent_id_fk
                        references site_nodes (node_id),
        name            varchar2(100)
                        constraint site_nodes_name_ck
                        check (name not like '%/%'),
        constraint site_nodes_un
        unique (parent_id, name),
        -- Is it legal to create a child node?
        directory_p     char(1) not null
                        constraint site_nodes_directory_p_ck
                        check (directory_p in ('t', 'f')),
        -- Should urls that are logical children of this node be
        -- mapped to this node?
        pattern_p       char(1) default 'f' not null
                        constraint site_nodes_pattern_p_ck
                        check (pattern_p in ('t', 'f')),
        object_id       constraint site_nodes_object_id_fk
                        references acs_objects (object_id)
);

create index site_nodes_object_id_idx on site_nodes (object_id);
create index site_nodes_parent_obj_node_idx on site_nodes(parent_id, object_id, node_id);
create index site_nodes_parent_id_idx on site_nodes(parent_id);


create or replace package site_node
as

  -- Create a new site node. If you set directory_p to be 'f' then you
  -- cannot create nodes that have this node as their parent.

  function new (
    node_id             in site_nodes.node_id%TYPE default null,
    parent_id           in site_nodes.node_id%TYPE default null,
    name                in site_nodes.name%TYPE,
    object_id           in site_nodes.object_id%TYPE default null,
    directory_p         in site_nodes.directory_p%TYPE,
    pattern_p           in site_nodes.pattern_p%TYPE default 'f',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return site_nodes.node_id%TYPE;

  -- Delete a site node.

  procedure del (
    node_id             in site_nodes.node_id%TYPE
  );

  -- Return the node_id of a url. If the url begins with '/' then the
  -- parent_id must be null. This will raise the no_data_found
  -- exception if there is no mathing node in the site_nodes table.
  -- This will match directories even if no trailing slash is included
  -- in the url.

  function node_id (
    url                 in varchar2,
    parent_id   in site_nodes.node_id%TYPE default null
  ) return site_nodes.node_id%TYPE;

  -- Return the url of a node_id.

  function url (
    node_id             in site_nodes.node_id%TYPE
  ) return varchar2;

end;
/
show errors

create or replace package body site_node
as

  function new (
    node_id             in site_nodes.node_id%TYPE default null,
    parent_id           in site_nodes.node_id%TYPE default null,
    name                in site_nodes.name%TYPE,
    object_id           in site_nodes.object_id%TYPE default null,
    directory_p         in site_nodes.directory_p%TYPE,
    pattern_p           in site_nodes.pattern_p%TYPE default 'f',
    creation_user       in acs_objects.creation_user%TYPE default null,
    creation_ip         in acs_objects.creation_ip%TYPE default null
  ) return site_nodes.node_id%TYPE
  is
    v_node_id           site_nodes.node_id%TYPE;
    v_directory_p       site_nodes.directory_p%TYPE;
  begin
    if parent_id is not null then
      select directory_p into v_directory_p
      from site_nodes
      where node_id = new.parent_id;

      if v_directory_p = 'f' then
        raise_application_error (
          -20000,
          'Node ' || parent_id || ' is not a directory'
        );
      end if;
    end if;

    v_node_id := acs_object.new (
      object_id => node_id,
      object_type => 'site_node',
      title => name,
      package_id => object_id,
      creation_user => creation_user,
      creation_ip => creation_ip
    );

    insert into site_nodes
     (node_id, parent_id, name, object_id, directory_p, pattern_p)
    values
     (v_node_id, new.parent_id, new.name, new.object_id,
      new.directory_p, new.pattern_p);

     return v_node_id;
  end;

  procedure del (
    node_id             in site_nodes.node_id%TYPE
  )
  is
  begin
    delete from site_nodes
    where node_id = site_node.del.node_id;

    acs_object.del(node_id);
  end;

  function find_pattern (
    node_id     in site_nodes.node_id%TYPE
  ) return site_nodes.node_id%TYPE
  is
    v_pattern_p site_nodes.pattern_p%TYPE;
    v_parent_id site_nodes.node_id%TYPE;
  begin
    if node_id is null then
      raise no_data_found;
    end if;

    select pattern_p, parent_id into v_pattern_p, v_parent_id
    from site_nodes
    where node_id = find_pattern.node_id;

    if v_pattern_p = 't' then
      return node_id;
    else
      return find_pattern(v_parent_id);
    end if;
  end;

  function node_id (
    url                 in varchar2,
    parent_id           in site_nodes.node_id%TYPE default null
  ) return site_nodes.node_id%TYPE
  is
    v_pos               integer;
    v_first             site_nodes.name%TYPE;
    v_rest              varchar2(4000);
    v_node_id           integer;
    v_pattern_p         site_nodes.pattern_p%TYPE;
    v_url               varchar2(4000);
    v_directory_p       site_nodes.directory_p%TYPE;
    v_trailing_slash_p  char(1);
  begin
    v_url := url;

    if substr(v_url, length(v_url), 1) = '/' then
      -- It ends with a / so it must be a directory.
      v_trailing_slash_p := 't';
      v_url := substr(v_url, 1, length(v_url) - 1);
    end if;

    v_pos := 1;

    while v_pos <= length(v_url) and substr(v_url, v_pos, 1) != '/' loop
      v_pos := v_pos + 1;
    end loop;

    if v_pos = length(v_url) then
      v_first := v_url;
      v_rest := null;
    else
      v_first := substr(v_url, 1, v_pos - 1);
      v_rest := substr(v_url, v_pos + 1);
    end if;

    begin
      -- Is there a better way to do these freaking null compares?
      select node_id, directory_p into v_node_id, v_directory_p
      from site_nodes
      where nvl(parent_id, 3.14) = nvl(site_node.node_id.parent_id, 3.14)
      and nvl(name, chr(10)) = nvl(v_first, chr(10));
    exception
      when no_data_found then
        return find_pattern(parent_id);
    end;

    if v_rest is null then
      if v_trailing_slash_p = 't' and v_directory_p = 'f' then
        return find_pattern(parent_id);
      else
        return v_node_id;
      end if;
    else
      return node_id(v_rest, v_node_id);
    end if;
  end;

  function url (
    node_id             in site_nodes.node_id%TYPE
  ) return varchar2
  is
    v_parent_id site_nodes.node_id%TYPE;
    v_name              site_nodes.name%TYPE;
    v_directory_p       site_nodes.directory_p%TYPE;
  begin
    if node_id is null then
      return '';
    end if;

    select parent_id, name, directory_p into
           v_parent_id, v_name, v_directory_p
    from site_nodes
    where node_id = url.node_id;

    if v_directory_p = 't' then
      return url(v_parent_id) || v_name || '/';
    else
      return url(v_parent_id) || v_name;
    end if;
  end;

end;
/
show errors
