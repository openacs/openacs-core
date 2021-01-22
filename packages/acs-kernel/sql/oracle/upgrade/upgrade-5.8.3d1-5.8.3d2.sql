
drop index site_nodes_parent_id_idx;
create index site_nodes_parent_obj_node_idx on site_nodes(parent_id, object_id, node_id);
create index site_nodes_parent_id_idx on site_nodes(parent_id);
create index site_node_obj_map_node_id_idx on site_node_object_mappings(node_id);

