ad_library {n
  Tcl procs for interface with the site-node data model.

  @author rhs@mit.edu
  @creation-date 2000-09-06
  @cvs-id $Id$
}


ad_proc -public site_node_create {
    {-new_node_id ""}
    {-directory_p "t"}
    {-pattern_p "t"}
    parent_node_id
    name
} {
    Create a new site node.
    Returns the node_id
} {
    # Generate an ID if we need one
    if {[empty_string_p $new_node_id]} {
	set new_node_id [db_nextval acs_object_id_seq]
    }

    set user_id [ad_verify_and_get_user_id]
    set ip_address [ad_conn peeraddr]

    set node_id [db_exec_plsql node_new {}]

    return $node_id
}

ad_proc -public site_nodes_sync {args} {
  Brings the in memory copy of the url hierarchy in sync with the
  database version.
} {
    if { [util_memoize_cached_p {site_nodes_sync_helper}] } {
	util_memoize_flush {site_nodes_sync_helper}
    }
    nsv_array reset site_nodes [util_memoize {site_nodes_sync_helper}]
    ns_eval {
	global tcl_site_nodes
	if {[info exists tcl_site_nodes]} {
	    unset tcl_site_nodes
	}
    }

}

ad_proc -private site_nodes_sync_helper {args} {
  Brings the in memory copy of the url hierarchy in sync with the
  database version.
} {
  db_foreach nodes_select {
    select site_node.url(n.node_id) as url, n.node_id, n.directory_p,
           n.pattern_p, n.object_id, o.object_type, n.package_key, n.package_id
    from acs_objects o, (select n.node_id, n.directory_p, n.pattern_p, n.object_id, p.package_key, p.package_id
                           from site_nodes n, apm_packages p
                          where n.object_id = p.package_id) n
    where n.object_id = o.object_id (+)
  } {

    set val(url) $url
    set val(node_id) $node_id
    set val(directory_p) $directory_p
    set val(pattern_p) $pattern_p
    set val(object_id) $object_id
    set val(object_type) $object_type
    set val(package_key) $package_key
    set val(package_id) $package_id

    set nodes($url) [array get val]
  }
  return [array get nodes]
}


ad_proc -public site_node {url} {
  Returns an array in the form of a list. This array contains
  url, node_id, directory_p, pattern_p, and object_id for the
  given url. If no node is found then this will throw an error.
} {

  # Try the URL as is.
  if {[catch {nsv_get site_nodes $url} result] == 0} {
    return $result
  }

  # Add a trailing slash and try again.
  if {[string index $url end] != "/"} {
    append url "/"
    if {[catch {nsv_get site_nodes $url} result] == 0} {
      return $result
    }
  }

  # Try successively shorter prefixes.
  while {$url != ""} {
    # Chop off last component and try again.
    set url [string trimright $url /]
    set url [string range $url 0 [string last / $url]]
    
    if {[catch {nsv_get site_nodes $url} result] == 0} {
      array set node $result
      if {$node(pattern_p) == "t" && $node(object_id) != ""} {
	return $result
      }
    }
  }

  error "site node not found"
}


ad_proc -public site_node_id {url} {
  Returns the node_id of a site node. Throws an error if there is no
  matching node.
} {
  array set node [site_node $url]
  return $node(node_id)
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
    if { [empty_string_p $url] } {
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
	    array set node [site_node $result]
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
    if { [empty_string_p $subsite_pkg_id] } {
	# No package was found... return the default
	return $default
    }
    return [db_string select_url {
	select site_node.url(node_id) from site_nodes where object_id=:subsite_pkg_id
    } -default ""]
}

ad_proc -public site_node_create_package_instance {
    { -package_id 0 }
    { -sync_p "t" }
    node_id
    instance_name 
    context_id 
    package_key
} {
    Creates a new instance of the specified package and flushes the
    in-memory site map (if sync_p is t).

    DRB: I've modified this so it doesn't call the package's post instantiation proc until
    after the site node map is updated.   Delaying the call in this way allows the package to
    find itself in the map.   The code that mounts a subsite, in particular, needs to be able
    to do this so it can find the nearest parent node that defines an application group (the
    code in aD ACS 4.2 was flat-out broken). 

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-05

    @return The package_id of the newly mounted package 
} {

    # Create  the package.

    set package_id [apm_package_create_instance $instance_name $context_id $package_key]

    # Update the site map
    db_dml update_site_nodes {
	update site_nodes
	   set object_id = :package_id
	 where node_id = :node_id
    }

    # Flush the in-memory site node map
    if { [string eq $sync_p "t"] } {
	site_nodes_sync
    }

    apm_package_call_post_instantiation_proc $package_id $package_key

    return $package_id

}

ad_proc -public site_node_mount_application { 
    { -sync_p "t" }
    { -return "package_id" }
    parent_node_id
    instance_name
    package_key
    package_name
} {
    Creates a new instance of the specified package and mounts it
    beneath parent_node_id.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-05

    @param sync_p If "t", we flush the in-memory site map
    @param return You can specify what is returned: the package_id or node_id
    @param parent_node_id The node under which we are mounting this
           application
    @param instance_name The instance name for the new site node
    @param package_key The type of package we are mounting
    @param package_name The name we want to give the package we are
           mounting.
    @return The package id of the newly mounted package or the new
           node id, based on the value of $return

} {

    # First create the new node beneath parent_node_id
    set node_id [db_exec_plsql create_node {
	begin
	  :1 := site_node.new (
                    parent_id => :parent_node_id,
                    name => :instance_name,
                    directory_p => 't',
                    pattern_p => 't'
	  );
	end;
    }]

    # If there is an object mounted at the parent_node_id
    # then use that object_id, instead of the parent_node_id,
    # as the context_id
    if { ![db_0or1row get_context {
        select object_id as context_id
          from site_nodes 
         where node_id = :parent_node_id
    }] } {
	set context_id $parent_node_id
    }    

    set package_id [site_node_create_package_instance -sync_p $sync_p $node_id $package_name $context_id $package_key]

    if { [string eq $return "package_id"] } {
	return $package_id
    } elseif { [string eq $return "node_id"] } {
	return $node_id
    } elseif { [string eq $return "package_id,node_id"] } {
	return [list $package_id $node_id]
    }

    error "Unknown return key: $return. Must be either package_id, node_id"
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
    db_dml unmount {
	update site_nodes
	   set object_id = null
	 where node_id = :node_id
    }

    if { [string eq $delete_p "t"] } {
	# Delete the node from the site map
	db_exec_plsql node_delete {
	    begin site_node.delete(:node_id); end;
	}	
    }

    if { [string eq $sync_p "t"] } {
	site_nodes_sync
    }
}

