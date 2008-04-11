ad_library {

    site node api

    @author rhs@mit.edu
    @author yon (yon@openforce.net)
    @creation-date 2000-09-06
    @cvs-id $Id$

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
    
        if { ![empty_string_p $package_key] } {
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

    apm_invoke_callback_proc -package_key [apm_package_key_from_id $object_id] -type "after-mount" -arg_list [list node_id $node_id package_id $object_id]

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
    if { [empty_string_p $node_id] } {
        # Default parent node to the main site
        if { [empty_string_p $parent_node_id ] } {
            set parent_node_id [site_node::get_node_id -url "/"]
        }

        # Default node_name to package_key
        if { [empty_string_p $node_name] } {
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

            if { [exists_and_not_null node(object_id)] } {
                error "Cannot mount package at url $url as package $node(object_id) is already mounted there"
            }

            set node_id $node(node_id)
        }
    }

    # Default context id to the closest ancestor package_id
    if { [empty_string_p $context_id] } {
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
    apm_invoke_callback_proc -package_key [apm_package_key_from_id $package_id] -type before-unmount -arg_list [list package_id $package_id node_id $node_id]

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
    if { ![empty_string_p $root_node_id] } {
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

        array set nodes [nsv_array get site_nodes]
        array set url_by_node_id [nsv_array get site_node_url_by_node_id]
        array set url_by_object_id [nsv_array get site_node_url_by_object_id]
        array set url_by_package_key [nsv_array get site_node_url_by_package_key]
        
        # Lars: We need to record the object_id's touched, so we can sort the 
        # object_id->url mappings again. We store them sorted by length of the URL 
        if { [info exists url_by_node_id($node_id)] } {
            set old_url $url_by_node_id($node_id)
            if { $sync_children_p } {
                append old_url *
            }

            # This is a little cumbersome, but we have to remove the entry for
            # the object_id->url mapping, for each object_id that used to be 
            # mounted here
            
            # Loop over all the URLs under the node we're updating
            foreach cur_node_url [array names nodes $old_url] {
                array set cur_node $nodes($cur_node_url)

                # Find the object_id previously mounted there
                set cur_object_id $cur_node(object_id)
                if { ![empty_string_p $cur_object_id] } {
                    # Remove the URL from the url_by_object_id entry for that object_id
                    set cur_idx [lsearch -exact $url_by_object_id($cur_object_id) $cur_node_url]
                    if { $cur_idx != -1 } {
                        set url_by_object_id($cur_object_id) \
                            [lreplace $url_by_object_id($cur_object_id) $cur_idx $cur_idx]
                    }
                }
                
                # Find the package_key previously mounted there
                set cur_package_key $cur_node(package_key)
                if { ![empty_string_p $cur_package_key] } {
                    # Remove the URL from the url_by_package_key entry for that package_key
                    set cur_idx [lsearch -exact $url_by_package_key($cur_package_key) $cur_node_url]
                    if { $cur_idx != -1 } {
                        set url_by_package_key($cur_package_key) \
                            [lreplace $url_by_package_key($cur_package_key) $cur_idx $cur_idx]
                    }
                }
            }

            # unset old nodes-subtree
            array unset nodes $old_url
        }

        # Note that in the queries below, we use connect by instead of site_node.url
        # to get the URLs. This is less expensive.

        if { $sync_children_p } {
            set query_name select_child_site_nodes
        } else {
            set query_name select_site_node
        }
        
        db_foreach $query_name {} {
            if {[empty_string_p $parent_id]} {
                # url of root node
                set url "/"
            } else {
                # append directory to url of parent node
                set url $url_by_node_id($parent_id)
                append url $name
                if { $directory_p == "t" } { append url "/" }
            }
            # save new url
            set url_by_node_id($node_id) $url
            if { ![empty_string_p $object_id] } {
                lappend url_by_object_id($object_id) $url
            }
            if { ![empty_string_p $package_key] } {
                lappend url_by_package_key($package_key) $url
            }

            if { [empty_string_p $package_id] } {
                set object_type ""
            } else {
                set object_type "apm_package"
            }

            # save new node
            set nodes($url) \
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
        foreach object_id [array names url_by_object_id] {
                set url_by_object_id($object_id) [lsort \
                                                      -decreasing \
                                                      -command util::string_length_compare \
                                                      $url_by_object_id($object_id)]
        }

        # update arrays
        nsv_array reset site_nodes [array get nodes]
        nsv_array reset site_node_url_by_node_id [array get url_by_node_id]
        nsv_array reset site_node_url_by_object_id [array get url_by_object_id]
        nsv_array reset site_node_url_by_package_key [array get url_by_package_key]

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

    @notrailing If true then strip any
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
    if { ![empty_string_p $url] } {
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

    while {![string equal $node_id ""]} {
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
                         -package_type option.

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
    if { ![empty_string_p $package_type] && ![empty_string_p $package_key] } {
        error "You may specify either package_type, package_key, or filter_element, but not more than one."
    }

    if { ![empty_string_p $package_type] } {
        lappend filters package_type $package_type
    } elseif { ![empty_string_p $package_key] } {
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
                    if { ![string equal $site_node($elm) $val] } {
                        set passed_p 0
                        break
                    }
                }
                if { $passed_p } {
                    if { ![empty_string_p $element] } {
                        lappend return_val $site_node($element)
                    } else {
                        lappend return_val $child_url
                    }
                }
            }
        }
    } elseif { ![empty_string_p $element] } {
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
    if { ![empty_string_p $element]
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
    if { [empty_string_p $url] } {
          if { [empty_string_p $node_id] } {
              set url "/"
          } else {
              set url [site_node::get_url -node_id $node_id]
          }
    }

    # should we return the package at the passed-in node/url?
    if { $include_self_p && ![empty_string_p $package_key]} {
        array set node_array [site_node::get -url $url]

        if { [lsearch -exact $package_key $node_array(package_key)] != -1 } {
            return $node_array($element)
        }
    }

    set elm_value {}
    while { [empty_string_p $elm_value] && $url != "/"} {
        # move up a level
        set url [string trimright $url /]
        set url [string range $url 0 [string last / $url]]
        
        array set node_array [site_node::get -url $url]

        # are we looking for a specific package_key?
        if { [empty_string_p $package_key] || \
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
    if { ![empty_string_p $parent_node(package_key)] } {
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

    if { ![empty_string_p $folder] } {
        if { [lsearch $existing_urls $folder] != -1 } {
            # The folder is on the list
            if { [empty_string_p $current_node_id] } {
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
        if { [empty_string_p $instance_name] } {
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

        if {[string equal $delete_p t]} {
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
    set pkg_id [site_node_closest_ancestor_package "acs-subsite"]
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
    if {[empty_string_p $url]} {
        set url [ad_conn url]
    }

    # Try the URL as is.
    if {[catch {nsv_get site_nodes $url} result] == 0} {
          array set node $result
          if { [lsearch -exact $package_keys $node(package_key)] != -1 } {
              return $node(package_id)
          }
    }
    
    # Add a trailing slash and try again.
    if {[string index $url end] != "/"} {
          append url "/"
          if {[catch {nsv_get site_nodes $url} result] == 0} {
              array set node $result
              if { [lsearch -exact $package_keys $node(package_key)] != -1 } {
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
              if {$node(pattern_p) == "t" && $node(object_id) != "" && [lsearch -exact $package_keys $node(package_key)] != -1 } {
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
    if {[empty_string_p $package_key]} {
        set package_key [subsite::package_keys]
    }

    set subsite_pkg_id [site_node::closest_ancestor_package \
                            -include_self \
                            -package_key $package_key \
                            -url [ad_conn url] ]

    if {[empty_string_p $subsite_pkg_id]} {
        # No package was found... return the default
        return $default
    }

    return [lindex [site_node::get_url_from_object_id -object_id $subsite_pkg_id] 0]
}
