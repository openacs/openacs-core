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
    Create a new data link between this_object_id and target_object_id.

    @param this_object_id ID of the object that you want linked to the target
    object.
    @param target_object_id The ID of the target object.
} {
    set forward_rel_id [db_nextval acs_data_links_seq]
    set backward_rel_id [db_nextval acs_data_links_seq]

    db_dml create_forward_link {}
    db_dml create_backward_link {}
}

ad_proc -public application_data_link::delete_links {
    -object_id:required
} {
    Delete application data links for all objects linking to the given
    object_id.

    @param object_id Object ID that you want application data links removed
    from.
} {
    set rel_ids [db_list linked_objects {}]

    foreach rel_id $rel_ids {
	db_dml delete_link {}
    }
}

ad_proc -public application_data_link::get {
    -object_id:required
} {
    Retrieves a list of object_ids for all objects linked to the
    given object_id.

    @return List of linked object ids.
} {
    return [db_list linked_objects {}]
}

ad_proc -public application_data_link::get_linked {
    -from_object_id:required
    -to_object_type:required
} {
    Gets the ID for the object linked to from_object_id and matches the
    to_object_type.

    @param from_object_id Object ID of linked-from object.
    @param to_object_type Object type of linked-to object.

    @return object_id of linked object.
} {
    return [db_list linked_object {}]
}

ad_proc -public application_data_link::get_linked_content {
    -from_object_id:required
    -to_content_type:required
} {
    Gets the content of the linked object.

    @param from_object_id Object ID of linked-from object.
    @param to_content_type Content type of linked-to object.

    @return item_id for the content item.
} {
    return [db_list linked_object {}]
}
