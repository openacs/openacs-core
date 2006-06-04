ad_library {

    Procs which may be invoked using similarly named elements in an
    install.xml file.

    @creation-date 2004-06-16
    @author Lee Denison (lee@thaum.net)
    @cvs-id $Id$
}

namespace eval install {}
namespace eval install::xml {}
namespace eval install::xml::util {}
namespace eval install::xml::action {}
namespace eval install::xml::object_id {}

ad_proc -public install::xml::action::text { node } {
    A documentation element which ignores its contents and does no processing.
} { 
    return {}
}

ad_proc -private ::install::xml::action::source { node } {
    Source an install.xml file, sql file or tcl script during execution of 
    the current install.xml.

    If no type attribute is specified then this tag will attempt to guess 
    type of the sourced script from the file extension, otherwise it defaults 
    to install.xml.

    The type of the sourced script may be explicitly declared as 'tcl', 
    'sql' or 'install.xml' using the type attribute.

    @author Lee Denison lee@xarg.co.uk
    @creation-date 2005-02-04

} {
    set src [apm_required_attribute_value $node src]
    set type [apm_attribute_value -default {} $node type]

    if {[string equal $type ""]} {
        switch -glob $src {
            *.tcl { set type tcl }
            *.sql { set type sql }
            default { set type install.xml }
        }
    }

    set params [xml_node_get_children [lindex $node 0]]

    foreach param $params {
        if {![string equal [xml_node_get_name $param] param]} {
            error "Unknown xml element \"[xml_node_get_name $param]\""
        }

        set name [apm_required_attribute_value $param name]
        set id [apm_attribute_value -default {} $param id]
        set value [apm_attribute_value -default {} $param value]

        if {![string equal $id ""]} {
            set value [install::xml::util::get_id $id]
        }

        set parameters($name) $value
    }

    switch -exact $type {
        tcl {
            set code [template::util::read_file [acs_root_dir]$src]
            set out [eval $code]
        }
        sql {
            db_source_sql_file [acs_root_dir]$src
            set out "$src completed"
        }
        install.xml {
            set binds [array get parameters]
            set out [apm::process_install_xml -nested $src $binds]
        }
        default {
            error "Unknown script type $type"
        }
    }

    return $out 
}

ad_proc -public install::xml::action::install { node } {
    Installs a package including dependencies.

    <p>&lt;install package=&quot;<em>package-key</em> /&gt;</p>
} {
    set package_key [apm_required_attribute_value $node package]
    set package_info_path "[acs_root_dir]/packages/${package_key}/*.info"

    set install_spec_files [list]
    foreach install_spec_file [glob -nocomplain $package_info_path] {
        if { [catch { 
            array set package [apm_read_package_info_file $install_spec_file]
        } errmsg] } {
            # Unable to parse specification file.
            error "install: $install_spec_file could not be parsed correctly.  The error: $errmsg"
            return
        }

        if { [apm_package_supports_rdbms_p -package_key $package(package.key)]
             && ![apm_package_installed_p $package(package.key)] } {
            lappend install_spec_files $install_spec_file
        }
    }

    set pkg_info_list [list]
    foreach spec_file [glob -nocomplain "[acs_root_dir]/packages/*/*.info"] {
        # Get package info, and find out if this is a package we should install
        if { [catch { 
            array set package [apm_read_package_info_file $spec_file] 
        } errmsg] } {
            # Unable to parse specification file.
            error "install: $spec_file could not be parsed correctly.  The error: $errmsg"
        }

        if { [apm_package_supports_rdbms_p -package_key $package(package.key)]
             && ![apm_package_installed_p $package(package.key)] } {
            # Save the package info, we may need it for dependency 
            # satisfaction later
            lappend pkg_info_list [pkg_info_new $package(package.key) \
                $spec_file \
                $package(provides) \
                $package(requires) \
                ""]
        }
    }

    if { [llength $install_spec_files] > 0 } {
        set dependency_results [apm_dependency_check \
            -pkg_info_all $pkg_info_list \
            $install_spec_files]

        if { [lindex $dependency_results 0] == 1 } {
            apm_packages_full_install -callback apm_ns_write_callback \
                [lindex $dependency_results 1]
        } else {
            foreach package_spec [lindex $dependency_results 1] {
                if {[string is false [pkg_info_dependency_p $package_spec]]} {
                    append err_out "install: package \"[pkg_info_key $package_spec]\"[join [pkg_info_comment $package_spec] ","]\n"
                }
            }
            error $err_out
        }
    }

    return {}
}

