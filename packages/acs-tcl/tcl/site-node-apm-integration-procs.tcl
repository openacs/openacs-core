ad_library {

    site node / apm integration procs

    @author arjun (arjun@openforce.net)
    @author yon (yon@openforce.net)
    @creation-date 2002-07-10
    @cvs-id $Id$

}

namespace eval site_node_apm_integration {

    ad_proc -public -deprecated -warn new_site_node_and_package {
        {-name:required}
        {-parent_id:required}
        {-package_key:required}
        {-instance_name:required}
        {-context_id:required}
    } {
        Create site node, instantiate package, mount package at new site node. Deprecated - 
        please use site_node::instantiate_and_mount instead.

        @see site_node::instantiate_and_mount
    } {
        return [site_node::instantiate_and_mount -parent_node_id $parent_id \
                                                 -node_name $name \
                                                 -package_name $instance_name \
                                                 -context_id $context_id \
                                                 -package_key $package_key]
    }

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
        get the package_id of package_key that is mounted directly under
        package_id. returns empty string if not found.
    } {
        if {[empty_string_p $package_id]} {
            set package_id [ad_conn package_id]
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

        if {[empty_string_p $child_package_id]} {
            return 0
        } else {
            return 1 
        }
    }

}
