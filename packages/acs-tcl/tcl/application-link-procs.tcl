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

    db_exec_plsql create_forward_link {}
    db_exec_plsql create_backward_link {}
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
    Create a forum instance from an install.xml file
} {
    set this_package_url [apm_required_attribute_value $node this_package_url]
    set target_package_url [apm_required_attribute_value $node target_package_url]

    set this_package_id [site_node::get_element -url $this_package_url -element package_id]
    set target_package_id [site_node::get_element -url $target_package_url -element package_id]

    application_link::new -this_package_id $this_package_id -target_package_id $target_package_id

}

