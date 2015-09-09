ad_library {

    site node api

    @author rhs@mit.edu
    @author yon (yon@openforce.net)
    @creation-date 2000-09-06
    @cvs-id $Id$

}


#####################################################################
#
# For the sitenodes implmementation there are two versions available.
# One has the option to use either the classical site-nodes code based
# on nsvs or the newer XOTcl based code. The classical code has the
# disadvantage that it takes a while on start-up, uses a lot of
# memory, and is non-scalable on size and parallelization. The new
# version is much faster from a factor of two to a several thousand
# times - but requires XOTcl, which has not made it yet to the
# acs-core procs. So, the implementation checks, if the installation
# fullfills the requirements of the new code, if not, it falls back to
# the classical implementation.
# 
# Some timings:
#  simple installation:
#    nsv-based get_children: 291 microseconds
#    xotcl-based get_children: 30 microseconds
#
#  implementation with 130.000 site-nodes
#    nsv-based get_children: 1535380 microseconds
#    xotcl-based get_children: 186 microseconds
#
#   array set n [nsv_get site_nodes /]
#   ds_comment [time {site_node::get_children -node_id $n(node_id)}]
#   ds_comment [time {::xo::site_node get_children  -node_id $n(node_id)}]
#
# The easiest and most straightforward implementation is to put the
# few XOTcl classes here into this file (what i did for now), since it
# makes it easier to handle reloads, etc.
#
# If the variable UseXotclSiteNodes is set, we define a few of the
# ad_procs below to use the XOTcl-based infrastructure.
#
# In case, you are using dotlrn, make sure to use an up-to-date
# version of dotlrn that does not bypass the API to access the nsv
# "site_nodes". Make sure to use as well the two fixes by Victor
# Guerra for applets-procs.tcl and dotlrn-procs.tcl from May 12 2010.
#
# -gustaf neumann (May 2010)
#
#####################################################################
#

#
# Per default, use the classical code
#
set UseXotclSiteNodes 0

#
# Turn on UseXotclSiteNodes in cases, where all requirements are met.
# The XOTcl classes below depend on XOTcl 2, xotcl-core (in particular
# 05-db-procs.tcl). The current implementation does not support
# oracle, the implementation does not distinguish btw. AOLserver and
# NaviServer (uses simply ns_cache_eval for speed and simplicity).
# We can't use e.g.     && [ds_string check_package {select 1 from apm_package_versions where package_key = 'xotcl-core' and installed_p = 't'}]

#

if {[info command ::nx::Object] ne ""
    && [db_driverkey ""] eq "postgresql"
    && [apm_package_installed_p xotcl-core]
    && [ns_info name] eq "NaviServer"
} {
    set UseXotclSiteNodes 1
    ns_log notice "use XOTcl Site Nodes"
}

#----------------------------------------------------------------------
# site_nodes data structure
#----------------------------------------------------------------------
#
# nsv site_nodes($url)                           = array-list with all info about a node
# nsv site_node_url_by_node_id($node_id)         = url for that node_id
# nsv site_node_url_by_object_id($object_id)     = list of URLs where that object_id is mounted,
#                                                  ordered longest path first
# nsv site_node_url_by_package_key($package_key) = list of URLs where that package_key is mounted,
#                                                  no ordering
# nsv site_nodes_mutex                           = mutex object used to control concurrency


namespace eval site_node {}

ad_proc -public site_node::new {
    {-name:required}
    {-parent_id:required}
    {-directory_p t}
    {-pattern_p t}
} {
    create a new site node
} {
    set var_list [list \
                      [list name $name] \
                      [list parent_id $parent_id] \
                      [list directory_p $directory_p] \
                      [list pattern_p $pattern_p]]

    set node_id [package_instantiate_object -var_list $var_list site_node]

    #Now update the nsv caches.  We don't need to update the object_id and package_key caches
    #because nothing is mounted here yet.

    # Grab the lock so our URL key doesn't change on us midstream
    ns_mutex lock [nsv_get site_nodes_mutex mutex]

    with_finally -code {
        set url [site_node::get_url -node_id $parent_id]
        append url $name
        if { $directory_p == "t" } { append url "/" }
        nsv_set site_node_url_by_node_id $node_id $url
        nsv_set site_nodes $url \
            [list url $url node_id $node_id parent_id $parent_id name $name \
                 directory_p $directory_p pattern_p $pattern_p \
                 object_id "" object_type "" \
                 package_key "" package_id "" \
                 instance_name "" package_type ""]
    } -finally {
        ns_mutex unlock [nsv_get site_nodes_mutex mutex]
    }

    return $node_id
}

ad_proc -public site_node::delete {
    {-node_id:required}
} {
    delete the site node
} {
    db_exec_plsql delete_site_node {}
    update_cache -node_id $node_id
}

ad_proc -public site_node::mount {
    {-node_id:required}
    {-object_id:required}
    {-context_id}
} {
    mount object at site node
} {
    db_dml mount_object {}
    db_dml update_object_package_id {}

    ns_mutex lock [nsv_get site_nodes_mutex mutex]

    with_finally -code {
        #Now update the nsv caches.
        array set node [site_node::get_from_node_id -node_id $node_id]
        
        foreach var [list object_type package_key package_id instance_name package_type] {
            set $var ""
        }
        
        db_0or1row get_package_info {
            select 'apm_package' as object_type,
            p.package_key,
            p.package_id,
            p.instance_name,
            t.package_type
            from apm_packages p, apm_package_types t
            where p.package_id = :object_id
            and t.package_key = p.package_key
        }
        
        nsv_set site_nodes $node(url) \
            [list url $node(url) node_id $node(node_id) parent_id $node(parent_id) name $node(name) \
                 directory_p $node(directory_p) pattern_p $node(pattern_p) \
                 object_id $object_id object_type $object_type \
                 package_key $package_key package_id $package_id \
                 instance_name $instance_name package_type $package_type]
        
        set url_by_object_id [list $node(url)]
        if { [nsv_exists site_node_url_by_object_id $object_id] } {
            set url_by_object_id [concat [nsv_get site_node_url_by_object_id $object_id] $url_by_object_id]
            set url_by_object_id [lsort \
                                      -decreasing \
                                      -command util::string_length_compare \
                                      $url_by_object_id]
        }
        nsv_set site_node_url_by_object_id $object_id $url_by_object_id
        
        if { $package_key ne "" } {
            set url_by_package_key [list $node(url)]
            if { [nsv_exists site_node_url_by_package_key $package_key] } {
                set url_by_package_key [concat [nsv_get site_node_url_by_package_key $package_key] $url_by_package_key]
            }
            nsv_set site_node_url_by_package_key $package_key $url_by_package_key
        }
    } -finally {
        ns_mutex unlock [nsv_get site_nodes_mutex mutex]
    }

    # DAVEB update context_id if it is passed in
    # some code relies on context_id to be set by
    # instantiate_and_mount so we can't assume
    # anything at this point. Callers that need to set context_id
    # for example, when an unmounted package is mounted,
    # should pass in the correct context_id
    if {[info exists context_id]} {
        db_dml update_package_context_id ""
    }

    set package_key [apm_package_key_from_id $object_id]
    foreach inherited_package_key [nsv_get apm_package_inherit_order $package_key] {
        apm_invoke_callback_proc \
            -package_key $inherited_package_key \
            -type after-mount \
            -arg_list [list package_id $package_id node_id $node_id]
    }

}

