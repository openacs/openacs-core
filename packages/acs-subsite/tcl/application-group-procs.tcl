# /packages/subsite/tcl/application-group-procs.tcl

ad_library {

    Procs to manage application groups

    @author oumi@arsdigita.com
    @creation-date 2001-02-01
    @cvs-id $Id$

}

namespace eval application_group {}

ad_proc -public application_group::contains_party_p {
    { -package_id "" }
    { -party_id "" }
    -include_self:boolean
} {
    Determines whether the party in question (identified by party_id) is 
    a contained by the application group identified by package_id.
    If package_id is not specified, and we have a connection, then the 
    proc will grab the package_id of the current package (i.e., 
    [ad_conn package_id]).

} {

    if {$package_id eq "" && [ad_conn isconnected]} {
        set package_id [ad_conn package_id]
    }

    if {$package_id eq ""} {
        error "application_group::contains_party_p - package_id not specified"
    }

    # Check if the party is a member of the application group, OR
    # the party *is* the application group.  This proc considers the
    # applcation group to contain itself.
    if {$include_self_p} {
    set found_p [db_string app_group_contains_party_p {
        select case when exists (
            select 1
            from application_group_element_map
            where package_id = :package_id
              and element_id = :party_id
          union all
            select 1
            from application_groups
            where package_id = :package_id
              and group_id = :party_id
        ) then 1 else 0 end
        from dual
    }]
    } else {
    set found_p [db_string app_group_contains_party_p {
        select case when exists (
            select 1
            from application_group_element_map
            where package_id = :package_id
              and element_id = :party_id
        ) then 1 else 0 end
        from dual
    }]

    }

    return $found_p

}

ad_proc -public application_group::contains_relation_p {
    { -package_id "" }
    { -rel_id "" }
} {
    Determines whether the relation in question (identified by rel_id) is 
    a contained by the application group identified by package_id.
    If package_id is not specified, and we have a connection, then the 
    proc will grab the package_id of the current package (i.e., 
    [ad_conn package_id]).
} {

    if {$package_id eq "" && [ad_conn isconnected]} {
        set package_id [ad_conn package_id]
    }

    if {$package_id eq ""} {
        error "application_group::contains_party_p - package_id not specified"
    }

    # Check if the rel belongs to the application group, OR
    # the party *is* the application group.  This proc considers the
    # application group to contain itself.
    set found_p [db_string app_group_contains_rel_p {
        select case when exists (
            select 1
            from application_group_element_map
            where package_id = :package_id
              and rel_id = :rel_id
        ) then 1 else 0 end
        from dual
    }]

    return $found_p
}

ad_proc -public application_group::contains_segment_p {
    { -package_id "" }
    { -segment_id "" }
} {
    Determines whether the segment in question (identified by segment_id) 
    "belongs" to the application group identified by package_id.
    If package_id is not specified, and we have a connection, then the 
    proc will grab the package_id of the current package (i.e., 
    [ad_conn package_id]).

} {

    if {$package_id eq "" && [ad_conn isconnected]} {
        set package_id [ad_conn package_id]
    }

    if {$package_id eq ""} {
        error "application_group::contains_segment_p - package_id not specified"
    }

    # Check if the party is a member of the application group, OR
    # the party *is* the application group.  This proc considers the
    # applcation group to contain itself.
    set found_p [db_string app_group_contains_segment_p {
        select case when exists (
            select 1
            from application_group_segments
            where package_id = :package_id
              and segment_id = :segment_id
        ) then 1 else 0 end
        from dual
    }]

    return $found_p
}


ad_proc -public application_group::group_id_from_package_id {
    -no_complain:boolean
    { -package_id "" }
} {
    Get the application_group of a package.  By default, if no application
    group exists, we throw an error.  The -no_complain flag will prevent
    the error from being thrown, in which case you'll just get an
    empty string if the application group doesn't exist.
} {

    if {$no_complain_p} {
        set no_complain_p t
    } else {
        set no_complain_p f
    }

    if { [ad_conn isconnected] } {
        if {$package_id eq ""} {
    	set package_id [ad_conn package_id]
        }
    }

    if {$package_id eq ""} {
        error "application_group::group_id_from_package_id - no package_id specified."
    }

    set group_id [db_exec_plsql application_group_from_package_id_query {
        begin
        :1 := application_group.group_id_from_package_id (
            package_id => :package_id,
            no_complain_p => :no_complain_p
        );
        end;
    }]

    return $group_id
}

ad_proc -public application_group::package_id_from_group_id {
    -group_id:required
} {

    Returns the package_id of a given application group.

} {
    return [db_string -cache_key application_group_pid_from_gid_${group_id} get {}]
}

