ad_library {

    site node api

    @author rhs@mit.edu
    @author yon (yon@openforce.net)
    @creation-date 2000-09-06
    @cvs-id $Id$

}

namespace eval site_node {

    ad_proc -public new {
        {-name:required}
        {-parent_id:required}
        {-directory_p t}
        {-pattern_p t}
    } {
        create a new site node
    } {
        set extra_vars [ns_set create]
        ns_set put $extra_vars name $name
        ns_set put $extra_vars parent_id $parent_id
        ns_set put $extra_vars directory_p $directory_p
        ns_set put $extra_vars pattern_p $pattern_p

        set node_id [package_instantiate_object -extra_vars $extra_vars site_node]

        update_cache -node_id $node_id

        return $node_id
    }

    ad_proc -public delete {
        {-node_id:required}
    } {
        delete the site node
    } {
        db_exec_plsql delete_site_node {}
        update_cache -node_id $node_id
    }

    ad_proc -public mount {
        {-node_id:required}
        {-object_id:required}
    } {
        mount object at site node
    } {
        db_dml mount_object {}
        update_cache -node_id $node_id

        apm_invoke_callback_proc -package_key [apm_package_key_from_id $object_id] -type "after-mount" -arg_list [list node_id $node_id package_id $object_id]
    }

    ad_proc -public instantiate_and_mount {
        {-node_id ""}
        {-parent_node_id ""}
        {-node_name ""}
        {-package_name ""}
        {-context_id ""}
        {-package_key:required}
    } {
        Instantiate and mount a package of given type.

        @param node_id        The id of the node in the site map where the package should be mounted.
                              If not specified a new node under the main site will be created.
        @param parent_node_id If no node_id is specified this will be the parent node under which the
                              new node is created. Defaults to the main site node id.
        @param node_name      If node_id is not specified then this will be the name of the
                              new site node that is created. Defaults to package_key.
        @param package_name The name of the new package instance. Defaults to pretty name of package type.
        @param context_id     The context_id of the package. Defaults to the package_id at the parent
                              node in the site map. If there is no such package then context_id will be the
                              id of the parent node itself.
        @param package_key    The key of the package type to instantiate.

        @return The id of the instantiated package
                          
        @author Peter Marklund
    } {
        # Create a new node if none was provided
        if { [empty_string_p $node_id] } {
            if { [empty_string_p $parent_node_id ] } {
                set parent_node_id [site_node::get_node_id -url "/"]
            }

            # Default node_name to package_key
            set node_name [ad_decode $node_name "" $package_key $node_name]

            set node_id [site_node::new -name $node_name -parent_id $parent_node_id]
        }

        # Get the context_id of the new package
        if {[empty_string_p $context_id]} {
            # Attempt to use the package_id at the parent node
            if { [empty_string_p $parent_node_id] } {
                set parent_node_id [site_node::get_parent_id -node_id $node_id]
            }
            array set node [site_node::get -node_id $parent_node_id]
            set context_id $node(object_id)

            if {[empty_string_p $context_id]} {
                # No package at parent node, so use the id of the node itself instead
                # Should we use default_context here instead?
                set context_id $parent_node_id
            }
        }

        # Instantiate the package
        set package_id [apm_package_instance_new $package_name $context_id $package_key]

        # Mount the package
        site_node::mount -node_id $node_id -object_id $package_id

        return $package_id
    }

    ad_proc -public unmount {
        {-node_id:required}
    } {
        unmount an object from the site node
    } {
        set package_id [get_object_id -node_id $node_id]
        apm_invoke_callback_proc -package_key [apm_package_key_from_id $package_id] -type before-unmount -arg_list [list package_id $package_id node_id $node_id]

        db_dml unmount_object {}
        update_cache -node_id $node_id
    }

    ad_proc -private init_cache {} {
        initialize the site node cache
    } {
        nsv_array reset site_nodes [list]
        nsv_array reset site_node_urls [list]

        db_foreach select_site_nodes {} -column_array node {
            nsv_set site_nodes $node(url) [array get node]
            nsv_set site_node_urls $node(node_id) $node(url)
        }

        ns_eval {
            global tcl_site_nodes
            if {[info exists tcl_site_nodes]} {
                unset tcl_site_nodes
            }
        }
    }

    ad_proc -private update_cache {
        {-node_id:required}
    } {
        if { [db_0or1row select_site_node {} -column_array node] } {
            nsv_set site_nodes $node(url) [array get node]
            nsv_set site_node_urls $node(node_id) $node(url)

            ns_eval {
                global tcl_site_nodes
                if { [info exists tcl_site_nodes] } {
                    array unset tcl_site_nodes "${node(url)}*"
                }
            }
        } else {
            set url [get_url -node_id $node_id]

            if {[nsv_exists site_nodes $url]} {
                nsv_unset site_nodes $url
            }

            if {[nsv_exists site_node_urls $node_id]} {
                nsv_unset site_node_urls $node_id
            }
        }
    }

