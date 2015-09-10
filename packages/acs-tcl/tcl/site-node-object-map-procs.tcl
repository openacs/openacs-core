# tcl/portal-node-mapping-procs.tcl

ad_library {
    Portal Node Mappings

    @author Ben Adida (ben@openforce.net)
    @creation-date April 2002
    @cvs-id $Id$
}

namespace eval site_node_object_map {}

ad_proc -public site_node_object_map::new {
    {-object_id:required}
    {-node_id:required}
} {
    map object object_id to site_node node_id in table site_node_object_mappings
} {
    db_exec_plsql set_node_mapping {}
}

ad_proc -public site_node_object_map::del {
    {-object_id:required}
} {
    unmap object object_id from site_node node_id in table site_node_object_mappings
} {
    db_exec_plsql unset_node_mapping {}
}

ad_proc -public site_node_object_map::get_node_id {
    {-object_id:required}
} {
    @return the node_id of the site_node of the passed object_id
} {
    return [db_string select_node_mapping {} -default ""]
}

ad_proc -public site_node_object_map::get_url {
    {-object_id:required}
} {
    @return the url corresponding to the site_node to which the passed object_id is mapped.
} {
    set node_id [site_node_object_map::get_node_id -object_id $object_id]

    if {$node_id eq ""} {
        return {}
    }

    return [site_node::get_url -node_id $node_id]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
