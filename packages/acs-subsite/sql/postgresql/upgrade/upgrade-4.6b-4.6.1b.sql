-- packages/acs-subsite/sql/postgresql/upgrade/upgrade-4.5.1-4.5.2.sql
--
-- @author Eric Lorenzo (eric@openforce.net)
-- @creation-date 2002-10-24
-- @cvs-id $Id$


-- Moving primary key constraint on host_node_map from node_id column
-- to host column.  Fortunately, nothing references the table, so a
-- simple drop-rebuild is feasable
alter table host_node_map rename to host_node_map_old;

create table host_node_map (
   host       varchar(200)
              constraint host_node_map_new_pk primary key,
   node_id    integer not null
              constraint host_node_map_new_fk references acs_objects (object_id)
);

insert into host_node_map ( host, node_id )
   select host, node_id from host_node_map_old;

drop table host_node_map_old;

