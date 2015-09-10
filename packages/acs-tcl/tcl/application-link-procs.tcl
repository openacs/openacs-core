ad_library {
    
    Procs of application linking
    
    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-05-23
}

namespace eval application_link {}

ad_proc -public application_link::new {
    -this_package_id:required
    -target_package_id:required
} {
    Create a new link between this_package_id and target_package_id.

    @param this_package_id ID of the package that you want linked to the target
    package.
    @param target_package_id The ID of the target package.
} {
    if {[catch {ad_conn user_id} user_id]} {
	set user_id 0
    }
    
    if {[catch {ad_conn peeraddr} id_addr]} {
	set id_addr 127.0.0.1
    }

    set result [db_exec_plsql create_forward_link {}]
    db_exec_plsql create_backward_link {}

    return $result
}

ad_proc -public application_link::delete_links {
    -package_id:required
} {
    Delete application links for all packages linking to the given
    package_id.

    @param package_id Package ID that you want application links removed
    from.
} {
    set rel_ids [db_list linked_packages {}]

    foreach rel_id $rel_ids {
	relation_remove $rel_id
    }
}

ad_proc -public application_link::get {
    -package_id:required
} {
    Retrieves a list of package_ids for all applications linked to the
    given package_id.

    @return List of linked package ids.
} {
    return [db_list linked_packages {}]
}

ad_proc -public application_link::get_linked {
    -from_package_id:required
    -to_package_key:required
} {
    Gets the ID for the application linked to from_package_id and matches the
    to_package_type.

    @param from_package_id Object ID of linked-from application.
    @param to_package_type Object type of linked-to application.

    @return package_id of linked package.
} {
    return [db_list linked_package {}]
}

ad_proc -private ::install::xml::action::application-link { node } {
    Create an application link:

    <p>&lt;application-link from-package-id=&quot;<em>from-package-id</em>&quot; to-package-id=&quot;<em>to-package-id</em>&quot;/&gt;</p>
} {
    set id [apm_attribute_value -default "" $node id]

    set this_package_url [apm_attribute_value \
        -default "" \
        $node \
        this_package_url]
    set target_package_url [apm_attribute_value \
        -default "" \
        $node \
        target_package_url]

    set from_package_id [apm_attribute_value -default "" $node from-package-id]
    set to_package_id [apm_attribute_value -default "" $node to-package-id]

    if {$this_package_url ne "" } {
        set this_package_id [site_node::get_element -url $this_package_url \
            -element package_id]
    } elseif {$from_package_id ne "" } {
        set this_package_id [install::xml::util::get_id $from_package_id]
    } else {
        error "application-link tag must specify either this_package_url or from-package-id"
    }

    if {$target_package_url ne "" } {
        set target_package_id [site_node::get_element -url $target_package_url \
            -element package_id]
    } elseif {$to_package_id ne "" } {
        set target_package_id [install::xml::util::get_id $to_package_id]
    } else {
        error "application-link tag must specify either target_package_url or to-package-id"
    }

    set link_id [application_link::new -this_package_id $this_package_id \
        -target_package_id $target_package_id]
 
    if {![string is space $id]} {
        set ::install::xml::ids($id) $link_id
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