ad_proc -public site_node::rename {
    {-node_id:required}
    {-name:required}
} {
    Rename the site node.
} {
    # We need to update the cache for all the child nodes as well
    set node_url [get_url -node_id $node_id]
    set child_node_ids [get_children -all -node_id $node_id -element node_id]

    db_dml rename_node {}
    db_dml update_object_title {}

    update_cache -sync_children -node_id $node_id
}

ad_proc -public site_node::instantiate_and_mount {
    {-node_id ""}
    {-parent_node_id ""}
    {-node_name ""}
    {-package_name ""}
    {-context_id ""}
    {-package_key:required}
    {-package_id ""}
} {
    Instantiate and mount a package of given type. Will use an existing site node if possible.

    @param node_id        The id of the node in the site map where the package should be mounted.
    @param parent_node_id If no node_id is specified this will be the parent node under which the
    new node is created. Defaults to the main site node id.
    @param node_name      If node_id is not specified then this will be the name of the
    new site node that is created. Defaults to package_key.
    @param package_name   The name of the new package instance. Defaults to pretty name of package type.
    @param context_id     The context_id of the package. Defaults to the closest ancestor package
    in the site map.
    @param package_key    The key of the package type to instantiate.
    @param package_id     The id of the new package. Optional.

    @return The id of the instantiated package
    
    @author Peter Marklund
} {
    # Create a new node if none was provided and none exists
    if { $node_id eq "" } {
        # Default parent node to the main site
        if { $parent_node_id eq "" } {
            set parent_node_id [site_node::get_node_id -url "/"]
        }

        # Default node_name to package_key
        if { $node_name eq "" } {
            set node_name $package_key
        }

        # Create the node if it doesn't exists
        set parent_url [get_url -notrailing -node_id $parent_node_id]
        set url "${parent_url}/${node_name}"            

        if { ![exists_p -url $url] } {
            set node_id [site_node::new -name $node_name -parent_id $parent_node_id]
        } else {
            # Check that there isn't already a package mounted at the node
            array set node [get -url $url]

            if { [info exists node(object_id)] && $node(object_id) ne "" } {
                error "Cannot mount package at url $url as package $node(object_id) is already mounted there"
            }

            set node_id $node(node_id)
        }
    }

    # Default context id to the closest ancestor package_id
    if { $context_id eq "" } {
        set context_id [site_node::closest_ancestor_package -node_id $node_id]
    }

    # Instantiate the package
    set package_id [apm_package_instance_new \
                        -package_id $package_id \
                        -package_key $package_key \
                        -instance_name $package_name \
                        -context_id $context_id]

    # Mount the package
    site_node::mount -node_id $node_id -object_id $package_id

    return $package_id
}

ad_proc -public site_node::unmount {
    {-node_id:required}
} {
    unmount an object from the site node
} {
    set package_id [get_object_id -node_id $node_id]
    set package_key [apm_package_key_from_id $package_id]

    if {[nsv_exists apm_package_inherit_order $package_key]} {
        foreach inherited_package_key [nsv_get apm_package_inherit_order $package_key] {
            apm_invoke_callback_proc \
                -package_key $inherited_package_key \
                -type before-unmount \
                -arg_list [list package_id $package_id node_id $node_id]
        }
    }

    db_dml unmount_object {}
    db_dml update_object_package_id {}
    update_cache -node_id $node_id
}

ad_proc -private site_node::init_cache {} {
    initialize the site node cache
} {
    nsv_array reset site_nodes [list]
    nsv_array reset site_node_url_by_node_id [list]
    nsv_array reset site_node_url_by_object_id [list]
    nsv_array reset site_node_url_by_package_key [list]

    set root_node_id [db_string get_root_node_id {} -default {}]
    if { $root_node_id ne "" } {
        site_node::update_cache -sync_children -node_id $root_node_id
    }
}