ad_proc -public application_group::new {
    { -group_id "" } 
    { -group_type "application_group"}
    { -package_id "" }
    { -group_name "" }
    { -creation_user "" }
    { -creation_ip "" }
    { -email "" }
    { -url "" }
} {
    Creates an application group 
    (i.e., group of "users/parties of this application")

    Returns the group_id of the new application group.
} {

    if { [ad_conn isconnected] } {
        # Since we have a connection, default user_id / peeraddr
        # if they're not specified
        if { $creation_user eq "" } {
    	set creation_user [ad_conn user_id]
        }
        if { $creation_ip eq "" } {
    	set creation_ip [ad_conn peeraddr]
        }
        if { $package_id eq "" } {
    	set package_id [ad_conn package_id]
        }
    }

    if {$package_id eq ""} {
        error "application_group::new - package_id not specified"
    }

    if {$group_name eq ""} {
        set group_name [db_string group_name_query {
    	select substr(instance_name, 1, 90)
    	from apm_packages
    	where package_id = :package_id
        }]
        append group_name " Parties"
    }

    db_transaction {
        # creating the new group
        set group_id [db_exec_plsql add_group {}]
    }

    return $group_id

}

ad_proc -public application_group::delete {
    -group_id:required
} {
    Delete the given application group and all relational segments and constraints dependent
    on it (handled by the PL/[pg]SQL API
} {
    # LARS HACK:
    # Delete permissions on:
    # - the application group
    # - any relational segment of this group
    # - any relation with this gorup
    # We really ought to have cascading deletes on acs_permissions.grantee_id (and object_id)
    db_dml delete_perms {}

    db_exec_plsql delete {}

    db_flush_cache -cache_key_pattern application_group_*

}

ad_proc -public application_group::closest_ancestor_application_group_site_node {
    {-url ""}
    {-node_id ""}
    {-include_self:boolean}
} {
    Starting with the node at with given id, or at given url,
    climb up the site map and return the node of the first 
    non null application group

    @param url          The url of the node to start from. You must provide 
                        either url or node_id. An empty url is taken to mean 
                        the main site.
    @param node_id      The id of the node to start from. Takes precedence 
                        over any provided url.
    @param include_self If true, include the current package in the search

    @return The node of the first non-null application group in array get format.

    @author Peter Marklund, Dave Bauer
} {
    # Make sure we have a url to work with
    if { $url eq "" } {
          if { $node_id eq "" } {
              set url "/"
          } else {
              set url [site_node::get_url -node_id $node_id]
          }
    }

    set group_id ""
    while {$group_id eq "" && $url ne ""} {
        
        if { $include_self_p } {
            array set node_array [site_node::get -url $url]
            set group_id [application_group::group_id_from_package_id \
                             -package_id $node_array(package_id) \
                             -no_complain]
        }

        set include_self_p 1

        # move up a level
        set url [string trimright $url /]
        set url [string range $url 0 [string last / $url]]
    }
    if {$group_id eq ""} {
	array unset -no_complain node_array 
    }
    set node_array(application_group_id) $group_id

    return [array get node_array]
}

ad_proc -public application_group::closest_ancestor_element {
    {-node_id ""}
    {-url ""}
    {-element:required}
    {-include_self:boolean}
} {
    Return one element of the site node for the closest ancestor package that has an
    application group.

    @param url url of the node to start searching from.
    @param node_id node_id of the node to start searching from (only one of node_id and url
           can be specified).
    @param include_self If true, include the current package in the search

    @return element The desired element of the appropriate site node.
} {
    array set site_node \
        [application_group::closest_ancestor_application_group_site_node \
            -include_self=$include_self_p \
            -url $url \
            -node_id $node_id]
    return $site_node($element)
}

ad_proc -public application_group::closest_ancestor_application_group_id {
    {-url ""}
    {-node_id ""}
    {-include_self:boolean}
} {
    Application group id of the closest ancestor package that has an application
    group

    @param url url of the node to start searching from.
    @param node_id node_id of the node to start searching from (only one of node_id and url
           can be specified).
    @param include_self If true, include the current package in the search

    @return group_id of the closest ancestor package that has an application group, if any.
} {
    return [application_group::closest_ancestor_element \
               -include_self=$include_self_p \
               -url $url \
               -node_id $node_id \
               -element application_group_id]
}
    
ad_proc -public application_group::child_application_groups {
    -node_id:required
    {-package_key ""}
} {

} {
    set group_list [list]
    set child_packages [site_node::get_children -package_key $package_key -node_id $node_id -element package_id]
    foreach package_id $child_packages {
	if {[set group_id [application_group::group_id_from_package_id -package_id ${package_id} -no_complain]] ne ""} {
	    lappend group_list $group_id
	}
    }
    return $group_list
}
