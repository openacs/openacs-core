-- @author Mark Dettinger (mdettinger@arsdigita.com)

create table host_node_map (
   host                 varchar(200),
   node_id              integer 
			constraint host_node_map_node_id_fk
                        references acs_objects (object_id)
                        constraint host_node_map_node_id_pk
                        primary key
);
