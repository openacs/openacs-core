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

    if {[empty_string_p $package_id] && [ad_conn isconnected]} {
        set package_id [ad_conn package_id]
    }

    if {[empty_string_p $package_id]} {
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

    if {[empty_string_p $package_id] && [ad_conn isconnected]} {
        set package_id [ad_conn package_id]
    }

    if {[empty_string_p $package_id]} {
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

    if {[empty_string_p $package_id] && [ad_conn isconnected]} {
        set package_id [ad_conn package_id]
    }

    if {[empty_string_p $package_id]} {
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
        if {[empty_string_p $package_id]} {
    	set package_id [ad_conn package_id]
        }
    }

    if {[empty_string_p $package_id]} {
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
        if { [empty_string_p $creation_user] } {
    	set creation_user [ad_conn user_id]
        }
        if { [empty_string_p $creation_ip] } {
    	set creation_ip [ad_conn peeraddr]
        }
        if { [empty_string_p $package_id] } {
    	set package_id [ad_conn package_id]
        }
    }

    if {[empty_string_p $package_id]} {
        error "application_group::new - package_id not specified"
    }

    if {[empty_string_p $group_name]} {
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

}

