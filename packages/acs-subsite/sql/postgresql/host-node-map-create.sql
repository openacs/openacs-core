-- @author Mark Dettinger (mdettinger@arsdigita.com)

create table host_node_map (
   host                 varchar(200),
   node_id              integer 
			constraint host_node_map_pk primary key
			constraint host_node_map_fk references acs_objects (object_id)
);