ad_proc -private site_node::update_cache {
    {-sync_children:boolean}
    {-node_id:required}
} {
    Brings the in memory copy of the site nodes hierarchy in sync with the
    database version. Only updates the given node and its children.
} {
    # don't let any other thread try to do a concurrent update
    # until cache is fully updated
    ns_mutex lock [nsv_get site_nodes_mutex mutex]

    with_finally -code {
        
        # Lars: We need to record the object_id's touched, so we can sort the 
        # object_id->url mappings again. We store them sorted by length of the URL 
        if { [nsv_exists site_node_url_by_node_id $node_id] } {
            set old_url [nsv_get site_node_url_by_node_id $node_id]
            if { $sync_children_p } {
                append old_url *
            }
            
            # This is a little cumbersome, but we have to remove the entry for
            # the object_id->url mapping, for each object_id that used to be 
            # mounted here
            
            # Loop over all the URLs under the node we're updating
            set cur_nodes [nsv_array get site_nodes $old_url]
            foreach {cur_node_url curr_node_values} $cur_nodes {
                array set cur_node $curr_node_values
                # Find the object_id previously mounted there
                set cur_object_id $cur_node(object_id)
                if { $cur_object_id ne "" } {
                    # Remove the URL from the url_by_object_id entry for that object_id
                    set cur_url_by_object_id [nsv_get site_node_url_by_object_id $cur_object_id]
                    set cur_idx [lsearch -exact $cur_url_by_object_id $cur_node_url]
                    if { $cur_idx != -1 } {
                        set cur_url_by_object_id \
                            [lreplace $cur_url_by_object_id $cur_idx $cur_idx]
                        nsv_set site_node_url_by_object_id $cur_object_id $cur_url_by_object_id
                    }
                }
                
                # Find the package_key previously mounted there
                set cur_package_key $cur_node(package_key)
                if { $cur_package_key ne "" } {
                    # Remove the URL from the url_by_package_key entry for that package_key
                    set cur_url_by_package_key [nsv_get site_node_url_by_package_key $cur_package_key]
                    set cur_idx [lsearch -exact $cur_url_by_package_key $cur_node_url]
                    if { $cur_idx != -1 } {
                        set cur_url_by_package_key \
                            [lreplace $cur_url_by_package_key $cur_idx $cur_idx]
                        nsv_set site_node_url_by_package_key $cur_package_key $cur_url_by_package_key
                    }
                }
                nsv_unset site_nodes $cur_node_url
                nsv_unset site_node_url_by_node_id $cur_node(node_id)
            }
        }

        # Note that in the queries below, we use connect by instead of site_node.url
        # to get the URLs. This is less expensive.

        if { $sync_children_p } {
            set query_name select_child_site_nodes
        } else {
            set query_name select_site_node
        }
        
        set cur_obj_ids [list]
        db_foreach $query_name {} {
            if {$parent_id eq ""} {
                # url of root node
                set url "/"
            } else {
                # append directory to url of parent node
                set url [nsv_get site_node_url_by_node_id $parent_id]
                append url $name
                if { $directory_p == "t" } { append url "/" }
            }
            # save new url
            nsv_set site_node_url_by_node_id $node_id $url
            if { $object_id ne "" } {
                nsv_lappend site_node_url_by_object_id $object_id $url
                lappend cur_obj_ids $object_id
            }
            if { $package_key ne "" } {
                nsv_lappend site_node_url_by_package_key $package_key $url
            }

            if { $package_id eq "" } {
                set object_type ""
            } else {
                set object_type "apm_package"
            }

            # save new node
            nsv_set site_nodes $url \
                [list url $url node_id $node_id parent_id $parent_id name $name \
                     directory_p $directory_p pattern_p $pattern_p \
                     object_id $object_id object_type $object_type \
                     package_key $package_key package_id $package_id \
                     instance_name $instance_name package_type $package_type]
        }
        # AG: This lsort used to live in the db_foreach loop above.  I moved it here
        # to avoid redundant re-sorting on systems where multiple URLs are mapped to
        # the same object_id.  This was causing a 40 minute startup delay on a .LRN site
        # with 4000+ URLs mapped to one instance of the attachments package.
        # The sort facilitates deleting child nodes before parent nodes.
        foreach object_id [lsort -unique $cur_obj_ids] {
            nsv_set site_node_url_by_object_id $object_id [lsort \
                                                               -decreasing \
                                                               -command util::string_length_compare \
                                                               [nsv_get site_node_url_by_object_id $object_id] ]
        }
    } -finally {
        ns_mutex unlock [nsv_get site_nodes_mutex mutex]
    }
}

ad_proc -public site_node::get {
    {-url ""}
    {-node_id ""}
} {
    returns an array representing the site node that matches the given url

    either url or node_id is required, if both are passed url is ignored

    The array elements are: package_id, package_key, object_type, directory_p, 
    instance_name, pattern_p, parent_id, node_id, object_id, url.
} {
    if {$url eq "" && $node_id eq ""} {
        error "site_node::get \"must pass in either url or node_id\""
    }

    if {$node_id ne ""} {
        return [get_from_node_id -node_id $node_id]
    }

    if {$url ne ""} {
        return [get_from_url -url $url]
    }

}

ad_proc -public site_node::get_element {
    {-node_id ""}
    {-url ""}
    {-element:required}
} {
    returns an element from the array representing the site node that matches the given url

    either url or node_id is required, if both are passed url is ignored

    The array elements are: package_id, package_key, object_type, directory_p, 
    instance_name, pattern_p, parent_id, node_id, object_id, url.

    @see site_node::get
} {
    array set node [site_node::get -node_id $node_id -url $url]
    return $node($element)
}

ad_proc -public site_node::get_from_node_id {
    {-node_id:required}
} {
    returns an array representing the site node for the given node_id
    
    @see site_node::get
} {
    return [get_from_url -url [get_url -node_id $node_id]]
}

ad_proc -public site_node::get_from_url {
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
    if {[string index $url end] ne "/" } {
        append url "/"
        if {[nsv_exists site_nodes $url]} {
            return [nsv_get site_nodes $url]
        }
    }

    # chomp off part of the url and re-attempt
    if {!$exact_p} {
        while {$url ne ""} {
            set url [string trimright $url /]
            set url [string range $url 0 [string last / $url]]

            if {[nsv_exists site_nodes $url]} {
                array set node [nsv_get site_nodes $url]

                if {$node(pattern_p) == "t" && $node(object_id) ne ""} {
                    return [array get node]
                }
            }
        }
    }

    error "site node not found at url \"$url\""
}

ad_proc -public site_node::exists_p {
    {-url:required}
} {
    Returns 1 if a site node exists at the given url and 0 otherwise.

    @author Peter Marklund
} {
    set url_no_trailing [string trimright $url "/"]
    return [nsv_exists site_nodes "$url_no_trailing/"]
}        

ad_proc -public site_node::get_from_object_id {
    {-object_id:required}
} {
    return the site node associated with the given object_id

    WARNING: Returns only the first site node associated with this object.
} {
    return [get -url [lindex [get_url_from_object_id -object_id $object_id] 0]]
}

ad_proc -public site_node::get_all_from_object_id {
    {-object_id:required}
} {
    Return a list of site node info associated with the given object_id. 
    The nodes will be ordered descendingly by url (children before their parents).
} {
    set node_id_list [list]

    set url_list [list]
    foreach url [get_url_from_object_id -object_id $object_id] {
        lappend node_id_list [get -url $url]
    }

    return $node_id_list
}

ad_proc -public site_node::get_url {
    {-node_id:required}
    {-notrailing:boolean}
} {
    return the url of this node_id

    @param notrailing If true then strip any
    trailing slash ('/'). This means the empty string is returned for the root.
} {
    set url ""
    if {[nsv_exists site_node_url_by_node_id $node_id]} {
        set url [nsv_get site_node_url_by_node_id $node_id]
    }
    
    if { $notrailing_p } {
        set url [string trimright $url "/"]
    }

    return $url
}

