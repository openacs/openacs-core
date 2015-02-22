
drop index site_nodes_parent_id_idx;
create index site_nodes_parent_id_idx on site_nodes(parent_id);

create or replace function __create_index(name varchar, def varchar)
returns integer as $$
declare v_exists integer;
begin
  select into v_exists count(*) from pg_class where relname = name;
  if v_exists = 0 then
    execute 'create index ' || name || ' ' || def; 
  end if;
  return 1;
end;
$$ language plpgsql;

select __create_index('site_nodes_parent_object_node_id_idx','on site_nodes(parent_id, object_id, node_id)');
select __create_index('site_node_object_mappings_node_id_idx','on site_node_object_mappings(node_id)');

drop function __create_index(name varchar, def varchar);
