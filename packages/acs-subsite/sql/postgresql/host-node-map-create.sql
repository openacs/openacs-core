-- @author Mark Dettinger (mdettinger@arsdigita.com)
-- @author Eric Lorenzo (eric@openforce.net)

create table host_node_map (
   host         varchar(200)
                constraint host_node_map_pk primary key,
   node_id      integer not null
                constraint host_node_map_fk
                           references acs_objects (object_id)
);
