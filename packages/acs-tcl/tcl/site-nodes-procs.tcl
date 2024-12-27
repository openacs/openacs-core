ad_library {

    Site node API

    @author rhs@mit.edu
    @author yon (yon@openforce.net), Gustaf Neumann

}

#####################################################################
#
# The implementation depends just on XOTcl2/NX, which is required
# starting with OpenACS 5.10. This version replaced an old variant
# based on nsv, which was loading always all site nodes into an nsv
# array, an trying to maintain this. This approach turned out to be
# very costly on large sites, and was never fully debugged.
#
# The version below is much faster from a factor of two to a several
# thousand times.
#
# Some timings:
#
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
#   ds_comment [time {::acs::site_node get_children  -node_id $n(node_id)}]
#
# The code was tested on installations with NaviServer under
# PostgreSQL and Oracle, including new installs under PostgreSQL.
#
# Still missing: test on fresh new install with Oracle
# Still missing: tests for AOLserver
#
#####################################################################

namespace eval site_node {}

ad_proc -public site_node::delete_service_nodes  {
    {-node_id:required}
} {
    Unmount and delete all (shared) service packages under this
    site_node.

    @param node_id starting node_id
} {
    set sub_node_urls [site_node::get_children \
                           -node_id $node_id]
    foreach sub_node_url $sub_node_urls {
        set sub_node_id [site_node::get_element -url $sub_node_url -element node_id]
        set package_id [site_node::get_object_id -node_id $sub_node_id]
        if {$package_id ne ""
            && [db_0or1row is_apm_service {
                select 1 from apm_services
                where service_id = :package_id
            }]} {
            site_node::unmount -node_id $sub_node_id
            site_node::delete -node_id $sub_node_id
        }
    }
}

ad_proc -public site_node::delete {
    {-node_id:required}
    -delete_subnodes:boolean
    -delete_package:boolean
} {
    delete the site node
} {
    if {!$delete_subnodes_p} {
        set n_subnodes [llength [site_node::get_children \
                                     -node_id $node_id]]
        if {$n_subnodes != 0} {
            error "Site node has subnodes. To force use -delete_subnodes option"
        }
    }

    set nodes_to_delete {}

    # breadth-first visit of the node tree, so we can delete children
    # starting from leaves, then their parents and so on to the top
    # (and thus not triggering reference constraint errors)
    set queue [list $node_id]
    while {$queue ne ""} {
        set parent_id [lindex $queue 0]
        lappend nodes_to_delete $parent_id
        set queue [lrange $queue 1 end]
        lappend queue {*}[site_node::get_children \
                              -element "node_id" \
                              -node_id $parent_id]
    }

    # delete nodes in reverse order, starting from leaves
    foreach node_id [lreverse $nodes_to_delete] {
        # first delete package_id under this node...
        set package_id [site_node::get_object_id -node_id $node_id]
        set url [site_node::get_url -node_id $node_id]
        if {$delete_package_p} {
            apm_package_instance_delete $package_id
        }
        # ...then the node itself
        #
        # TODO: The names of the function in the database should be
        # aligned.
        #
        if {[db_driverkey ""] eq "oracle"} {
            acs::dc call site_node del -node_id $node_id
        } else {
            acs::dc call site_node delete -node_id $node_id
        }
        acs::dc call site_node delete -node_id $node_id
        update_cache -node_id $node_id -url $url -object_id $package_id
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
    set node_object_id [dict get [site_node::get -node_id $node_id] object_id]

    db_dml rename_node {}
    db_dml update_object_title {}

    update_cache -sync_children -node_id $node_id -url $node_url -object_id $node_object_id
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
            #ns_log notice "site_node::instantiate_and_mount NEW sitenode '$node_id'"
        } else {
            # Check that there isn't already a package mounted at the node
            set node [get -url $url]
            set object_id [expr {[dict exists $node object_id] ? [dict get $node object_id] : ""}]
            if { $object_id ne "" } {
                error "Cannot mount package at url $url as package $object_id is already mounted there"
            }

            set node_id [dict get $node node_id]
        }
    }

    # Default context id to the closest ancestor package_id
    if { $context_id eq "" } {
        set context_id [site_node::closest_ancestor_package -node_id $node_id]
    }
    #ns_log notice "site_node::instantiate_and_mount -node_id '$node_id' context_id '$context_id'"

    # Instantiate the package
    set package_id [apm_package_instance_new \
                        -package_id $package_id \
                        -package_key $package_key \
                        -instance_name $package_name \
                        -context_id $context_id]
    #ns_log notice "site_node::instantiate_and_mount -node_id '$node_id' context_id '$context_id' package_id '$package_id'"

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
    set url [site_node::get_url -node_id $node_id]
    db_dml unmount_object {}
    db_dml update_object_package_id {}
    update_cache -node_id $node_id -url $url -object_id $package_id
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
    return [dict get [site_node::get -node_id $node_id -url $url] $element]
}

