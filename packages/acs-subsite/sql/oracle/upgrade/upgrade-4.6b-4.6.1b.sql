-- @author Eric Lorenzo (eric@openforce.net)

-- This has not been tested.
alter table host_node_map drop primary key;

alter table host_node_map add ( constraint host_node_map_pk primary key ( host ) );