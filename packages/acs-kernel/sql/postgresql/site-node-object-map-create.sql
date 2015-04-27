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
create index site_node_object_mappings_node_id_idx on site_node_object_mappings(node_id);


select define_function_args('site_node_object_map__new', 'object_id,node_id');

--
-- procedure site_node_object_map__new/2
--
CREATE OR REPLACE FUNCTION site_node_object_map__new(
   p_object_id integer,
   p_node_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    perform site_node_object_map__del(p_object_id);

    insert
    into site_node_object_mappings
    (object_id, node_id)
    values
    (p_object_id, p_node_id);

    return 0;
END;

$$ LANGUAGE plpgsql;

select define_function_args('site_node_object_map__del', 'object_id');



--
-- procedure site_node_object_map__del/1
--
CREATE OR REPLACE FUNCTION site_node_object_map__del(
   p_object_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    delete
    from site_node_object_mappings
    where object_id = p_object_id;

    return 0;
END;

$$ LANGUAGE plpgsql;