ad_proc -public site_node::get_from_node_id {
    {-node_id:required}
} {
    returns an array representing the site node for the given node_id

    @see site_node::get
} {
    return [get_from_url -url [get_url -node_id $node_id]]
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

ad_proc -public site_node::get_node_id {
    {-url:required}
} {
    @return the node_id for this url
} {
    return [dict get [get -url $url] node_id]
}

ad_proc -public site_node::get_node_id_from_object_id {
    {-object_id:required}
} {
    @return the site node id associated with the given object_id
} {
    set urls [get_url_from_object_id -object_id $object_id]
    if {[llength $urls] == 0} {
        set url ""
    } else {
        if {[llength $urls] > 1} {
            ad_log warning "get_node_id_from_object_id for object $object_id returns [llength $urls] URLs, first one is returned"
        }
        set url [lindex $urls 0]
    }
    if { $url ne "" } {
        return [get_node_id -url $url]
    } else {
        return {}
    }
}

ad_proc -public site_node::get_parent_id {
    {-node_id:required}
} {
    @return the parent_id of this node
} {
    return [dict get [get -node_id $node_id] parent_id]
}

ad_proc -public site_node::get_parent {
    {-node_id:required}
} {
    @return the parent node of this node
} {
    return [get -node_id [get_parent_id -node_id $node_id]]
}

ad_proc -public site_node::get_ancestors {
    {-node_id:required}
    {-element ""}
} {
    @return the ancestors of this node
} {
    set result [list]
    set array_result_p [string equal $element ""]

    while {$node_id ne "" } {
        set node [get -node_id $node_id]

        if {$array_result_p} {
            lappend result $node
        } else {
            lappend result [dict get $node $element]
        }

        set node_id [dict get $node parent_id]
    }

    return $result
}

ad_proc -public site_node::get_object_id {
    {-node_id:required}
} {
    @return the object_id for this node
} {
    return [dict get [get -node_id $node_id] object_id]
}

ad_proc -public site_node::closest_ancestor_package {
    {-url ""}
    {-node_id ""}
    {-package_key ""}
    {-include_self:boolean}
    {-element "object_id"}
} {
    Starting with the node of the given id, or at given url,
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
    #
    # Make sure we have a URL to work with
    #
    if { $url eq "" } {
        if { $node_id eq "" } {
            set url "/"
        } else {
            set url [site_node::get_url -node_id $node_id]
        }
    }

    #ns_log notice "closest_ancestor_package still [list -url $url urlv [ns_conn urlv]]"

    #
    # GN: Make sure, the URL does not end with multiple slashes. The
    # following regsub is from the standard's point of view not
    # correct, since a URL path /%2f/ is syntactically permissible,
    # but this is not supported in the current site-nodes code. It
    # would be correct, to avoid the parsing of the slashes here and
    # to process instead the result of [ns_conn urlv], which is
    # already parsed (before the percent substitutions). This would
    # probably require the request processor to perform some mangling
    # of urlv in vhost cases to set a a proper [ad_conn urlv] ... and
    # of course to pass the "urlv" instead of the "url" to the
    # slash-parsing functions.
    #
    regsub {(/[/]*)/$} $url / url

    #ns_log notice "closest_ancestor_package simplified [list -url $url]"

    #
    # Should we return the package at the passed-in node/url?
    #
    if { $include_self_p && $package_key ne ""} {
        set node [site_node::get -url $url]
        #ns_log notice "=== [list site_node::get -url $url] => '$node'"

        if {[dict get $node package_key] in $package_key} {
            return [dict get $node $element]
        }
    }

    set elm_value {}
    while { $elm_value eq "" && $url ne "/"} {
        # move up a level
        set url [string trimright $url /]
        set url [string range $url 0 [string last / $url]]
        set node [site_node::get -url $url]

        # are we looking for a specific package_key?
        if { $package_key eq ""
             || [dict get $node package_key] in $package_key
         } {
            set elm_value [dict get $node $element]
        }
    }

    return $elm_value

}

ad_proc -public site_node::verify_folder_name {
    {-parent_node_id:required}
    {-current_node_id ""}
    {-instance_name ""}
    {-folder ""}
} {

    Verifies that the given folder name is valid for a folder under
    the given parent_node_id.  If current_node_id is supplied, it's
    assumed that we're renaming an existing node, not creating a new
    one.  If folder name is not supplied, we'll generate one from the
    instance name, which must then be supplied.

    @return folder name, or empty string if the supplied folder name wasn't acceptable.

} {
    set existing_urls [site_node::get_children -node_id $parent_node_id -element name]

    array set parent_node [site_node::get -node_id $parent_node_id]
    if { $parent_node(package_key) ne "" } {
        # Find all the page or directory names under this package
        foreach path [glob -nocomplain -types d "[acs_package_root_dir $parent_node(package_key)]/www/*"] {
            lappend existing_urls [lindex [ad_file split $path] end]
        }
        foreach path [glob -nocomplain -types f "[acs_package_root_dir $parent_node(package_key)]/www/*.adp"] {
            lappend existing_urls [file rootname [lindex [ad_file split $path] end]]
        }
        foreach path [glob -nocomplain -types f "[acs_package_root_dir $parent_node(package_key)]/www/*.tcl"] {
            set name [file rootname [lindex [ad_file split $path] end]]
            if { $name ni $existing_urls } {
                lappend existing_urls $name
            }
        }
    }

    if { $folder ne "" } {
        if { $folder in $existing_urls } {
            # The folder is on the list
            if { $current_node_id eq "" } {
                # New node: Complain
                return {}
            } else {
                # Renaming an existing node: Check to see if the node is merely conflicting with itself
                set parent_url [site_node::get_url -node_id $parent_node_id]
                set new_node_url "$parent_url$folder"
                if { ![site_node::exists_p -url $new_node_url]
                     || $current_node_id != [site_node::get_node_id -url $new_node_url]
                 } {
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

namespace eval ::acs {

    #####################################################
    # @class acs::SiteNode
    #####################################################
    #
    #    This class capsulates access to site-nodes stored in the
    #    database.  It is written in a style to support the needs
    #    of the Tcl-based API above.
    #
    # @author Gustaf Neumann

    ::nx::Class create ::acs::SiteNode {

        :public method get {
            {-url ""}
            {-node_id ""}
        } {
            #
            # @return a site node from url or site-node with all its context info
            #

            if {$url eq "" && $node_id eq ""} {
                error "site_node::get \"must pass in either url or node_id\""
            }

            #
            # Make sure, we have a node_id.
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
            # Get URL, since it is not returned by the later query.

            # TODO: I did not want to modify the query for the time
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
            # Filtering happens here exactly like in the nsv-based
            # version. If should be possible to realize (at least
            # some of the) filtering via the SQL query.
            #
            if {$all} {
                #
                # The following query is just for PG.  Note that
                # the query should not return the root of the
                # tree.
                #
                set sql [subst {
                    WITH RECURSIVE site_node_tree(node_id, parent_id) AS (
                      select node_id, parent_id from site_nodes where node_id = :node_id
                    UNION ALL
                      select child.node_id, child.parent_id from site_node_tree, site_nodes child
                      where  child.parent_id = site_node_tree.node_id
                    ) select [acs::dc map_function_name site_node__url(node_id)]
                    from site_node_tree where node_id != :node_id
                }]
                if {[db_driverkey ""] eq "oracle"} {
                    set sql [string map [list "WITH RECURSIVE" "WITH"] $sql]
                }

                set child_urls [::acs::dc list -prepare integer dbqd..[current method]-all $sql]
            } else {
                if {$package_key ne ""} {
                    #
                    # Simple optimization for package_keys; seems to be frequently used.
                    # We leave the logic below unmodified, which could be optimized as well.
                    #
                    set package_key_clause "and package_id = object_id and package_key = :package_key"
                    set from "site_nodes, apm_packages"
                } else {
                    set package_key_clause ""
                    set from "site_nodes"
                }
                set sql [subst {
                    select [::acs::dc map_function_name {site_node__url(node_id)}]
                    from $from
                    where parent_id = :node_id $package_key_clause
                }]
                set child_urls [::acs::dc list dbqd..[current method] $sql]
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

        :method has_children {
            -node_id:required,integer,1..1
        } {
            #
            # Check, if the provided site-node has children.
            #
            # @return boolean value.
            #
            # ns_log notice "non-cached version of has_children called with $node_id"

            set children [::acs::dc list -prepare integer dbqd..has_children {
                select 1 from site_nodes where parent_id = :node_id
                FETCH NEXT 1 ROWS ONLY
            }]
            return [llength $children]
        }

        #
        # @method get_urls_from_object_id
        #
        #    returns a list of URLs for site_nodes that have the given
        #    object mounted or the empty list if there are none. The URLs
        #    will be returned in descending order meaning any children
        #    will come before their parents. This ordering is useful when
        #    deleting site nodes as we must delete child site nodes before
        #    their parents.
        #

        :public method get_urls_from_object_id {
            -object_id:required
        } {
            set child_urls [::acs::dc list -prepare integer dbqd..[current method]-all [subst {
                select [acs::dc map_function_name site_node__url(node_id)] as url
                from site_nodes
                where object_id = :object_id
                order by url desc
            }]]
        }

        :public method get_urls_from_package_key {
            -package_key:required
        } {
            #
            # Return potentially multiple URLs based on a package key.
            #
            # @param package_key
            #
            return [::acs::dc list -prepare varchar dbqd..[current method]-urls-from-package-key [subst {
                select [acs::dc map_function_name site_node__url(node_id)]
                from site_nodes n, apm_packages p
                where p.package_key = :package_key
                and n.object_id = p.package_id
            }]]
        }

        :public method get_package_url {
            -package_key:required
        } {
            #
            # Legacy interface: previous implementations of the
            # site-nodes assumed, that there is just one site-node
            # entry available for a package-key. This method
            # returns just the first answer form
            # get_urls_from_package_key
            #
            return [lindex [:get_urls_from_package_key -package_key $package_key] 0]
        }

        #
        # @method get_node_id
        #    obtain node id from url, using directly the stored procedure
        #    site_node.node_id
        #
        #    ::acs::dc call site_node node_id -url url  ?-parent_id parent_id?
        #
        :public forward get_node_id ::acs::dc call site_node node_id

        #
        # @method get_url
        #    obtain url from node-id, using directly the stored procedure
        #    site_node.url
        #
        #    ::acs::dc call site_node url -node_id node_id
        #
        :public forward get_url ::acs::dc call site_node url

        :public method flush_cache {
            -node_id:required,1..1
            {-with_subtree:boolean}
            {-url ""}
        } {
            #
            #  This is a stub method to be overloaded by some
            #  cache managers.
            #
        }

        # Create an object "acs::site_node" to provide a
        # user-interface close to the classical one.
        :create site_node
    }

    #
    # For these URLs we assume that the site_node will never
    # change, or require a broadcast flush, or reboot.
    #
    # TODO: make me configurable, after release of 5.10.
    site_node eval {
        set :static_site_nodes {/ 1 /dotlrn 1 /dotlrn/ 1 /register/ 1 /SYSTEM/ 1}
    }

    #####################################################
    # Caching
    #####################################################
    variable createCache

    if {[namespace which ::ns_cache_names] ne ""} {
        set createCache [expr {"site_nodes_cache" ni [::ns_cache_names]}]
    } else {
        set createCache [catch {ns_cache flush site_nodes_cache NOTHING}]
    }
    if {$createCache} {
        #
        # Create caches. The sizes can be tailored in the config
        # file like the following:
        #
        # ns_section ns/server/${server}/acs/acs-tcl
        #   ns_param SiteNodesCacheSize                    10MB
        #   ns_param SiteNodesCachePartitions               2
        #   ns_param SiteNodesChildenCacheSize             10MB
        #   ns_param SiteNodesChildenCachePartitions        2
        #   ns_param SiteNodesIdCacheSize                 200KB
        #
        ::acs::KeyPartitionedCache create ::acs::site_nodes_cache \
            -package_key acs-tcl \
            -parameter SiteNodesCache \
            -default_size 2MB
        #
        # In case we have "ns_hash" defined, we can use the
        # "HashKeyPartitionedCache". Otherwise fall back to the
        # plain cache.
        #
        if {[::acs::icanuse "ns_hash"]} {
            ::acs::HashKeyPartitionedCache create ::acs::site_nodes_id_cache \
                -package_key acs-tcl \
                -parameter SiteNodesIdCache \
                -default_size 100KB
        } else {
            ::acs::Cache create ::acs::site_nodes_id_cache \
                -package_key acs-tcl \
                -parameter SiteNodesIdCache \
                -default_size 100KB
        }

        ::acs::KeyPartitionedCache create ::acs::site_nodes_children_cache \
            -package_key acs-tcl \
            -parameter SiteNodesChildenCache \
            -default_size 100KB
    }

    #
    # acs::SiteNodesCache is a mixin class for caching the SiteNode objects.
    # Add/remove caching methods as wanted. Removing the registry of
    # the object mixin deactivates caching for these methods
    # completely.
    #
    ::nx::Class create ::acs::SiteNodesCache {

        :public method get_children {
            -node_id:required,integer,1..1
            {-all:switch}
            {-package_type ""}
            {-package_key ""}
            {-filters ""}
            {-element ""}
        } {
            #
            # Cache get_children operations, except, when "-all"
            # was specified.  The underlying operation can be quite
            # expensive, when huge site-node trees are
            # explored. Since the argument list influences the
            # results, we cache for every parameter combination.
            #
            # Since this cache contains subtrees, we have to flush
            # trees, which is implemented via pattern flushes. So
            # we use a separate cache to avoid long locks on
            # site-nodes in general.
            #
            if {$all} {
                #
                # Don't cache when $all is specified - seldom
                # used, a pain for invalidating.
                #
                next
            } else {
                ::acs::site_nodes_children_cache eval -partition_key $node_id \
                    get_children-$node_id-$all-$package_type-$package_key-$filters-$element {
                        next
                    }
            }
        }

        :method has_children {
            -node_id:required,integer,1..1
        } {
            ::acs::site_nodes_children_cache eval -partition_key $node_id \
                has_children-$node_id {
                    next
                }
        }

        :public method get_node_id {-url:required} {
            #
            # Cache the result of the upstream implementation of
            # get_node_id in the acs::site_nodes_id_cache cache.
            #
            acs::site_nodes_id_cache eval id-$url { next }
        }

        :protected method properties {-node_id:required,integer,1..1} {
            return [acs::per_request_cache eval -key acs-tcl.site_nodes_property-$node_id {
                ::acs::site_nodes_cache eval -partition_key $node_id $node_id { next }
            }]
        }

        :public method get_url {-node_id:required,1..1} {
            #
            # It's a pain, but OpenACS and its regression test
            # call "get_url" a few times with an empty node_id.
            # Shortcut these calls here to avoid problems with the
            # non-numeric partition_key.
            #
            if {$node_id eq ""} {
                set result ""
            } else {
                set result [::acs::site_nodes_cache eval \
                                -partition_key $node_id \
                                url-$node_id { next }]
            }
            return $result
        }

        :public method get_urls_from_object_id {-object_id:required,integer,1..1} {
            #
            # Cache the result of the upstream implementation of
            # get_urls_from_object_id in the acs::site_nodes_cache.
            #
            ::acs::site_nodes_cache eval -partition_key $object_id urls-$object_id { next }
        }

        :public method get_package_url {-package_key:required} {
            #
            # Cache the result of the upstream implementation of
            # get_package_url in the acs::site_nodes_cache.
            #
            # Note: the cache value from the following method must
            # currently be explicitly flushed. We do that, for
            # instance, when we mount a new package.
            #
            ::acs::site_nodes_cache eval -partition_key 0 package_url-$package_key { next }
        }

        :method flush_per_request_cache {} {
            array unset ::__node_id
        }

        :public method flush_pattern {{-partition_key ""} pattern} {
            #
            # Flush from the site-nodes caches certain
            # information. The method hides the actual caching
            # structure and is as well provided in conformance
            # with the alternative implementations
            # above. Depending on the specified pattern, it
            # reroutes the flushing request to different caches.
            #

            :flush_per_request_cache

            switch -glob -- $pattern {
                id-*           {set cache site_nodes_id_cache}
                get_children-* -
                has_children   {set cache site_nodes_children_cache}
                default        {set cache site_nodes_cache}
            }
            ::acs::$cache flush_pattern -partition_key $partition_key $pattern
        }

        :public method flush_cache {
            -node_id:required,1..1
            {-with_subtree:boolean true}
            {-url ""}
        } {
            #
            # Flush entries from site-node tree, including the current node,
            # the root of flushed (sub)tree. If the node_id is not provided,
            # or it is the node_id of root of the full site-node tree, flush
            # the whole tree.
            #

            :flush_per_request_cache

            set old_url [:get_url -node_id $node_id]

            if {$node_id eq "" || $old_url eq "/"} {
                #
                # When no node_id is given or the URL is specified
                # as top-url, flush all caches. This happens
                # e.g. in the regression test.
                #
                #ns_log notice "FLUSHALL"
                ::acs::site_nodes_cache flush_all
                ::acs::site_nodes_id_cache flush_all
                ::acs::site_nodes_children_cache flush_all

            } else {
                #
                # Get subtree from db
                #
                set sql [subst {
                    WITH RECURSIVE site_node_tree(node_id,parent_id,object_id)  AS (
                      select node_id, parent_id, object_id from site_nodes where node_id = :node_id
                    UNION ALL
                      select child.node_id, child.parent_id, child.object_id from site_node_tree, site_nodes child
                      where  child.parent_id = site_node_tree.node_id
                      and :with_subtree
                    )
                    select [acs::dc map_function_name site_node__url(node_id)], node_id, object_id
                    from site_node_tree
                }]
                if {[db_driverkey ""] eq "oracle"} {
                    set sql [string map [list "WITH RECURSIVE" "WITH"] $sql]
                    if { $with_subtree } {
                        set sql [string map [list ":with_subtree" "1 = 1"] $sql]
                    } else {
                        set sql [string map [list ":with_subtree" "1 = 0"] $sql]
                    }
                }

                set tree [::acs::dc list_of_lists -prepare integer,boolean dbqd..get_subtree $sql]

                foreach entry $tree {
                    lassign $entry url node_id object_id
                    foreach key [list $node_id url-$node_id] {
                        ::acs::site_nodes_cache flush -partition_key $node_id $key
                    }
                    if {$object_id ne ""} {
                        ::acs::site_nodes_cache flush -partition_key $object_id urls-$object_id
                    }
                    :flush_pattern -partition_key $node_id get_children-$node_id-*
                    ::acs::site_nodes_children_cache flush \
                        -partition_key $node_id \
                        has_children-$node_id
                }
                regsub {/$} $old_url "" old_url
                :flush_pattern id-$old_url*
            }
        }
    }

    ::nx::Class create ::acs::SiteNodeUrlspaceCache {
        #
        # Cache site-node information via ns_urlspace. We can use
        # the URL trie, which supports tree match operations, for
        # tree information. This means that for example for .vuh
        # handlers it is not necessary to cache the full url for
        # obtaining the site-node, like it was until now:
        #
        #    3839 id-/storage/view/installers/windows-installer/installer.htm
        #    3839 id-/storage/view/aolserver/install.tgz
        #    3839 id-/storage/view/tutorial/OpenACS_Tutorial.htm
        #    3839 id-/storage/view/openacs-dotlrn-conference-2007-spring/Methodology_ALPE.pdf
        #    3839 id-/storage/view/xowiki-resources/Assessment.jpg
        #    3839 id-/storage/view/tutorial-page-map.png
        #    ...
        #
        # Providing a single entry like
        #
        #    ns_urlspace set -key sitenode /storage/* 3839
        #
        # is sufficient for replacing all entries above.
        #

        :public method get_node_id {-url:required} {
            #
            # Get node_id for the provided URL. We have to
            # determine the partial URL for determining the site
            # node.
            #
            # @return node_id (integer)
            #

            #
            # This is the main interface of the
            # SiteNodeUrlspaceCache to provide a first-level
            # cache.
            #

            # Try per-request caching
            #
            if {[dict exists ${:static_site_nodes} $url]} {
                set key :node_id($url)
            } else {
                set key ::__node_id($url)
            }
            if {[info exists $key]} {
                #ns_log notice "==== returning cached value [set $key]"
                return [set $key]
            }

            #
            # Try to get value from urlspace
            #
            set ID [ns_urlspace get -id $::acs::siteNodesID -key sitenode $url]
            if {$ID eq ""} {
                #
                # Get value the classical way, caching potentially
                # the full url path in the site_nodes_id_cache.
                #
                set ID [next]
                #ns_log notice "--- get_node_id from site_nodes_id_cache <$url> -> <$ID>"
                if {$ID ne ""} {
                    #
                    # We got a valid ID. If we would add blindly a
                    # node_id for the returned URL (e.g. for "/*")
                    # and some other subnode is not jet resolved,
                    # we would obtain later the node_id of the
                    # parent_node although there is a subnode.
                    #
                    # We could address this by e.g. pre-caching
                    # all "inner nodes" or similar, but this
                    # requires a deeper analysis of larger sites.
                    #
                    # In earlier versions, we had here
                    #   ... {[site_node::get_children -node_id $ID] eq ""} ...
                    # but on site_node trees with huge number of entries,
                    # this is a waste.
                    #
                    if {![:has_children -node_id $ID]} {
                        #
                        # We are on a leaf-node of the site node
                        # tree. Get the shortened url and save it
                        # in the urlspace.
                        #
                        set short_url [site_node::get_url -node_id $ID]
                        set cmd [list ns_urlspace set -id $::acs::siteNodesID -key sitenode $short_url* $ID]
                        #ns_log notice "--- get_node_id save in urlspace <$cmd> -> <$ID>"
                        {*}$cmd
                        #ns_log notice "---\n[join [ns_urlspace list -id $::acs::siteNodesID] \n]"
                    }
                    return [set $key $ID]
                }
            }
            return $ID
        }

        :public method flush_cache {
            -node_id:required,1..1
            {-with_subtree:boolean true}
            {-url ""}
        } {
            #
            # Cleanup in the urlspace tree: Clear always the
            # full subtree via "-recurse" (maybe not always
            # necessary).
            #

            ::acs::clusterwide ns_urlspace unset -id $::acs::siteNodesID -recurse -key sitenode $url
            next
        }
    }
    site_node object mixins add SiteNodesCache

    if {[namespace which ns_urlspace] ne ""} {
        set ::acs::siteNodesID [ns_urlspace new]
        ns_log notice \
            "... using ns_urlspace $::acs::siteNodesID for reduced redundancy in site node caches"
        site_node object mixins add SiteNodeUrlspaceCache
    }

}

#
# Plain Tcl API using the definitions from above
#
ad_proc -public site_node::new {
    {-name:required}
    {-parent_id:required}
    {-directory_p t}
    {-pattern_p t}
} {
    Create a new site node

    @return node_id
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

    #
    # We have to flush from the parent_url (which might be a leaf
    # turning into an inner node)
    #
    set parent_node_id [site_node::get_parent_id -node_id $node_id]
    set url [site_node::get_url -node_id $parent_node_id]

    site_node::update_cache -sync_children -node_id $node_id -url $url -object_id $object_id
    #
    # The parent_node_id should in a mount operation never be
    # empty.
    #
    ::acs::site_nodes_cache flush_pattern \
        -partition_key $parent_node_id \
        get_children-$parent_node_id-*
    ::acs::site_nodes_children_cache flush \
        -partition_key $parent_node_id has_children-$parent_node_id
    #
    # This may be the first instance of this particular package.
    #
    ::acs::site_nodes_cache flush \
        -partition_key 0 \
        package_url-[apm_package_key_from_id $object_id]


    #
    # DAVEB: update context_id if it is passed in some code relies
    # on context_id to be set by instantiate_and_mount so we can't
    # assume anything at this point. Callers that need to set
    # context_id for example, when an unmounted package is
    # mounted, should pass in the correct context_id.
    #
    if {[info exists context_id]} {
        db_dml update_package_context_id {
            update acs_objects
            set context_id = :context_id
            where object_id = :object_id
        }
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
    cache in case we have a root site node.
} {
    #ns_log notice "site_node::init_cache"
    if {[db_0or1row get_root_node {
        select node_id as root_node_id
        from site_nodes
        where parent_id is null
    }]} {
        #
        # If we are called during the *-init procs, the database
        # interface might not be initialized yet. However, in this
        # situation, there is nothing to flush yet.
        #
        ::acs::site_node flush_cache -node_id $root_node_id
    }
    #ns_log notice "site_node::init_cache $root_node_id DONE"
}

ad_proc -public site_node::update_cache {
    {-sync_children:boolean}
    {-node_id:required}
    {-url ""}
    {-object_id ""}
} {
    Brings the in-memory copy of the site nodes hierarchy in sync with the
    database version. Only updates the given node and its children.
} {
    ::acs::site_node flush_cache \
        -node_id $node_id \
        -with_subtree $sync_children_p \
        -url $url

    set parent_node_id [site_node::get_parent_id -node_id $node_id]
    if {$parent_node_id ne ""} {
        ::acs::site_node flush_pattern \
            -partition_key $parent_node_id \
            get_children-$parent_node_id-*
    }

    #
    # In case update_cache is called after the deletion of the node
    # in the database, it is still necessary to flush for the
    # original object_id, but this can't be handled in the
    # recursive query of method "flush_cache".
    #
    if {$object_id ne ""} {
        ::acs::site_nodes_cache flush -partition_key $object_id urls-$object_id
    }
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
    return [::acs::site_node get -url $url -node_id $node_id]
}

ad_proc -public site_node::get_from_url {
    {-url:required}
    {-exact:boolean}
} {
    Returns an array representing the site node that matches the given url.

    A trailing '/' will be appended to $url if required and not present.

    If the '-exact' switch is not present and $url is not found, returns the
    first match found by successively removing the trailing $url path component.

    @see site_node::get
} {
    # TODO: The switch "-exact" does nothing here... Needed?
    return [::acs::site_node get -node_id [::acs::site_node get_node_id -url $url]]
}

ad_proc -public site_node::exists_p {
    {-url:required}
} {
    Returns 1 if a site node exists at the given url and 0 otherwise.

    @param url URL path starting with a slash.
} {
    set url_no_trailing [expr {$url eq "/" ? "/" : [string trimright $url "/"]}]
    #
    # The function "get_node_id" returns always a node_id, which
    # might be the node_id of the root. In order to check, whether
    # the provided URL is really a site-node, we do an inverse
    # lookup and check whether the returned node_id has the same
    # URL as the provided one.
    #
    set node_id [::acs::site_node get_node_id -url $url_no_trailing]
    return [expr {[::acs::site_node get_url -node_id $node_id] eq "$url_no_trailing/"}]
}

ad_proc -public site_node::get_url {
    {-node_id:required}
    {-notrailing:boolean}
} {
    return the url of this node_id

    @param notrailing If true then strip any trailing slash ('/').
    This means the empty string is returned for the root.
} {
    set url [::acs::site_node get_url -node_id $node_id]
    if { $notrailing_p } {
        set url [string trimright $url "/"]
    }
    return $url
}

ad_proc -public site_node::get_url_from_object_id {
    {-object_id:required}
} {
    Returns a list of URLs for site_nodes that have the given object
    mounted or the empty list if there are none. The
    url:s will be returned in descending order meaning any children will
    come before their parents. This ordering is useful when deleting site nodes
    as we must delete child site nodes before their parents.
} {
    ::acs::site_node get_urls_from_object_id -object_id $object_id
}

ad_proc -public site_node::get_children {
    {-all:boolean}
    {-package_type {}}
    {-package_key {}}
    {-filters {}}
    {-element {}}
    {-node_id:required}
} {

    This proc gives answers to questions such as: What are all the
    package_id's (or any of the other available elements) for all the
    instances of package_key or package_type mounted under node_id
    xxx?

    @param node_id       The node for which you want to find the children.

    @option all          Set this if you want all children, not just direct children

    @option package_type If specified, this will limit the returned nodes to those with
                         a package of the specified package type (normally apm_service or
                         apm_application) mounted. Conflicts with the -package_key option.

    @param package_key   If specified, this will limit the returned nodes to those with a
                         package of the specified package key mounted. Conflicts with the
                         -package_type option. Can take one or more packages keys as a Tcl list.

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
    ::acs::site_node get_children \
        -all=$all_p \
        -package_type $package_type \
        -package_key $package_key \
        -filters $filters \
        -element $element \
        -node_id $node_id
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
    return [::acs::site_node get_package_url -package_key $package_key]
}


#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