    ad_proc -public get {
        {-url ""}
        {-node_id ""}
    } {
        returns an array representing the site node that matches the given url

        either url or node_id is required, if both are passed url is ignored

        The array elements are: package_id, package_key, object_type, directory_p, 
        instance_name, pattern_p, parent_id, node_id, object_id, url.
    } {
        if {[empty_string_p $url] && [empty_string_p $node_id]} {
            error "site_node::get \"must pass in either url or node_id\""
        }

        if {![empty_string_p $node_id]} {
            return [get_from_node_id -node_id $node_id]
        }

        if {![empty_string_p $url]} {
            return [get_from_url -url $url]
        }

    }

    ad_proc -public get_from_node_id {
        {-node_id:required}
    } {
        returns an array representing the site node for the given node_id
        
        @see site_node::get
    } {
        return [get_from_url -url [get_url -node_id $node_id]]
    }

    ad_proc -public get_from_url {
        {-url:required}
    	{-exact:boolean}
    } {
        Returns an array representing the site node that matches the given url.<p>

	A trailing '/' will be appended to $url if required and not present.<p>

	If the '-exact' switch is not present and $url is not found, returns the
	first match found by successively removing the trailing $url path component.<p>

        @see site_node::get
    } {
        # attempt an exact match
        if {[nsv_exists site_nodes $url]} {
            return [nsv_get site_nodes $url]
        }

        # attempt adding a / to the end of the url if it doesn't already have
        # one
        if {![string equal [string index $url end] "/"]} {
            append url "/"
            if {[nsv_exists site_nodes $url]} {
                return [nsv_get site_nodes $url]
            }
        }

        # chomp off part of the url and re-attempt
	if {!$exact_p} {
	    while {![empty_string_p $url]} {
		set url [string trimright $url /]
		set url [string range $url 0 [string last / $url]]

		if {[nsv_exists site_nodes $url]} {
		    array set node [nsv_get site_nodes $url]

		    if {[string equal $node(pattern_p) t] && ![empty_string_p $node(object_id)]} {
			return [array get node]
		    }
		}
	    }
	}

        error "site node not found at url $url"
    }

    ad_proc -public get_from_object_id {
        {-object_id:required}
    } {
        return the site node associated with the given object_id

        WARNING: Returns only the first site node associated with this object.
    } {
        return [get -url [lindex [get_url_from_object_id -object_id $object_id] 0]]
    }

    ad_proc -public get_all_from_object_id {
        {-object_id:required}
    } {
        return a list of site nodes associated with the given object_id
    } {
        set node_id_list [list]

        foreach url [get_url_from_object_id -object_id $object_id] {
            lappend node_id_list [get -url $url]
        }

        return $node_id_list
    }

    ad_proc -public get_url {
        {-node_id:required}
    } {
        return the url of this node_id
    } {
        set url ""
        if {[nsv_exists site_node_urls $node_id]} {
            set url [nsv_get site_node_urls $node_id]
        }

        return $url
    }

    ad_proc -public get_url_from_object_id {
        {-object_id:required}
    } {
        returns a list of urls for site_nodes that have the given object
        mounted or the empty list if there are none
    } {
        return [db_list select_url_from_object_id {}]
    }

    ad_proc -public get_node_id {
        {-url:required}
    } {
        return the node_id for this url
    } {
        array set node [get -url $url]
        return $node(node_id)
    }

    ad_proc -public get_node_id_from_object_id {
        {-object_id:required}
    } {
        return the site node id associated with the given object_id
    } {
        return [get_node_id -url [lindex [get_url_from_object_id -object_id $object_id] 0]]
    }

    ad_proc -public get_parent_id {
        {-node_id:required}
    } {
        return the parent_id of this node
    } {
        array set node [get -node_id $node_id]
        return $node(parent_id)
    }

    ad_proc -public get_parent {
        {-node_id:required}
    } {
        return the parent node of this node
    } {
        array set node [get -node_id $node_id]
        return [get -node_id $node(parent_id)]
    }

    ad_proc -public get_object_id {
        {-node_id:required}
    } {
        return the object_id for this node
    } {
        array set node [get -node_id $node_id]
        return $node(object_id)
    }

    
}

##############
#
# Deprecated Procedures
#
#############

ad_proc -deprecated -warn site_node_create {
    {-new_node_id ""}
    {-directory_p "t"}
    {-pattern_p "t"}
    parent_node_id
    name
} {
    Create a new site node.  Returns the node_id

    @see site_node::new
} {
    return [site_node::new \
        -name $name \
        -parent_id $parent_node_id \
        -directory_p $directory_p \
        -pattern_p $pattern_p \
    ]
}

ad_proc -deprecated -warn site_node_create_package_instance {
    { -package_id 0 }
    { -sync_p "t" }
    node_id
    instance_name
    context_id
    package_key
} {
    Creates a new instance of the specified package and flushes the
    in-memory site map (if sync_p is t). This proc is deprecated, please use
    site_node::instantiate_and_mount instead.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @see site_node::instantiate_and_mount
    @creation-date 2001-02-05

    @return The package_id of the newly mounted package
} {
    return [site_node::instantiate_and_mount -node_id $node_id \
                                             -package_name $instance_name \
                                             -context_id $context_id \
                                             -package_key $package_key]
}

