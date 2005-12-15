ad_library {
    
    Procs of application data linking
    
    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-05-23
}

namespace eval application_data_link {}

ad_proc -public application_data_link::new {
    -this_object_id:required
    -target_object_id:required
} {
    set forward_rel_id [db_nextval acs_data_links_seq]
    set backward_rel_id [db_nextval acs_data_links_seq]

    db_dml create_forward_link {}
    db_dml create_backward_link {}
}

ad_proc -public application_data_link::delete_links {
    -object_id:required
} {
    set rel_ids [db_list linked_objects {}]

    foreach rel_id $rel_ids {
	db_dml delete_link {}
    }
}

ad_proc -public application_data_link::get {
    -object_id:required
} {
    return [db_list linked_objects {}]
}

ad_proc -public application_data_link::get_linked {
    -from_object_id:required
    -to_object_type:required
} {
    return [db_list linked_object {}]
}

ad_proc -public application_data_link::get_linked_content {
    -from_object_id:required
    -to_content_type:required
} {
    return [db_list linked_object {}]
}