ad_proc -public site_node::get_url_from_object_id {
    {-object_id:required}
} {
    returns a list of urls for site_nodes that have the given object
    mounted or the empty list if there are none. The
    url:s will be returned in descending order meaning any children will
    come before their parents. This ordering is useful when deleting site nodes
    as we must delete child site nodes before their parents.
} {
    if { [nsv_exists site_node_url_by_object_id $object_id] } {
        return [nsv_get site_node_url_by_object_id $object_id]
    } else {
        return [list]
    }
}

ad_proc -public site_node::get_node_id {
    {-url:required}
} {
    return the node_id for this url
} {
    array set node [get -url $url]
    return $node(node_id)
}

ad_proc -public site_node::get_node_id_from_object_id {
    {-object_id:required}
} {
    return the site node id associated with the given object_id
} {
    set url  [lindex [get_url_from_object_id -object_id $object_id] 0]
    if { $url ne "" } {
        return [get_node_id -url $url]
    } else {
        return {}
    }
}

ad_proc -public site_node::get_parent_id {
    {-node_id:required}
} {
    return the parent_id of this node
} {
    array set node [get -node_id $node_id]
    return $node(parent_id)
}

ad_proc -public site_node::get_parent {
    {-node_id:required}
} {
    return the parent node of this node
} {
    array set node [get -node_id $node_id]
    return [get -node_id $node(parent_id)]
}

ad_proc -public site_node::get_ancestors {
    {-node_id:required}
    {-element ""}
} {
    return the ancestors of this node
} {
    set result [list]
    set array_result_p [string equal $element ""]

    while {$node_id ne "" } {
        array set node [get -node_id $node_id]
        
        if {$array_result_p} {
            lappend result [array get node]
        } else {
            lappend result $node($element)
        }

        set node_id $node(parent_id)
    }
    
    return $result
}

ad_proc -public site_node::get_object_id {
    {-node_id:required}
} {
    return the object_id for this node
} {
    array set node [get -node_id $node_id]
    return $node(object_id)
}

ad_proc -public site_node::get_children {
    {-all:boolean}
    {-package_type {}}
    {-package_key {}}
    {-filters {}}
    {-element {}}
    {-node_id:required}
} {
    This proc gives answers to questions such as: What are all the package_id's 
    (or any of the other available elements) for all the instances of package_key or package_type mounted
    under node_id xxx?

    @param node_id       The node for which you want to find the children.

    @option all          Set this if you want all children, not just direct children
    
    @option package_type If specified, this will limit the returned nodes to those with an
    package of the specified package type (normally apm_service or 
                                           apm_application) mounted. Conflicts with the -package_key option.
    
    @param package_key   If specified, this will limit the returned nodes to those with a
    package of the specified package key mounted. Conflicts with the
    -package_type option. Can take one or more packges keys as a Tcl list.

    @param filters       Takes a list of { element value element value ... } for filtering 
    the result list. Only nodes where element is value for each of the 
    filters in the list will get included. For example: 
    -filters { package_key "acs-subsite" }.
    
    @param element       The element of the site node you wish returned. Defaults to url, but 
    the following elements are available: object_type, url, object_id,
    instance_name, package_type, package_id, name, node_id, directory_p.
    
    @return A list of URLs of the site_nodes immediately under this site node, or all children, 
    if the -all switch is specified.
    
    @author Lars Pind (lars@collaboraid.biz)
} {
    if { $package_type ne "" && $package_key ne "" } {
        error "You may specify either package_type, package_key, or filter_element, but not more than one."
    }

    if { $package_type ne "" } {
        lappend filters package_type $package_type
    } elseif { $package_key ne "" } {
        lappend filters package_key $package_key
    }

    set node_url [site_node::get_url -node_id $node_id]

    if { !$all_p } { 
        set child_urls [list]
        set s [string length "$node_url"]
        # find all child_urls who have only one path element below node_id
        # by clipping the node url and last character and seeing if there 
        # is a / in the string.  about 2x faster than the RE version.
        foreach child_url [nsv_array names site_nodes "${node_url}?*"] {
            if { [string first / [string range $child_url $s end-1]] < 0 } {
                lappend child_urls $child_url
            }
        }
    } else {
        set child_urls [nsv_array names site_nodes "${node_url}?*"]
    }


    if { [llength $filters] > 0 } {
        set return_val [list]
        foreach child_url $child_urls {
            array unset site_node
            if {![catch {array set site_node [nsv_get site_nodes $child_url]}]} {

                set passed_p 1
                foreach { elm val } $filters {
                    # package_key supports one or more package keys
                    # since we can filter on the site node pretty name
                    # we can't just treat all filter values as a list
                    if {$elm eq "package_key" && [llength $val] > 1 && [lsearch $val $site_node($elm)] < 0} {
                        set passed_p 0
                        break
                    } elseif {($elm ne "package_key" || [llength $val] == 1) && $site_node($elm) ne $val } {
                        set passed_p 0
                        break
                    }
                }
                if { $passed_p } {
                    if { $element ne "" } {
                        lappend return_val $site_node($element)
                    } else {
                        lappend return_val $child_url
                    }
                }
            }
        }
    } elseif { $element ne "" } {
        set return_val [list]
        foreach child_url $child_urls {
            array unset site_node
            if {![catch {array set site_node [nsv_get site_nodes $child_url]}]} {
                lappend return_val $site_node($element)
            }
        }
    }

    # if we had filters or were getting a particular element then we 
    # have our results in return_val otherwise it's just urls
    if { $element ne ""
         || [llength $filters] > 0} {
        return $return_val
    } else {
        return $child_urls
    }
}