ad_proc -public site_node_delete_package_instance {
    {-node_id:required}
} {
    Wrapper for apm_package_instance_delete

    @author Arjun Sanyal (arjun@openforc.net)
    @creation-date 2002-05-02
} {
    db_transaction {
        set package_id [site_node::get_object_id -node_id $node_id]
        site_node::unmount -node_id $node_id
        apm_package_instance_delete $package_id
    }
}

ad_proc -public -deprecated -warn site_node_mount_application {
    {-sync_p "t"}
    {-return "package_id"}
    parent_node_id
    url_path_component
    package_key
    instance_name
} {
    Creates a new instance of the specified package and mounts it
    beneath parent_node_id. Deprecated - please use the proc
    site_node::instantiate_and_mount instead.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-05

    @param sync_p If "t", we flush the in-memory site map
    @param return (now ignored, always return package_id)
    @param parent_node_id The node under which we are mounting this
           application
    @param url_path_component the url for the mounted instance (appended to the parent_node 
           url)
    @param package_key The type of package we are mounting
    @param instance_name The name we want to give the package we are
           mounting (used for the context bar string etc).

    @see site_node::instantiate_and_mount

    @return The package id of the newly mounted package
} {
    return [site_node::instantiate_and_mount -parent_node_id $parent_node_id \
                                             -node_name $url_path_component
                                             -package_name $instance_name \
                                             -package_key $package_key]
}

ad_proc -public site_map_unmount_application {
    { -sync_p "t" }
    { -delete_p "f" }
    node_id
} {
    Unmounts the specified node.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-07

    @param sync_p If "t", we flush the in-memory site map
    @param delete_p If "t", we attempt to delete the site node. This
         will fail if you have not cleaned up child nodes
    @param node_id The node_id to unmount

} {
    db_transaction {
        site_node::unmount -node_id $node_id

        if {[string equal $delete_p t]} {
            site_node::delete -node_id $node_id
        }
    }
}

ad_proc -deprecated -warn site_node {url} {
    Returns an array in the form of a list. This array contains
    url, node_id, directory_p, pattern_p, and object_id for the
    given url. If no node is found then this will throw an error.
    
    @see site_node::get 
} {
    return [site_node::get -url $url]
}

ad_proc -public site_node_id {url} {
    Returns the node_id of a site node. Throws an error if there is no
    matching node.
} {
    return [site_node::get_node_id -url $url]
}

ad_proc -public site_nodes_sync {args} {
    Brings the in memory copy of the url hierarchy in sync with the
    database version.
} {
    site_node::init_cache
}

ad_proc -public site_node_closest_ancestor_package {
    { -default "" }
    { -url "" }
    package_key
} {
    Finds the package id of a package of specified type that is
    closest to the node id represented by url (or by ad_conn url).Note
    that closest means the nearest ancestor node of the specified
    type, or the current node if it is of the correct type.

    <p>

    Usage:

    <pre>
    # Pull out the package_id of the subsite closest to our current node
    set pkg_id [site_node_closest_ancestor_package "acs-subsite"]
    </pre>

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 1/17/2001

    @param default The value to return if no package can be found
    @param current_node_id The node from which to start the search
    @param package_key The type of the package for which we are looking

    @return <code>package_id</code> of the nearest package of the
    specified type (<code>package_key</code>). Returns $default if no
    such package can be found.

} {
    if {[empty_string_p $url]} {
	set url [ad_conn url]
    }

    # Try the URL as is.
    if {[catch {nsv_get site_nodes $url} result] == 0} {
	array set node $result
	if { [string eq $node(package_key) $package_key] } {
	    return $node(package_id)
	}
    }

    # Add a trailing slash and try again.
    if {[string index $url end] != "/"} {
	append url "/"
	if {[catch {nsv_get site_nodes $url} result] == 0} {
	    array set node $result
	    if { [string eq $node(package_key) $package_key] } {
		return $node(package_id)
	    }
	}
    }

    # Try successively shorter prefixes.
    while {$url != ""} {
	# Chop off last component and try again.
	set url [string trimright $url /]
	set url [string range $url 0 [string last / $url]]
	
	if {[catch {nsv_get site_nodes $url} result] == 0} {
	    array set node $result
	    if {$node(pattern_p) == "t" && $node(object_id) != "" && [string eq $node(package_key) $package_key] } {
		return $node(package_id)
	    }
	}
    }

    return $default
}

ad_proc -public site_node_closest_ancestor_package_url {
    { -default "" }
    { -package_key "acs-subsite" }
} {
    Returns the url stub of the nearest application of the specified
    type.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-05

    @param package_key The type of package for which we're looking
    @param default The default value to return if no package of the
    specified type was found

} {
    set subsite_pkg_id [site_node_closest_ancestor_package $package_key]
    if {[empty_string_p $subsite_pkg_id]} {
	# No package was found... return the default
	return $default
    }

    return [lindex [site_node::get_url_from_object_id -object_id $subsite_pkg_id] 0]
}
