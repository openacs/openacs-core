# tcl/portal-node-mapping-procs.tcl

ad_library {
    Portal Node Mappings

    @author Ben Adida (ben@openforce.net)
    @creation-date April 2002
    @cvs-id $Id$
}

namespace eval site_node_object_map {

    ad_proc -public new {
        {-object_id:required}
        {-node_id:required}
    } {
        db_exec_plsql set_node_mapping {}
    }

    ad_proc -public del {
        {-object_id:required}
    } {
        db_exec_plsql unset_node_mapping {}
    }

    ad_proc -public get_node_id {
        {-object_id:required}
    } {
        return [db_string select_node_mapping {} -default ""]
    }

    ad_proc -public get_url {
        {-object_id:required}
    } {
        set node_id [get_node_id -object_id $object_id]

        if {[empty_string_p $node_id]} {
            return $node_id
        }

        return [site_node::get_url -node_id $node_id]
    }

}