ad_proc -public site_node::closest_ancestor_package {
    {-url ""}
    {-node_id ""}
    {-package_key ""}
    {-include_self:boolean}
    {-element "object_id"}
} {
    Starting with the node at with given id, or at given url,
    climb up the site map and return the id of the first not-null
    mounted object. If no ancestor object is found the empty string is 
    returned.

    Will ignore itself and only return true ancestors unless 
    <code>include_self</code> is set.

    @param url          The url of the node to start from. You must provide 
    either url or node_id. An empty url is taken to mean 
    the main site.
    @param node_id      The id of the node to start from. Takes precedence 
    over any provided url.
    @param package_key  Restrict search to objects of this package type. You 
    may supply a list of package_keys.
    @param include_self Return the package_id at the passed-in node if it is 
    of the desired package_key. Ignored if package_key is 
    empty.

    @return The id of the first object found and an empty string if no object
    is found. Throws an error if no node with given url can be found.

    @author Peter Marklund
} {
    # Make sure we have a url to work with
    if { $url eq "" } {
        if { $node_id eq "" } {
            set url "/"
        } else {
            set url [site_node::get_url -node_id $node_id]
        }
    }

    # should we return the package at the passed-in node/url?
    if { $include_self_p && $package_key ne ""} {
        array set node_array [site_node::get -url $url]

        if {$node_array(package_key) in $package_key} {
            return $node_array($element)
        }
    }

    set elm_value {}
    while { $elm_value eq "" && $url ne "/"} {
        # move up a level
        set url [string trimright $url /]
        set url [string range $url 0 [string last / $url]]
        
        array set node_array [site_node::get -url $url]

        # are we looking for a specific package_key?
        if { $package_key eq "" || \
                 [lsearch -exact $package_key $node_array(package_key)] != -1 } {
            set elm_value $node_array($element)
        }       
    }

    return $elm_value

}    

ad_proc -public site_node::get_package_url {
    {-package_key:required}
} {
    Get the URL of any mounted instance of a package with the given package_key.

    If there is more than one mounted instance of a package, returns
    the first URL. To see all of the mounted URLs, use the 
    site_node::get_children proc.

    @return a URL, or empty string if no instance of the package is mounted.
    @see site_node::get_children
} {
    if { [nsv_exists site_node_url_by_package_key $package_key] } {
        return [lindex [nsv_get site_node_url_by_package_key $package_key] 0]
    } else {
        return {}
    }
}


ad_proc -public site_node::verify_folder_name {
    {-parent_node_id:required}
    {-current_node_id ""}
    {-instance_name ""}
    {-folder ""}
} {
    Verifies that the given folder name is valid for a folder under the given parent_node_id.
    If current_node_id is supplied, it's assumed that we're renaming an existing node, not creating a new one.
    If folder name is not supplied, we'll generate one from the instance name, which must then be supplied.
    Returns folder name to use, or empty string if the supplied folder name wasn't acceptable.
} {
    set existing_urls [site_node::get_children -node_id $parent_node_id -element name]
    
    array set parent_node [site_node::get -node_id $parent_node_id]
    if { $parent_node(package_key) ne "" } {
        # Find all the page or directory names under this package
        foreach path [glob -nocomplain -types d "[acs_package_root_dir $parent_node(package_key)]/www/*"] {
            lappend existing_urls [lindex [file split $path] end]
        }
        foreach path [glob -nocomplain -types f "[acs_package_root_dir $parent_node(package_key)]/www/*.adp"] {
            lappend existing_urls [file rootname [lindex [file split $path] end]]
        }
        foreach path [glob -nocomplain -types f "[acs_package_root_dir $parent_node(package_key)]/www/*.tcl"] {
            set name [file rootname [lindex [file split $path] end]]
            if { [lsearch $existing_urls $name] == -1 } {
                lappend existing_urls $name
            }
        }
    } 

    if { $folder ne "" } {
        if { [lsearch $existing_urls $folder] != -1 } {
            # The folder is on the list
            if { $current_node_id eq "" } {
                # New node: Complain
                return {}
            } else {
                # Renaming an existing node: Check to see if the node is merely conflicting with itself
                set parent_url [site_node::get_url -node_id $parent_node_id]
                set new_node_url "$parent_url$folder"
                if { ![site_node::exists_p -url $new_node_url] || \
                         $current_node_id != [site_node::get_node_id -url $new_node_url] } {
                    return {}
                }
            }
        }
    } else {
        # Autogenerate folder name
        if { $instance_name eq "" } {
            error "Instance name must be supplied when folder name is empty."
        }

        set folder [util_text_to_url \
                        -existing_urls $existing_urls \
                        -text $instance_name]
    }
    return $folder
}



##############
#
# Deprecated Procedures
#
#############


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
    } on_error {
        site_node::update_cache -node_id $node_id
    }
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

        if {$delete_p == "t"} {
            site_node::delete -node_id $node_id
        }
    }
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

ad_proc -deprecated -warn site_node_closest_ancestor_package {
    { -default "" }
    { -url "" }
    package_keys
} {
    <p>
    Use site_node::closest_ancestor_package. Note that 
    site_node_closest_ancestor_package will include the passed-in node in the 
    search, whereas the new proc doesn't by default. If you want to include 
    the passed-in node, call site_node::closest_ancestor_package with the 
    -include_self flag
    </p>

    <p>
    Finds the package id of a package of specified type that is
    closest to the node id represented by url (or by ad_conn url).Note
    that closest means the nearest ancestor node of the specified
    type, or the current node if it is of the correct type.

    <p>

    Usage:

    <pre>
    # Pull out the package_id of the subsite closest to our current node
    set pkg_id [site_node::closest_ancestor_package -include_self -package_key "acs-subsite"]
    </pre>

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 1/17/2001

    @param default The value to return if no package can be found
    @param current_node_id The node from which to start the search
    @param package_keys The type(s) of the package(s) for which we are looking

    @return <code>package_id</code> of the nearest package of the
    specified type (<code>package_key</code>). Returns $default if no
    such package can be found.

    @see site_node::closest_ancestor_package
} {
    if {$url eq ""} {
        set url [ad_conn url]
    }

    # Try the URL as is.
    if {[catch {nsv_get site_nodes $url} result] == 0} {
        array set node $result
        if {$node(package_key) in $package_keys} {
            return $node(package_id)
        }
    }
    
    # Add a trailing slash and try again.
    if {[string index $url end] ne "/"} {
        append url "/"
        if {[catch {nsv_get site_nodes $url} result] == 0} {
            array set node $result
            if {$node(package_key) in $package_keys} {
                return $node(package_id)
            }
        }
    }
    
    # Try successively shorter prefixes.
    while {$url ne ""} {
        # Chop off last component and try again.
        set url [string trimright $url /]
        set url [string range $url 0 [string last / $url]]
        
        if {[catch {nsv_get site_nodes $url} result] == 0} {
            array set node $result
            if {$node(pattern_p) == "t" 
                && $node(object_id) ne "" 
                && $node(package_key) in $package_keys} {
                return $node(package_id)
            }
        }
    }
    
    return $default
}