ad_proc -public install::xml::action::mount { node } {
    Mounts a package on a specified node.

    <p>&lt;mount package=&quot;<em>package-key</em> instance-name=&quot;<em>name</em>&quot; mount-point=&quot;<em>url</em>&quot; /&gt;</p>
} { 
    set package_key [apm_required_attribute_value $node package]
    set instance_name [apm_required_attribute_value $node instance-name]
    set id [apm_attribute_value -default "" $node id]
    set mount_point [apm_attribute_value -default "" $node mount-point]
    set context_id [apm_attribute_value -default "" $node context-id]
    set security_inherit_p [apm_attribute_value -default "t" $node security-inherit-p]

    set out [list]

    # Remove double slashes
    regsub -all {//} $mount_point "/" mount_point
    set mount_point [string trimright $mount_point " /"]

    if {[string is space $mount_point] ||
        [string equal $mount_point "/"]} {
        array set site_node [site_node::get -url "/"]

        if { ![empty_string_p $site_node(object_id)] } {
            ns_log Error "A package is already mounted at \"$mount_point\""
            ns_write "<br>mount: A package is already mounted at \"$mount_point\", ignoring mount command."
            set node_id ""
        }

        if {[string equal $context_id ""]} {
            set context_id default_context
        }

        set context_id [install::xml::util::get_id $context_id]
    } else {
        regexp {(.*)/([^/]*)$} $mount_point match parent_url mount_point

        if {[string eq $parent_url ""]} { 
            set parent_url /
        }

        set parent_id [site_node::get_node_id -url $parent_url]

        if { [catch {
            db_transaction {
                set node_id [site_node::new -name $mount_point \
                    -parent_id $parent_id]
            }
        } error] } {
            # There is already a node with that path, check if there is a 
            # package mounted there
            array set site_node [site_node::get -url "/$mount_point"]
            if { [empty_string_p $site_node(object_id)] } {
                # There is no package mounted there so go ahead and mount the 
                # new package
                set node_id $site_node(node_id)
            } else {
                ns_log Error "A package is already mounted at \"$mount_point\""
                ns_write "<br>mount: A package is already mounted at \"$mount_point\", ignoring mount command."
                set node_id ""
            }
        }

        if {![string equal $context_id ""]} {
            set context_id [install::xml::util::get_id $context_id]
        }
    }

    if { ![empty_string_p $node_id] } {
        lappend out "Mounting new instance of package $package_key at /$mount_point"
        set package_id [site_node::instantiate_and_mount \
            -node_id $node_id \
            -context_id $context_id \
            -node_name $mount_point \
            -package_name $instance_name \
            -package_key $package_key]

        if {![template::util::is_true $security_inherit_p]} {
            permission::set_not_inherit -object_id $package_id
        }

        if {![string equal $id ""]} {
            set ::install::xml::ids($id) $package_id
        }
    }

    return $out
}

ad_proc -public install::xml::action::mount-existing { node } {
    Mounts an existing package on a specified node.

    <p>&lt;mount-existing package-id=&quot;<em>package-id</em> mount-point=&quot;<em>url</em>&quot; /&gt;</p>
} { 
    set package_id [apm_attribute_value -default "" $node package-id]
    set package_key [apm_attribute_value -default "" $node package-key]
    set mount_point [apm_attribute_value -default "" $node mount-point]

    set out [list]

    # Remove double slashes
    regsub -all {//} $mount_point "/" mount_point

    if {[string is space $mount_point] ||
        [string equal $mount_point "/"]} {
        array set site_node [site_node::get -url "/"]

        if { ![empty_string_p $site_node(object_id)] } {
            ns_log Error "A package is already mounted at \"$mount_point\""
            ns_write "<br>mount: A package is already mounted at \"$mount_point\", ignoring mount command."
            set node_id ""
        }
    } else {
        regexp {(.*)/([^/]*)$} $mount_point match parent_url mount_point

        if {[string eq $parent_url ""]} { 
            set parent_url /
        }

        set parent_id [site_node::get_node_id -url $parent_url]

        if { [catch {
            db_transaction {
                set node_id [site_node::new -name $mount_point \
                    -parent_id $parent_id]
            }
        } error] } {
            # There is already a node with that path, check if there is a 
            # package mounted there
            array set site_node [site_node::get -url "/$mount_point"]
            if { [empty_string_p $site_node(object_id)] } {
                # There is no package mounted there so go ahead and mount the 
                # new package
                set node_id $site_node(node_id)
            } else {
                ns_log Error "A package is already mounted at \"$mount_point\""
                ns_write "<br>mount: A package is already mounted at \"$mount_point\", ignoring mount command."
                set node_id ""
            }
        }
    }

    if { ![empty_string_p $node_id] } {
        lappend out "Mounting existing package $package_id at /$mount_point"

        if { ![string equal $package_id ""] } {
            set package_id [install::xml::util::get_id $package_id]
        } elseif { ![string equal $package_key ""] } {
            set package_id [apm_package_id_from_key $package_key]
        } 

        set package_id [site_node::mount \
            -node_id $node_id \
            -object_id $package_id]
    }

    return $out
}

ad_proc -public install::xml::action::create-package { node } {
    Create a relation type.
} {
    variable ::install::xml::ids

    set id [apm_required_attribute_value $node id]
    set package_key [apm_required_attribute_value $node package-key]
    set instance_name [apm_attribute_value -default "" $node name]
    set context_id [apm_attribute_value -default "" $node context-id]

    if {[string equal $context_id ""]} {
        set context_id [db_null]
    } else {
        set context_id [install::xml::util::get_id $context_id]
    }

    set package_id [apm_package_instance_new \
        -instance_name $instance_name \
        -package_key $package_key \
        -context_id $context_id]

    if {![string is space $id]} {
        set ::install::xml::ids($id) $package_id
    }

    return $package_id
}

ad_proc -public install::xml::action::set-parameter { node } {
    Sets a package parameter.

    <p>&lt;set-parameter name=&quot;<em>parameter</em>&quot; [ package=&quot;<em>package-key</em> | url=&quot;<em>package-url</em>&quot; ] type=&quot;<em>[id|literal]</em>&quot; value=&quot;<em>value</em>&quot; /&gt;</p>
} { 
    variable ::install::xml::ids

    set name [apm_required_attribute_value $node name]
    set value [apm_attribute_value -default {} $node value]

    set package_id [install::xml::object_id::package $node]

    set type [apm_attribute_value -default "literal" $node type]

    switch -- $type {
      literal {
        parameter::set_value -package_id $package_id \
            -parameter $name \
            -value $value

      }
      id {
        parameter::set_value -package_id $package_id \
            -parameter $name \
            -value $ids($value)
      }
    }
}

ad_proc -public install::xml::action::set-parameter-default { node } {
    Sets a package parameter default value

    <code>&lt;set-parameter-default name=&quot;<em>parameter</em>&quot; package-key=&quot;<em>package-key</em>&quot; value=&quot;val&quot;&gt;</code>
} {
    set name [apm_required_attribute_value $node name]
    set package_key [apm_required_attribute_value $node package-key]
    set value [apm_attribute_value -default {} $node value]

    parameter::set_default \
        -package_key $package_key \
        -parameter $name \
        -value $value

    return ""

}

ad_proc -public install::xml::action::set-permission { node } {
    Sets permissions on an object.

    <p>&lt;set-permissions grantee=&quot;<em>party</em>&quot; privilege=&quot;<em>package-key</em> /&gt;</p>
} { 
    set privileges [apm_required_attribute_value $node privilege]

    set privilege_list [split $privileges ","]

    set grantees_node [xml_node_get_children_by_name [lindex $node 0] grantee]
    set grantees [xml_node_get_children [lindex $grantees_node 0]]

    foreach grantee $grantees {
        set party_id [apm_invoke_install_proc -type object_id -node $grantee]
         
        set objects_node [xml_node_get_children_by_name [lindex $node 0] object]
        set objects [xml_node_get_children [lindex $objects_node 0]]

        foreach object $objects {
            set object_id [apm_invoke_install_proc -type object_id \
                -node $object]

            foreach privilege $privilege_list {
                permission::grant -object_id $object_id \
                    -party_id $party_id \
                    -privilege $privilege
            }
        }
    }
}

ad_proc -public install::xml::action::unset-permission { node } {
    Revokes a permissions on an object - has no effect if the permission is not granted directly (ie does not act as negative permissions).

    <p>&lt;unset-permissions grantee=&quot;<em>party</em>&quot; privilege=&quot;<em>package-key</em> /&gt;</p>
} { 
    set privileges [apm_required_attribute_value $node privilege]

    set privilege_list [split $privileges ","]

    set grantees_node [xml_node_get_children_by_name [lindex $node 0] grantee]
    set grantees [xml_node_get_children [lindex $grantees_node 0]]

    foreach grantee $grantees {
        set party_id [apm_invoke_install_proc -type object_id -node $grantee]
         
        set objects_node [xml_node_get_children_by_name [lindex $node 0] object]
        set objects [xml_node_get_children [lindex $objects_node 0]]

        foreach object $objects {
            set object_id [apm_invoke_install_proc -type object_id \
                -node $object]

            foreach privilege $privilege_list {
                permission::revoke -object_id $object_id \
                    -party_id $party_id \
                    -privilege $privilege
            }
        }
    }
}

ad_proc -public install::xml::action::set-join-policy { node } {
    Set the join policy of a group.
} {
    set join_policy [apm_required_attribute_value $node join-policy]

    set objects [xml_node_get_children [lindex $node 0]]

    foreach object $objects {
        set group_id [apm_invoke_install_proc -type object_id -node $object]

        group::get -group_id $group_id -array group
        set group(join_policy) $join_policy
        group::update -group_id $group_id -array group
    }
}

ad_proc -public install::xml::action::create-user { node } {
    Create a new user.

    local-p should be set to true when this action is used in
    the bootstrap install.xml - this ensures we call the 
    auth::local api directly while the service contract has not
    been setup.
} {
    set email [apm_required_attribute_value $node email]
    set first_names [apm_required_attribute_value $node first-names]
    set last_name [apm_required_attribute_value $node last-name]
    set password [apm_required_attribute_value $node password]
    set username [apm_attribute_value -default "" $node username]
    set screen_name [apm_attribute_value -default "" $node screen-name]
    set url [apm_attribute_value -default "" $node url]
    set secret_question [apm_attribute_value -default "" $node secret-question]
    set secret_answer [apm_attribute_value -default "" $node secret-answer]
    set id [apm_attribute_value -default "" $node id]
    set local_p [apm_attribute_value -default 0 $node local-p]

    set local_p [template::util::is_true $local_p]

    if {$local_p} {
        foreach elm [auth::get_all_registration_elements] {
            if { [info exists $elm] } {
                set user_info($elm) [set $elm]
            }
        }

        set user_info(email_verified_p) 1

        array set result [auth::create_local_account \
            -authority_id [auth::authority::local] \
            -username $username \
            -array user_info]

        if {[string equal $result(creation_status) "ok"]} {
            # Need to find out which username was set
            set username $result(username)

            array set result [auth::local::registration::Register \
                {} \
                $username \
                [auth::authority::local] \
                $first_names \
                $last_name \
                $screen_name \
                $email \
                $url \
                $password \
                $secret_question \
                $secret_answer]
        }
    } else {
        array set result [auth::create_user -email $email \
            -first_names $first_names \
            -last_name $last_name \
            -password $password \
            -username $username \
            -screen_name $screen_name \
            -url $url \
            -secret_question $secret_question \
            -secret_answer $secret_answer \
            -email_verified_p 1 \
            -nologin \
            ]
    }

    if {[string equal $result(creation_status) "ok"]} {
        if {![string equal $id ""]} {
            set ::install::xml::ids($id) $result(user_id)
        }

        return [list $result(creation_message)]
    } else {
        ns_log error "create-user: $result(creation_status): $result(creation_message)"
    }
}

ad_proc -public install::xml::action::add-subsite-member { node } {
    Add a member to a subsites application group.
} {
    set member_state [apm_attribute_value -default "" $node member-state]

    set group_id [::install::xml::object_id::application-group $node]

    set user_nodes [xml_node_get_children [lindex $node 0]]

    foreach node $user_nodes {
        if {![string equal [xml_node_get_name $node] user]} {
            error "Unknown xml element \"[xml_node_get_name $node]\""
        }

        set user_id [::install::xml::object_id::object $node]

        group::add_member -user_id $user_id \
            -group_id $group_id \
            -member_state $member_state
    }

    return {}
}

ad_proc -public install::xml::action::relation-type { node } {
    Create a relation type.
} {
    set rel_type [apm_required_attribute_value $node rel-type]
    set pretty_name [apm_required_attribute_value $node pretty-name]
    set pretty_plural [apm_required_attribute_value $node pretty-plural]
    set object_type_one [apm_required_attribute_value $node object-type-one]
    set min_n_rels_one [apm_required_attribute_value $node min-n-rels-one]
    set max_n_rels_one [apm_attribute_value -default "" $node max-n-rels-one]
    set object_type_two [apm_required_attribute_value $node object-type-two]
    set min_n_rels_two [apm_required_attribute_value $node min-n-rels-two]
    set max_n_rels_two [apm_attribute_value -default "" $node max-n-rels-two]

    rel_types::new $rel_type \
        $pretty_name \
        $pretty_plural \
        $object_type_one \
        $min_n_rels_one \
        $max_n_rels_one \
        $object_type_two \
        $min_n_rels_two \
        $max_n_rels_two

    return {}
}

ad_proc -public install::xml::object_id::package { node } {
    Returns an object_id for a package specified in node.

    The node name is ignored so any node which provides the correct 
    attributes may be used.

    <p>&lt;package [ id=&quot;<em>id</em>&quot; | key=&quot;<em>package-key</em>&quot; | url=&quot;<em>package-url</em>&quot; ] /&gt;</p>
} {
    set id [apm_attribute_value -default "" $node package-id]
    set url [apm_attribute_value -default "" $node url]

    set package_key [apm_attribute_value -default "" $node package-key]
    if {[string equal $package_key ""]} {
        set package_key [apm_attribute_value -default "" $node package]
    }

    # Remove double slashes
    regsub -all {//} $url "/" url

    if { ![string equal $package_key ""] && ![string equal $url ""] } {
        error "set-parameter: Can't specify both package and url for $url and $package_key"

    } elseif { ![string equal $id ""] } {
        if {[string is integer $id]} {
            return $id
        } else {
            return [install::xml::util::get_id $id]
        }
    } elseif { ![string equal $package_key ""] } {
        return [apm_package_id_from_key $package_key]

    } else {
        return [site_node::get_object_id \
            -node_id [site_node::get_node_id -url $url]]
    }
}

ad_proc -public install::xml::object_id::group { node } {
    Returns an object_id for a group or relational segment.

    The node name is ignored so any node which provides the correct 
    attributes may be used.

    <p>&lt;group id=&quot;<em>group_id</em>&quot; [ type=&quot;<em>group type</em>&quot; relation=&quot;<em>relation-type</em>&quot; ] /&gt;</p>
} {
    set group_type [apm_attribute_value -default "group" $node type]
    set relation_type [apm_attribute_value -default "membership_rel" $node relation]
    
    if {[string equal $group_type "group"]} {
        set id [apm_required_attribute_value $node group-id]
    } elseif {[string equal $group_type "rel_segment"]} {
        set id [apm_required_attribute_value $node parent-id]
    }

    set group_id [install::xml::util::get_id $id]

    if {[string equal $group_type "group"]} {
        return $group_id
    } elseif {[string equal $group_type "rel_segment"]} {
        return [group::get_rel_segment -group_id $group_id -type $relation_type]
    }
}

ad_proc -public install::xml::object_id::application-group { node } {
    Returns an object_id for an application group or relational segment of
    a given package.

    The node name is ignored so any node which provides the correct 
    attributes may be used.

} {
    set group_type [apm_attribute_value -default "group" $node type]
    set relation_type [apm_attribute_value -default "membership_rel" $node relation]

    set package_id [::install::xml::object_id::package $node]

    set group_id [application_group::group_id_from_package_id \
        -package_id $package_id] 

    if {[string equal $group_type "group"]} {
        return $group_id
    } elseif {[string equal $group_type "rel_segment"]} {
        return [group::get_rel_segment -group_id $group_id -type $relation_type]
    }
}

ad_proc -public install::xml::object_id::object { node } {
    Returns a literal object_id for an object.
    
    use &lt;object id="-100"&gt; to return the literal id -100.
} {
    set id [apm_required_attribute_value $node id]

    if {[string is integer $id]} {
        return $id
    } else {
        return [install::xml::util::get_id $id]
    }
}

ad_proc -public install::xml::util::get_id { id } {
    Returns an id from the global ids variable if it exists and attempts to
    find an acs_magic_object if not.
} {
    variable ::install::xml::ids

    if {[catch {
        if {[info exists ids($id)]} {
            set result $ids($id)
        } else {
            set result [acs_magic_object $id]
        }
    } err]} {
        error "$id is not defined in this install.xml and is not an acs_magic_object"
    }
    
    return $result
}
