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
    Source an install.xml file, sql file or Tcl script during execution of 
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

    if {$type eq ""} {
        switch -glob $src {
            *.tcl { set type tcl }
            *.sql { set type sql }
            default { set type install.xml }
        }
    }

    set params [xml_node_get_children [lindex $node 0]]

    foreach param $params {
        if {[xml_node_get_name $param] ne "param"} {
            error "Unknown xml element \"[xml_node_get_name $param]\""
        }

        set name [apm_required_attribute_value $param name]
        set id [apm_attribute_value -default {} $param id]
        set value [apm_attribute_value -default {} $param value]

        if {$id ne ""} {
            set value [install::xml::util::get_id $id]
        }

        set parameters($name) $value
    }

    switch -exact $type {
        tcl {
            set code [template::util::read_file $::acs::rootdir$src]
            set out [eval $code]
        }
        sql {
            db_source_sql_file $::acs::rootdir$src
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

    apm_simple_package_install $package_key

    return
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
    set mount_point [string trim $mount_point " /"]

    if {[string is space $mount_point] || $mount_point eq "/"} {
        array set site_node [site_node::get -url "/"]

        if {$site_node(object_id) ne ""} {
            ns_log Error "A package is already mounted at '$mount_point', ignoring mount command"
            lappend out "A package is already mounted at '$mount_point', ignoring mount command"
            set node_id ""
        }

        if {$context_id eq ""} {
            set context_id default_context
        }

        set context_id [install::xml::util::get_id $context_id]
    } else {
        set leaf_url $mount_point
        set parent_url ""
        regexp {(.*)/([^/]*)$} $mount_point match parent_url leaf_url

        set parent_id [site_node::get_node_id -url "/$parent_url"]

        # technically this isn't safe - between us checking that the node exists
        # and using it, the node may have been deleted. 
        # We could "select for update" but since it's in a memory cache anyway,
        # it won't help us very much!
        # Instead we just press on and if there's an error handle it at the top level.
       
        # create the node and reget iff it doesn't exist
        if { [catch { array set site_node [site_node::get_from_url -exact -url "/$mount_point"] } error] } {
            set node_id [site_node::new -name $leaf_url -parent_id $parent_id]
            array set site_node [site_node::get_from_url -exact -url "/$mount_point"]
        }

        # There now definitely a node with that path
        if {$site_node(object_id) eq ""} {
            # no package mounted - good!
            set node_id $site_node(node_id)
        } else {
            ns_log Error "A package is already mounted at '$mount_point', ignoring mount command"
            lappend out "A package is already mounted at '$mount_point', ignoring mount command"
            set node_id ""
        }

        if {$context_id eq ""} {
            set context_id [install::xml::util::get_id $context_id]
        }
    }

    if {$node_id ne ""} {
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

        if {$id ne ""} {
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
    set mount_point [string trim $mount_point " /"]

    if {[string is space $mount_point] || $mount_point eq "/"} {
        array set site_node [site_node::get -url "/"]

        if {$site_node(object_id) ne ""} {
            ns_log Error "A package is already mounted at '$mount_point', ignoring mount command"
            lappend out "A package is already mounted at '$mount_point', ignoring mount command"
            set node_id ""
        }
    } else {
        set leaf_url $mount_point
        set parent_url ""
        regexp {(.*)/([^/]*)$} $mount_point match parent_url leaf_url

        set parent_id [site_node::get_node_id -url "/$parent_url"]

        # technically this isn't safe - between us checking that the node exists
        # and using it, the node may have been deleted. 
        # We could "select for update" but since it's in a memory cache anyway,
        # it won't help us very much!
        # Instead we just press on and if there's an error handle it at the top level.
        
        # create the node and reget iff it doesn't exist
        if { [catch { array set site_node [site_node::get_from_url -exact -url "/$mount_point"] } error] } {
            set node_id [site_node::new -name $leaf_url -parent_id $parent_id]
            array set site_node [site_node::get_from_url -exact -url "/$mount_point"]
        }
    
        # There now definitely a node with that path
        if {$site_node(object_id) eq ""} {
            # no package mounted - good!
            set node_id $site_node(node_id)
        } else {
            ns_log Error "A package is already mounted at '$mount_point', ignoring mount command"
            lappend out "A package is already mounted at '$mount_point', ignoring mount command"
            set node_id ""
        }
    }

    if {$node_id ne ""} {
        lappend out "Mounting existing package $package_id at /$mount_point"

        if {$package_id ne ""} {
            set package_id [install::xml::util::get_id $package_id]
        } elseif {$package_key ne ""} {
            set package_id [apm_package_id_from_key $package_key]
        } 

        set package_id [site_node::mount \
            -node_id $node_id \
            -object_id $package_id]
    }

    return $out
}

ad_proc -public install::xml::action::rename-instance { node } {
    Change the instance name of an existing package (such as the main subsite).  Either
    the url (if it's mounted) or package_id of the package may be given.

    <p>&lt;rename-instance package-id=&quot;<em>package-id</em>&quot; url=&quot;<em>url</em>&quot; instance-name=&quot;<em>new instance name</em>&quot; /&gt;</p>

} { 
    set package_id [apm_attribute_value -default "" $node package-id]
    set url [apm_attribute_value -default "" $node url]
    set instance_name [apm_required_attribute_value $node instance-name]

    if { $url ne "" && $package_id ne "" } {
        error "rename-instance specified with both url and package-id arguments"
    } elseif { $package_id ne "" } {
        set package_id [install::xml::util::get_id $package_id]
        set url [lindex [site_node::get_url_from_object_id -object_id $package_id] 0]
    } else {
        array set site_node [site_node::get_from_url -url $url -exact]
        set package_id $site_node(object_id)
    }

    apm_package_rename -package_id $package_id -instance_name $instance_name

    return [list "Package mounted at \"$url\" renamed to \"$instance_name\""]

}

ad_proc -public install::xml::action::create-package { node } {
    Create a relation type.
} {
    variable ::install::xml::ids
    set package_key [apm_required_attribute_value $node package-key]
    set instance_name [apm_attribute_value -default "" $node name]
    set context_id [apm_attribute_value -default "" $node context-id]
    set security_inherit_p [apm_attribute_value -default "t" $node security-inherit-p]

    if {$context_id eq ""} {
        set context_id [db_null]
    } else {
        set context_id [install::xml::util::get_id $context_id]
    }

    set package_id [apm_package_instance_new \
        -instance_name $instance_name \
        -package_key $package_key \
        -context_id $context_id]

    if {![template::util::is_true $security_inherit_p]} {
         permission::set_not_inherit -object_id $package_id
    }

    if {![string is space $id]} {
        set ::install::xml::ids($id) $package_id
    }

    return
}

ad_proc -public install::xml::action::register-parameter { node } {
    Registers a package parameter.

    <p>&lt;register-parameter name=&quot;<em>parameter</em>&quot; description=&quot;<em>description</em>&quot; package-key=&quot;<em>package-key</em>&quot; scope=&quot;<em>instance or global</em>&quot; default-value=&quot;<em>default-value</em>&quot; datatype=&quot;<em>datatype</em>&quot; [ [ [ section=&quot;<em>section</em>&quot; ] min-n-values=&quot;<em>min-n-values</em>&quot; ] max-n-values=&quot;<em>max-n-values</em>&quot; ] [ callback=&quot;<em>callback</em>&quot; ] [ parameter-id=&quot;<em>parameter-id</em>&quot; ]</p>
} { 
    set name [apm_required_attribute_value $node name]
    set desc [apm_required_attribute_value $node description]
    set package_key [apm_required_attribute_value $node package-key]
    set default_value [apm_required_attribute_value $node default-value]
    set scope [apm_attribute_value -default instance $node scope]
    set datatype [apm_required_attribute_value $node datatype]
    set min_n_values [apm_attribute_value -default {} $node min-n-values]
    set max_n_values [apm_attribute_value -default {} $node max-n-values]
    set section [apm_attribute_value -default {} $node section]
    set callback [apm_attribute_value -default {} $node callback]
    set parameter_id [apm_attribute_value -default {} $node parameter-id]

    set command "apm_parameter_register"

    if {$callback ne ""} {
        append command " -callback $callback"
    }

    if {$parameter_id ne ""} {
        append command " -parameter_id $parameter_id"
    }

    append command " -scope $scope $name \"$desc\" $package_key $default_value $datatype"

    if {$section ne ""} {
        append command " $section"

        if {$min_n_values ne ""} {
            append command " $min_n_values"

            if {$max_n_values ne ""} {
                append command " $max_n_values"
            }
        }
    }

    {*}$command
    return
}

ad_proc -public install::xml::action::set-parameter { node } {
    Sets a package parameter.

    <p>&lt;set-parameter name=&quot;<em>parameter</em>&quot; [ package=&quot;<em>package-key</em> | url=&quot;<em>package-url</em>&quot; ] type=&quot;<em>[id|literal]</em>&quot; value=&quot;<em>value</em>&quot; /&gt;</p>
} { 
    variable ::install::xml::ids

    set name [apm_required_attribute_value $node name]
    set type [apm_attribute_value -default "literal" $node type]
    set value [apm_attribute_value -default {} $node value]

    set package_ids [install::xml::object_id::package $node]

    foreach package_id $package_ids {
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
    return
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
    return
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
    return
}

ad_proc -public install::xml::action::unset-permission { node } {
    Revokes a permissions on an object - has no effect if the permission is not granted directly 
    (ie does not act as negative permissions).

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
    return
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
    return
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
    set salt [apm_attribute_value -default "" $node salt]
    set username [apm_attribute_value -default "" $node username]
    set screen_name [apm_attribute_value -default "" $node screen-name]
    set url [apm_attribute_value -default "" $node url]
    set secret_question [apm_attribute_value -default "" $node secret-question]
    set secret_answer [apm_attribute_value -default "" $node secret-answer]
    set id [apm_attribute_value -default "" $node id]
    set site_wide_admin_p [apm_attribute_value -default "" $node site-wide-admin]
    set local_p [apm_attribute_value -default 0 $node local-p]

    set local_p [template::util::is_true $local_p]

    if {$salt ne ""} {
      set salt_password $password
      set password dummy
    }

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

        if {$result(creation_status) eq "ok"} {
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

    if {$result(creation_status) eq "ok"} {
        if {[template::util::is_true $site_wide_admin_p]} {
            permission::grant -object_id [acs_magic_object "security_context_root"] \
                              -party_id $result(user_id) -privilege "admin"
        }

        if {$salt ne ""} {
            set user_id $result(user_id)

            db_dml set_real_passsword {
                UPDATE users
                   SET salt = :salt,
                       password = :salt_password
                 WHERE user_id = :user_id
            }
        }
              
        if {$id ne ""} {
            set ::install::xml::ids($id) $result(user_id)
        }

        return [list $result(creation_message)]
    } else {
        ns_log error "create-user: $result(creation_status): $result(creation_message)"
        return
    }
}

ad_proc -public install::xml::action::add-subsite-member { node } {
    Add a member to a subsites application group.
} {
    set member_state [apm_attribute_value -default "" $node member-state]

    set group_id [::install::xml::object_id::application-group $node]

    set user_nodes [xml_node_get_children [lindex $node 0]]

    foreach node $user_nodes {
        if {[xml_node_get_name $node] ne "user"} {
            error "Unknown xml element \"[xml_node_get_name $node]\""
        }

        set user_id [::install::xml::object_id::object $node]

        group::add_member -user_id $user_id \
            -group_id $group_id \
            -member_state $member_state \
            -no_perm_check
    }

    return
}

ad_proc -public install::xml::action::add-subsite-admin { node } {
    Add a member to a subsite's admins group.
} {
    set member_state [apm_attribute_value -default "" $node member-state]

    # group id is registered using the package id
    set package_id [install::xml::object_id::package $node]
    set group_id [subsite::get_admin_group -package_id $package_id]

    set user_nodes [xml_node_get_children [lindex $node 0]]

    foreach node $user_nodes {
        if {[xml_node_get_name $node] ne "user"} {
            error "Unknown xml element \"[xml_node_get_name $node]\""
        }

        set user_id [::install::xml::object_id::object $node]

        group::add_member -user_id $user_id \
            -group_id $group_id \
            -member_state $member_state \
            -no_perm_check
    }

    return
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

    return
}

ad_proc -public install::xml::action::relation-add { node } {
    Create a relation.
} {
    set rel_type [apm_required_attribute_value $node rel-type]
    set object_one [apm_required_attribute_value $node object-one]
    set object_two [apm_required_attribute_value $node object-two]

    relation_add $rel_type $object_one $object_two

    return
}

ad_proc -public install::xml::action::ats-page { node } {
    Creates an ATS Page.
} {
    set id [apm_attribute_value -default "" $node id]
    set package [apm_attribute_value -default "" $node package]
    set context [apm_attribute_value -default "" $node context]
    set path [apm_attribute_value $node path]

    if {$context ne ""} {
        set context [install::xml::util::get_id $context]
    }

    if {$package ne ""} {
        set package [install::xml::util::get_id $package]
    }

    set extension "*"
    regexp {(.*)\.(.*)} $path match path extension

    set result [db_string get_type_select {
                              select page_id
                                from ats_pages
                              where path = :path} -default ""]
    if {$result eq ""} {
        set result [location::ats::create_template -path $path \
            -extension $extension \
            -package_id $package \
            -context_id $context]
    } 

    if {$id ne ""} {
        set ::install::xml::ids($id) $result
    }
    return
}

ad_proc -public install::xml::action::location { node } {
    Creates a URL location object.
} {
    set id [apm_attribute_value -default "" $node id]
    set parent [apm_attribute_value -default "" $node parent]
    set name [apm_attribute_value -default "" $node name]
    set package [apm_attribute_value -default "" $node package]
    set context [apm_attribute_value -default "" $node context]
    set model [apm_attribute_value -default "" $node model]
    set view [apm_attribute_value -default "" $node view]
    set controller [apm_attribute_value -default "" $node controller]
    set path_arg [apm_attribute_value -default "" $node path-arg]
    set child_arg [apm_attribute_value -default "" $node child-arg]
    set directory_p [apm_attribute_value -default "t" $node directory-p]
    set title [apm_attribute_value -default "" $node title]

    if {$parent ne ""} {
        set parent [install::xml::util::get_id $parent]
    }

    if {$context ne ""} {
        set context [install::xml::util::get_id $context]
    }

    if {$package ne ""} {
        set package [install::xml::util::get_id $package]
    }

    if {$model ne ""} {
        set model [install::xml::util::get_id $model]
    }

    if {$view ne ""} {
        set view [install::xml::util::get_id $view]
    }

    set directory_p [template::util::is_true $directory_p]

    set location_id [location::create -parent_id $parent \
        -name $name \
        -title $title \
        -model_id $model \
        -view_id $view \
        -controller $controller \
        -path_arg $path_arg \
        -package_id $package \
        -context_id $context \
        -directory_p $directory_p]

    set children [xml_node_get_children [lindex $node 0]]

    foreach child $children {
        switch -exact -- [xml_node_get_name $child] {
            param {
                set name [apm_required_attribute_value $child name]
                set value [apm_attribute_value -default "" $child value]
                set type [apm_attribute_value -default literal $child type]
                set subtree_p [apm_attribute_value -default f $child subtree-p]
                
                set subtree_p [template::util::is_true $subtree_p]

                if {$type eq "id"} {
                    set value [install::xml::util::get_id $value]
                }

                location::parameter::create -location_id $location_id \
                    -name $name \
                    -value $value \
                    -subtree_p $subtree_p
            }
            forward {
                set name [apm_required_attribute_value $child name]
                set url [apm_required_attribute_value $child url]
                set exports [apm_attribute_value -default "" $child exports]
                set subtree_p [apm_attribute_value -default f $child subtree-p]
                
                set subtree_p [template::util::is_true $subtree_p]

                location::parameter::create -location_id $location_id \
                    -name "forward::$name" \
                    -value $url \
                    -subtree_p $subtree_p

                if {$exports ne ""} {
                    location::parameter::create -location_id $location_id \
                        -name "forward::${name}::exports" \
                        -value $exports \
                        -subtree_p $subtree_p
                }
            }
            location {
                xml_node_set_attribute $child parent $location_id

                if {$child_arg ne ""} {
                    xml_node_set_attribute $child path-arg $child_arg
                }

                if {$package ne "" 
                    && ![xml_node_has_attribute $child package-id]} {
                    xml_node_set_attribute $child package-id $package
                }

                if {$context ne "" 
                    && ![xml_node_has_attribute $child context-id]} {
                    xml_node_set_attribute $child context-id $parent_id
                }

                apm_invoke_install_proc -node $child
            }
            default {
                error "Unknown xml element \"[xml_node_get_name $child]\""
            }
        }
    }

    if {$id ne ""} {
        set ::install::xml::ids($id) $location_id
    }

    return $location_id
}

ad_proc -public install::xml::action::wizard { node } {
    Creates a wizard using the subtags for each step.
} {
    set id [apm_attribute_value -default "" $node id]
    set name [apm_attribute_value -default "" $node name]
    set package [apm_attribute_value -default "" $node package]
    set context [apm_attribute_value -default "" $node context]
    set title [apm_attribute_value -default "" $node title]
    set child_arg [apm_attribute_value -default "" $node child-arg]
    set process [apm_attribute_value -default "" $node process]
    
    if {$context ne ""} {
        set context [install::xml::util::get_id $context]
    }

    if {$package ne ""} {
        set package [install::xml::util::get_id $package]
    }

    set parent_id [location::create -parent_id "" \
        -name $name \
        -title $title \
        -model_id "" \
        -view_id "" \
        -controller "" \
        -path_arg "" \
        -package_id $package \
        -context_id $context]
    
    if {$process ne ""} {
        location::parameter::create -location_id $parent_id \
            -name "wizard::process" \
            -subtree_p t \
            -value $process
    }
    
    set steps [xml_node_get_children [lindex $node 0]]

    foreach step $steps {
        if {[xml_node_get_name $step] ne "step"} {
            error "Unknown xml element \"[xml_node_get_name $step]\""
        }

        set step_export [apm_attribute_value -default "" $step exports]
        set step_export_proc [apm_attribute_value -default "" $step exports-proc]

        xml_node_set_attribute $step parent $parent_id

        if {$child_arg ne ""} {
            xml_node_set_attribute $step path-arg $child_arg
        }

        if {$package ne "" 
            && ![xml_node_has_attribute $step package-id]} {
            xml_node_set_attribute $step package-id $package
        }

        if {$context ne "" 
            && ![xml_node_has_attribute $step context-id]} {
            xml_node_set_attribute $step context-id $parent_id
        }

        set directory_p [apm_attribute_value -default f $step directory-p]
        xml_node_set_attribute $step directory-p \
            [template::util::is_true $directory_p]

        set step_id [::install::xml::action::location $step]

        if {$step_export ne ""} {
            location::parameter::create -location_id $step_id \
                -name "wizard::exports" \
                -subtree_p t \
                -value $step_export
        }

        if {$step_export_proc ne ""} {
            location::parameter::create -location_id $step_id \
                -name "wizard::exports::proc" \
                -subtree_p t \
                -value $step_export_proc
        }
    }

    if {$id ne ""} {
        set ::install::xml::ids($id) $parent_id
    }

    return $parent_id
}

ad_proc -private ::install::xml::action::call-tcl-proc { node } {

    Call an arbitrary Tcl library procedure.

    Parameters which have a name are called using the "-param" syntax. If there's
    no name given, the value is passed directly as a positional parameter.  It is the
    user's responsibility to list all named parameters before any positional parameter
    (as is necessary if the proc is declared using ad_proc).

    If a named parameter has an XML attribute declaring its type to be boolean, and the
    value is blank, the switch is passed without a value.  Otherwise, the boolparam=value
    syntax is used.

    You can cheat and use this to execute arbitrary Tcl code if you dare, since Tcl
    commands are just procs ...

    @author Don Baccus donb@pacifier.com
    @creation-date 2008-12-04

} {
    set cmd [list [apm_required_attribute_value $node name]]

    set params [xml_node_get_children [lindex $node 0]]
    foreach param $params {
        if {[xml_node_get_name $param] ne "param"} {
            error "Unknown xml element \"[xml_node_get_name $param]\""
        }

        set name [apm_attribute_value -default {} $param name]
        set id [apm_attribute_value -default {} $param id]
        set value [apm_attribute_value -default {} $param value]
        set type [apm_attribute_value -default {} $param type]

        if {$id ne ""} {
            set value [install::xml::util::get_id $id]
        }

        if { $name ne "" && $type eq "boolean" } {
            if { $value ne "" } {
                lappend cmd -${name}=$value
            } else {
                lappend cmd -$name
            }
        } else {
            if { $name ne "" } {
                lappend cmd -$name
            }
            lappend cmd $value
        }
    }

    set result [{*}$cmd]
    set id [apm_attribute_value -default "" $node id]
    if {$id ne ""} {
        set ::install::xml::ids($id) $result
    }
    return
}


ad_proc -private ::install::xml::action::instantiate-object { node } {

    Instantiate an object using package_instantiate_object.  This will work
    for both PostgreSQL and Oracle if the proper object package and new()
    function have been defined.
    
    @author Don Baccus donb@pacifier.com
    @creation-date 2008-12-04

} {
    set type [apm_required_attribute_value $node type]

    set params [xml_node_get_children [lindex $node 0]]
    set var_list {}
    foreach param $params {
        if {[xml_node_get_name $param] ne "param"} {
            error "Unknown xml element \"[xml_node_get_name $param]\""
        }

        set name [apm_required_attribute_value $param name]
        set id [apm_attribute_value -default {} $param id]
        set value [apm_attribute_value -default {} $param value]

        if {$id ne ""} {
            set value [install::xml::util::get_id $id]
        }

        lappend var_list [list $name $value]
    }

    set object_id [package_instantiate_object -var_list $var_list $type]

    set id [apm_attribute_value -default "" $node id]
    if {$id ne ""} {
        set ::install::xml::ids($id) $object_id
    }
    return
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
    if {$package_key eq ""} {
        set package_key [apm_attribute_value -default "" $node package]
    }

    # Remove double slashes
    regsub -all {//} $url "/" url

    if { $package_key ne "" && $url ne "" } {
        error "set-parameter: Can't specify both package and url for $url and $package_key"

    } elseif { $id ne "" } {
        if {[string is integer $id]} {
            return $id
        } else {
            return [install::xml::util::get_id $id]
        }
    } elseif { $package_key ne "" } {
        return [apm_package_ids_from_key -package_key $package_key]

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
    
    if {$group_type eq "group"} {
        set id [apm_required_attribute_value $node group-id]
    } elseif {$group_type eq "rel_segment"} {
        set id [apm_required_attribute_value $node parent-id]
    }

    set group_id [install::xml::util::get_id $id]

    if {$group_type eq "group"} {
        return $group_id
    } elseif {$group_type ne "rel_segment"} {
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

    if {$group_type eq "group"} {
        return $group_id
    } elseif {$group_type eq "rel_segment"} {
        return [group::get_rel_segment -group_id $group_id -type $relation_type]
    }
}

ad_proc -public install::xml::object_id::member-group { node } {
} {
    set package_id [::install::xml::object_id::package $node]
    return [subsite::get_member_group -package_id $package_id]
}

ad_proc -public install::xml::object_id::admin-group { node } {
} {
    set package_id [::install::xml::object_id::package $node]
    return [subsite::get_admin_group -package_id $package_id]
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

ad_proc -public ::install::xml::action::set-id { node } {
    set a name/id pair for use in other install xml things
} {
    set name  [apm_required_attribute_value $node name]
    set value [apm_required_attribute_value $node value]

    variable ::install::xml::ids
    set ids($name) $value
}
    
ad_proc -public install::xml::util::get_id { id } {
    Returns an id from the global ids variable if it exists and attempts to
    find an acs_magic_object if not.
} {
    variable ::install::xml::ids

    if {[catch {
        if {[string is integer $id]} {
            set result $id
        } elseif {[info exists ids($id)]} {
            set result $ids($id)
        } else {
            set result [acs_magic_object $id]
        }
    } err]} {
        error "$id is not an integer, is not defined in this install.xml, and is not an acs_magic_object"
    }
    
    return $result
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
