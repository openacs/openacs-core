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
    set user_id [ad_conn user_id]
    set id_addr [ad_conn peeraddr]

    set result [db_exec_plsql create_forward_link {}]
    db_exec_plsql create_backward_link {}

    return $result
}

ad_proc -public application_link::delete_links {
    -package_id:required
} {
    set rel_ids [db_list linked_packages {}]

    foreach rel_id $rel_ids {
	relation_remove $rel_id
    }
}

ad_proc -public application_link::get {
    -package_id:required
} {
    return [db_list linked_packages {}]
}

ad_proc -public application_link::get_linked {
    -from_package_id:required
    -to_package_key:required
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

    if {![string equal $this_package_url ""]} {
        set this_package_id [site_node::get_element -url $this_package_url \
            -element package_id]
    } elseif {![string equal $from_package_id ""]} {
        set this_package_id [install::xml::util::get_id $from_package_id]
    } else {
        error "application-link tag must specify either this_package_url or from-package-id"
    }

    if {![string equal $target_package_url ""]} {
        set target_package_id [site_node::get_element -url $target_package_url \
            -element package_id]
    } elseif {![string equal $to_package_id ""]} {
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