ad_proc -deprecated -public site_node_closest_ancestor_package_url {
    { -default "" }
    { -package_key {} }
} {
    Returns the url stub of the nearest application of the specified
    type.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-02-05

    @param package_key The types of packages for which we're looking (defaults to subsite packages)
    @param default The default value to return if no package of the
    specified type was found

    @see site::node::closest_ancestor_package
} {
    if {$package_key eq ""} {
        set package_key [subsite::package_keys]
    }

    set subsite_pkg_id [site_node::closest_ancestor_package \
                            -include_self \
                            -package_key $package_key \
                            -url [ad_conn url] ]

    if {$subsite_pkg_id eq ""} {
        # No package was found... return the default
        return $default
    }

    return [lindex [site_node::get_url_from_object_id -object_id $subsite_pkg_id] 0]
}

ad_proc -public site_node::conn_url {
} {
    Use this in place of ns_conn url when referencing host_nodes.
    This proc returns the appropriate ns_conn url value, depending on
    if host_node_map is used for current connection, or hostname's
    domain.
} {
    set ns_conn_url [ns_conn url]
    set subsite_get_url [subsite::get_url]
    set joined_url [file join $subsite_get_url $ns_conn_url]
    # join drops ending slash for some cases. Add back if appropriate.
    if { [string range $ns_conn_url end end] eq "/" && [string range $joined_url end end] ne "/" } {
        append joined_url "/"
    }
    return $joined_url
}


#####################################################################
# old end of file
#####################################################################

