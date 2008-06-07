--
-- a mechanism for associating location (url) with a certain chunk of data.
--
-- @author Ben Adida (ben@openforce)
-- @version $Id$
--

create table site_node_object_mappings (
    object_id                       integer
                                    constraint snom_object_id_fk
                                    references acs_objects (object_id)
                                    on update cascade on delete cascade
                                    constraint snom_object_id_nn
                                    not null
                                    constraint site_node_object_mappings_pk
                                    primary key,
    node_id                         integer
                                    constraint snom_node_id_fk
                                    references site_nodes (node_id)
                                    on update cascade on delete cascade
                                    constraint snom_node_id_nn
                                    not null
);

select define_function_args('site_node_object_map__new', 'object_id,node_id');

create function site_node_object_map__new (integer,integer)
returns integer as '
declare
    p_object_id                     alias for $1;
    p_node_id                       alias for $2;
begin
    perform site_node_object_map__del(p_object_id);

    insert
    into site_node_object_mappings
    (object_id, node_id)
    values
    (p_object_id, p_node_id);

    return 0;
end;
' language 'plpgsql';

select define_function_args('site_node_object_map__del', 'object_id');

create function site_node_object_map__del (integer)
returns integer as '
declare
    p_object_id                     alias for $1;
begin
    delete
    from site_node_object_mappings
    where object_id = p_object_id;

    return 0;
end;
' language 'plpgsql';
