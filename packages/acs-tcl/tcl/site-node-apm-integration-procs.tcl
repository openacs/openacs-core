ad_library {

    site node / apm integration procs

    @author arjun (arjun@openforce.net)
    @author yon (yon@openforce.net)
    @creation-date 2002-07-10
    @cvs-id $Id$

}

namespace eval site_node_apm_integration {

    ad_proc -public delete_site_nodes_and_package {
        {-package_id:required}
    } {
        First deletes ALL the site nodes this instance is mapped to, then deletes the instance.

    } {
        db_transaction {
            # should here be a pre-destruction proc like the post instantiation proc?
            foreach site_node_info_list [site_node::get_all_from_object_id -object_id $package_id] {

                ns_log debug "delete_site_nodes_and_package: $site_node_info_list"
                
                array set site_node $site_node_info_list

                site_node::unmount -node_id $site_node(node_id)
                site_node::delete -node_id $site_node(node_id)
                site_node::update_cache -node_id $site_node(node_id)
            }

            apm_package_instance_delete $package_id
        }
    }

    ad_proc -public get_child_package_id {
        {-package_id ""}
        {-package_key:required}
    } {
        Get the package_id of package_key that is mounted directly under
        package_id.
        @return empty string if not found.
    } {
        if {$package_id eq ""} {
            if {[ad_conn isconnected]} { 
                set package_id [ad_conn package_id]
            } else { 
                error "Not in a connection and no package_id provided"
            } 
        }

        return [db_string select_child_package_id {} -default ""]
    }

    ad_proc -public child_package_exists_p {
        {-package_id ""}
        {-package_key:required}
    } {
        Returns 1 if there exists a child package with the given package_key, 
        or 0 if not.
    } {
        set child_package_id [get_child_package_id \
            -package_id $package_id \
            -package_key $package_key
        ]

        if {$child_package_id eq ""} {
            return 0
        } else {
            return 1 
        }
    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