if {$UseXotclSiteNodes} {

    #
    # If we are in this branch of the "if" statement, we want to use the
    # XOTcl-based infrastructure.
    #
    # First, we define a class for handling SiteNodes in the ::xo
    # namespace (like other XOTcl based support functions). Afterwards
    # we define some of the procs above to used this infrastructure.
    #

    namespace eval ::xo {

        #####################################################
        # @class SiteNode
        #####################################################
        #
        #    This class capsulates access to site-nodes stored in the
        #    database.  It is written in a style to support the the needs
        #    of the Tcl-based API above.
        #
        # @author Gustaf Neumann

        ::nx::Class create SiteNode {

            #
            # @method get 
            #    returns a site node from url or site-node with all its context info
            #

            :public method get {
                {-url ""}
                {-node_id ""}
            } {
                if {$url eq "" && $node_id eq ""} {
                    error "site_node::get \"must pass in either url or node_id\""
                }

                #
                # make sure, we have a node_id
                #
                if {$node_id eq ""} {
                    set node_id [:get_node_id -url $url]
                }
                
                return [:properties -node_id $node_id]
            }

            #
            # @method properties 
            #    returns a site node from node_id with all its context info
            #

            :protected method properties {
                 -node_id:integer,required
             } {
                #
                # Get url, since it is not returned by the later query. 
                
                # TODO: I did not want to modifiy the query for the time
                # being. When doing the Oracle support, the retrieval of the URL
                # should be moved into the query below....
                #
                set url [:get_url -node_id $node_id]
                
                #
                # get site-node with context from the database
                #
                ::db_1row dbqd.acs-tcl.tcl.site-nodes-procs.site_node::update_cache.select_site_node {}
                
                set object_type [expr {$package_id eq "" ? "" : "apm_package"}]    
                set list [list url $url node_id $node_id parent_id $parent_id name $name \
                              directory_p $directory_p pattern_p $pattern_p  object_id $object_id \
                              object_type $object_type  package_key $package_key package_id $package_id \
                              instance_name $instance_name package_type $package_type]
                return $list
            }
            
            #
            # @method get_children 
            #    get children of a site node
            #

            :public method get_children {
                -node_id:required 
                -all:switch
                {-package_type ""} 
                {-package_key ""}
                {-filters ""} 
                {-element ""}
            } {
                #
                # Fitering happens here exactly like in the nsv-based version. If should be possible to 
                # realize (at least some of the) filtering via the SQL query
                #
                if {$all} {
                    #
                    # the following query is just for PG, TODO: Oracle is missing
                    #
                    set child_urls [::xo::dc list [current method]-all {
                        select site_node__url(children.node_id) 
                        from site_nodes as parent, site_nodes as children
                        where parent.node_id = :node_id 
                        and children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
                        and children.tree_sortkey <> parent.tree_sortkey
                    }]
                } else {
                    if {$package_key ne ""} {
                        #
                        # Simple optimization for package_keys; seems to be frequenty used.
                        # We leave the logic below unmodified, which could be optimized as well.
                        #
                        set package_key_clause "and package_id = object_id and package_key = :package_key"
                        set from "site_nodes, apm_packages"
                    } else {
                        set package_key_clause ""
                        set from "site_nodes"
                    }
                    set sql [::xo::dc select \
                                 -vars site_node__url(node_id) \
                                 -from $from \
                                 -where "parent_id = :node_id $package_key_clause" \
                                 -map_function_names true]
                    set child_urls [::xo::dc list [current method] $sql]
                }
                
                if { $package_type ne "" } {
                    lappend filters package_type $package_type
                } elseif { $package_key ne "" } {
                    lappend filters package_key $package_key
                }
                
                if { [llength $filters] > 0 } {
                    set return_val [list]
                    foreach child_url $child_urls {
                        array unset site_node
                        if {![catch {array set site_node [:get -url $child_url]}]} {
                            
                            set passed_p 1
                            foreach { elm val } $filters {
                                if { $site_node($elm) ne $val } {
                                    set passed_p 0
                                    break
                                }
                            }
                            if { $passed_p } {
                                if { $element ne "" } {
                                    lappend return_val $site_node($element)
                                } else {
                                    lappend return_val $child_url
                                }
                            }
                        }
                    }
                } elseif { $element ne "" } {
                    set return_val [list]
                    foreach child_url $child_urls {
                        array unset site_node
                        if {![catch {array set site_node [:get -url $child_url]}]} {
                            lappend return_val $site_node($element)
                        }
                    }
                } else {
                    set return_val $child_urls
                }
                
                return $return_val
            }
            
            
            #
            # @method get_urls_from_object_id 
            #
            #    returns a list of urls for site_nodes that have the given
            #    object mounted or the empty list if there are none. The urls
            #    will be returned in descending order meaning any children
            #    will come before their parents. This ordering is useful when
            #    deleting site nodes as we must delete child site nodes before
            #    their parents.
            #
            
            :public method get_urls_from_object_id {
                -object_id:required 
            } {
                #
                # the following query is just for PG, TODO: Oracle is missing
                #
                set child_urls [::xo::dc list [current method]-all {
                    select site_node__url(node_id) 
                    from site_nodes 
                    where object_id = :object_id
                    order by tree_sortkey desc
                }]
            }
            
            :public method get_urls_from_package_key {
                -package_key:required 
            } {
                return [::xo::dc list [current method]-urls-from-package-key {
                    select site_node__url(node_id) 
                    from site_nodes n, apm_packages p
                    where p.package_key = :package_key
                    and n.object_id = p.package_id
                }]
            }

            #
            # @method get_node_id get_package_url
            #   just a small stub for a special case for method 
            #   get_urls_from_package_key
            #
            :public method get_package_url {
                -package_key:required
            } {
                return [lindex [:get_urls_from_package_key -package_key $package_key] 0]
            }

            #
            # @method get_node_id 
            #    obtain node id from url, using directly the stored procedure
            #    site_node.node_id
            #
            #    ::xo::db::sql::site_node node_id -url url  ?-parent_id parent_id?
            #
            :public forward get_node_id ::xo::db::sql::site_node node_id

            #
            # @method get_url
            #    obtain url from node-id, using directly the stored procedure
            #    site_node.url
            #
            #    ::xo::db::sql::site_node url -node_id node_id
            #
            :public forward get_url ::xo::db::sql::site_node url

            #
            # @method flush_cache
            #    a stub to be overloaded by the cache manager
            #
            :public method flush_cache {{-node_id ""} {-with_subtree:boolean}} {;}
            
            # Create an object "site_node" to provide a user-interface close
            # to the classical one.
            :create site_node
        }

        #####################################################
        # Caching
        #####################################################

        if {[catch {ns_cache flush xo_site_nodesNOTHING}]} {
            ns_log notice "xotcl-core: creating xo_site_nodes cache"
            ns_cache create xo_site_nodes -size 2000000
        }

        #
        # SiteNodeCache is a mixin class for caching the SiteNode objects.
        # Add/remove caching methods as wanted. Removing the registry of
        # the object mixin deactivates caching for these methods
        # completely.
        #

        ::nx::Class create SiteNodeCache {

            :public method get_children {
                -node_id:required 
                {-all:switch} {-package_type ""} {-package_key ""} {-filters ""} {-element ""}
            } {
                ns_cache_eval xo_site_nodes get_children-$node_id-$all-$package_type-$package_key-$filters-$element { next }
            }

            :public method get_node_id {-url:required} {
                ns_cache_eval xo_site_nodes id-$url { next }
            }

            :protected method properties {-node_id:required} {
                ns_cache_eval xo_site_nodes p-$node_id { next }
            }

            :public method get_url {-node_id:required} {
                ns_cache_eval xo_site_nodes url-$node_id { next }
            }

            :public method get_urls_from_object_id {-object_id:required} {
                ns_cache_eval xo_site_nodes urls-$object_id { next }
            }

            # The cache value from the following method is currently not
            # flushed, but just used for package keys, not instances, so it
            # should be safe.
            :public method get_package_url {-package_key:required} {
                ns_cache_eval xo_site_nodes package_url-$package_key { next }
            }

            :protected method flush_all {patterns} {
                foreach pattern $patterns {
                    foreach key [ns_cache names xo_site_nodes $pattern] {
                        #:msg ......key=$key
                        ::xo::clusterwide ns_cache flush xo_site_nodes $key
                    }
                }
            }

            :public method flush_cache {{-node_id ""} {-with_subtree:boolean true}} {
                # 
                # Flush entries from site-node tree, including the current node,
                # the root of flushed (sub)tree. If the node_id is not provided,
                # or it is the node_id of root of the full site-node tree, flush
                # the whole tree.
                #

                set old_url [:get_url -node_id $node_id]

                if {$node_id eq "" || $old_url eq "/"} {
                    foreach i [ns_cache names xo_site_nodes] {
                        ::xo::clusterwide ns_cache flush xo_site_nodes $i
                    }
                } else {
                    set limit_clause [expr {$with_subtree ? "" : "limit 1"}]
                    #
                    # the following query is just for PG, TODO: Oracle is missing
                    #
                    set tree [::xo::dc list_of_lists [current method]-flush-tree "
            select site_node__url(children.node_id), children.node_id, children.object_id
            from site_nodes as parent, site_nodes as children
            where parent.node_id = :node_id 
            and children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
            $limit_clause
          "]
                    foreach entry $tree {
                        foreach {url node_id object_id} $entry break
                        foreach key [list p-$node_id url-$node_id urls-$object_id] {
                            ::xo::clusterwide ns_cache flush xo_site_nodes $key
                        }
                        :flush_all get_children-$node_id-*
                    }
                    regsub {/$} $old_url "" old_url
                    :flush_all id-$old_url*
                }
            }

        }

        # Turn on caching by registering the mixin (backward compatibility
        # for early XOTcl2-versions, probably not needed anymore).
        if {"2.0.0" in [package versions nsf]} {
            site_node object mixins add SiteNodeCache
        } else {
            site_node object mixin add SiteNodeCache
        }
    }

    #####################################################################
    # Begin of overwritten procs from above
    #####################################################################
    #
    # The site-node implementation above depends on the nsv-array
    # "site_nodes". We have to overwrite this API to avoid these calls
    # and/or to use the XOTcl-based infrastructure.

    ad_proc -public site_node::new {
        {-name:required}
        {-parent_id:required}
        {-directory_p t}
        {-pattern_p t}
    } {
        create a new site node
    } {
        set var_list [list \
                          [list name $name] \
                          [list parent_id $parent_id] \
                          [list directory_p $directory_p] \
                          [list pattern_p $pattern_p]]
        
        set node_id [package_instantiate_object -var_list $var_list site_node]
        return $node_id
    }
    
    ad_proc -public site_node::mount {
        {-node_id:required}
        {-object_id:required}
        {-context_id}
    } {
        mount object at site node
    } {
        db_dml mount_object {}
        db_dml update_object_package_id {}

        # We might have for this node_id (or under it) some entries in the
        # cache, so flush these first.
        site_node::update_cache -sync_children -node_id $node_id
        
        # DAVEB update context_id if it is passed in
        # some code relies on context_id to be set by
        # instantiate_and_mount so we can't assume
        # anything at this point. Callers that need to set context_id
        # for example, when an unmounted package is mounted,
        # should pass in the correct context_id
        if {[info exists context_id]} {
            db_dml update_package_context_id ""
        }

        set package_key [apm_package_key_from_id $object_id]
        foreach inherited_package_key [nsv_get apm_package_inherit_order $package_key] {
            apm_invoke_callback_proc \
                -package_key $inherited_package_key \
                -type after-mount \
                -arg_list [list package_id $object_id node_id $node_id]
        }
    }

    ad_proc -private site_node::init_cache {} {
        Initialize the site node cache; actually, this means flushing the 
        cache in case we have root site node.
    } {
        ns_log notice "site_node::init_cache"
        set root_node_id [::db_string get_root_node_id {} -default {}]
        if { $root_node_id ne "" } {
            # If we are called during the *-init procs, the database
            # interface might not be initialized yet. However, in this
            # situation, there is nothing to flush yet.
            if {[info command ::xo::db::sql::site_node] ne ""} {
                ::xo::site_node flush_cache -node_id $root_node_id
            }
        }
    }

    ad_proc -private site_node::update_cache {
        {-sync_children:boolean}
        {-node_id:required}
    } {
        Brings the in memory copy of the site nodes hierarchy in sync with the
        database version. Only updates the given node and its children.
    } {
        #ns_log Notice "site_node::update_cache for node_id $node_id"
        ::xo::site_node flush_cache -node_id $node_id -with_subtree $sync_children_p
    }

    ad_proc -public site_node::get {
        {-url ""}
        {-node_id ""}
    } {
        Returns an array representing the site node that matches the given url.
        Either url or node_id is required, if both are passed url is ignored.
        The array elements are: package_id, package_key, object_type, directory_p, 
        instance_name, pattern_p, parent_id, node_id, object_id, url.
    } {
        return [::xo::site_node get -url $url -node_id $node_id]
    }

    ad_proc -public site_node::get_from_url {
        {-url:required}
        {-exact:boolean}
    } {
        Returns an array representing the site node that matches the given url.<p>

        A trailing '/' will be appended to $url if required and not present.<p>

        If the '-exact' switch is not present and $url is not found, returns the
        first match found by successively removing the trailing $url path component.<p>

        @see site_node::get
    } {
        # TODO: The switch "-exact" does nothing here... Needed?
        return [::xo::site_node get -node_id [::xo::site_node get_node_id -url $url]]
    }

    ad_proc -public site_node::exists_p {
        {-url:required}
    } {
        Returns 1 if a site node exists at the given url and 0 otherwise.
    } {

        set url_no_trailing [string trimright $url "/"]

        # get_node_id returns always a node_id, which might be the node_id
        # of the root. In order to check, whether the provided url is
        # really a site-node, we do an inverse lookup and check whether
        # the returned node_id has the same url as the provided one.
        #
        set node_id [::xo::site_node get_node_id -url $url_no_trailing]
        return [expr {[::xo::site_node get_url -node_id $node_id] eq "$url_no_trailing/"}]
    }

    ad_proc -public site_node::get_url {
        {-node_id:required}
        {-notrailing:boolean}
    } {
        return the url of this node_id

        @notrailing If true then strip any
        trailing slash ('/'). This means the empty string is returned for the root.
    } {
        set url [::xo::site_node get_url -node_id $node_id]
        if { $notrailing_p } {
            set url [string trimright $url "/"]
        }
        return $url
    }

    ad_proc -public site_node::get_url_from_object_id {
        {-object_id:required}
    } {
        returns a list of urls for site_nodes that have the given object
        mounted or the empty list if there are none. The
        url:s will be returned in descending order meaning any children will
        come before their parents. This ordering is useful when deleting site nodes
        as we must delete child site nodes before their parents.
    } {
        ::xo::site_node get_urls_from_object_id -object_id $object_id
    }

    ad_proc -public site_node::get_children {
        {-all:boolean}
        {-package_type {}}
        {-package_key {}}
        {-filters {}}
        {-element {}}
        {-node_id:required}
    } {
        This proc gives answers to questions such as: What are all the package_id's 
        (or any of the other available elements) for all the instances of package_key or package_type mounted
        under node_id xxx?

        @param node_id       The node for which you want to find the children.

        @option all          Set this if you want all children, not just direct children
        
        @option package_type If specified, this will limit the returned nodes to those with an
        package of the specified package type (normally apm_service or 
                                               apm_application) mounted. Conflicts with the -package_key option.
        
        @param package_key   If specified, this will limit the returned nodes to those with a
        package of the specified package key mounted. Conflicts with the
        -package_type option. Can take one or more packges keys as a Tcl list.

        @param filters       Takes a list of { element value element value ... } for filtering 
        the result list. Only nodes where element is value for each of the 
        filters in the list will get included. For example: 
        -filters { package_key "acs-subsite" }.
        
        @param element       The element of the site node you wish returned. Defaults to url, but 
        the following elements are available: object_type, url, object_id,
        instance_name, package_type, package_id, name, node_id, directory_p.
        
        @return A list of URLs of the site_nodes immediately under this site node, or all children, 
        if the -all switch is specified.
    } {
        ::xo::site_node get_children -all=$all_p -package_type $package_type -package_key $package_key \
            -filters $filters -element $element -node_id $node_id
    }

    ad_proc -public site_node::get_package_url {
        {-package_key:required}
    } {
        Get the URL of any mounted instance of a package with the given package_key.

        If there is more than one mounted instance of a package, returns
        the first URL. To see all of the mounted URLs, use the 
        site_node::get_children proc.

        @return a URL, or empty string if no instance of the package is mounted.
        @see site_node::get_children
    } {
        return [::xo::site_node get_package_url -package_key $package_key]
    }

    ad_proc -deprecated -warn site_node_closest_ancestor_package {
        { -default "" }
        { -url "" }
        package_keys
    } {
        <p>
        Use site_node::closest_ancestor_package. Note that 
        site_node_closest_ancestor_package will include the passed-in node in the 
        search, whereas the new proc doesn't by default. If you want to include 
        the passed-in node, call site_node::closest_ancestor_package with the 
        -include_self flag
        </p>

        <p>
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

        @param default The value to return if no package can be found
        @param current_node_id The node from which to start the search
        @param package_keys The type(s) of the package(s) for which we are looking

        @return <code>package_id</code> of the nearest package of the
        specified type (<code>package_key</code>). Returns $default if no
        such package can be found.

        @see site_node::closest_ancestor_package
    } {

        if {$url eq ""} {
            set url [ad_conn url]
        }

        set result [site_node::closest_ancestor_package -package_key $package_keys -url $url -include_self]
        if {$result eq ""} {
            set result $default
        }
        return $result
    }
    #
    # End of overwritten procs.
    #
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

