-- @author Mark Dettinger (mdettinger@arsdigita.com)
-- $Id$

-- This has not been tested against Oracle.
create table host_node_map (
   host                 varchar(200) 
	constraint host_node_map_host_pk primary key 
	constraint host_node_map_host_nn not null,
   node_id              integer 
	constraint host_node_map_node_id_fk references site_nodes
);
