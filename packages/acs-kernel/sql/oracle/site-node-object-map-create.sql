--
-- a mechanism for associating location (url) with a certain chunk of data.
--
-- @author Ben Adida (ben@openforce)
-- @version $Id$
--

create table site_node_object_mappings (
    object_id                       constraint snom_object_id_fk
                                    references acs_objects (object_id)
                                    on delete cascade
                                    constraint site_node_object_mappings_pk
                                    primary key,
    node_id                         constraint snom_node_id_fk
                                    references site_nodes (node_id)
                                    on delete cascade
                                    constraint snom_node_id_nn
                                    not null
);
create index site_node_obj_map_node_id_idx on site_node_object_mappings(node_id);

create or replace package site_node_object_map
as

    procedure new (
        object_id in site_node_object_mappings.object_id%TYPE,
        node_id in site_node_object_mappings.node_id%TYPE
    );

    procedure del (
        object_id in site_node_object_mappings.object_id%TYPE
    );

end site_node_object_map;
/
show errors

create or replace package body site_node_object_map
as

    procedure new (
        object_id in site_node_object_mappings.object_id%TYPE,
        node_id in site_node_object_mappings.node_id%TYPE
    ) is
    begin
        del(new.object_id);

        insert
        into site_node_object_mappings
        (object_id, node_id)
        values
        (new.object_id, new.node_id);
    end new;

    procedure del (
        object_id in site_node_object_mappings.object_id%TYPE
    ) is
    begin
        delete
        from site_node_object_mappings
        where object_id = del.object_id;
    end del;

end site_node_object_map;
/
show errors
