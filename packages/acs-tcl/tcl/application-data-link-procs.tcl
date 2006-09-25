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
    application_data_link::new_from \
	-object_id $this_object_id \
	-to_object_id $target_object_id
    application_data_link::new_to \
	-object_id $this_object_id \
        -from_object_id $target_object_id
}

ad_proc -public application_data_link::new_from {
    -object_id:required
    -to_object_id:required
} {
    Create a new data link between this_object_id and target_object_id.

    @param object_id ID of the object that you want linked to the target
    object.
    @param to_object_id The ID of the target object.
} {
    set forward_rel_id [db_nextval acs_data_links_seq]

    db_dml create_forward_link {}
}

ad_proc -public application_data_link::new_to {
    -object_id:required
    -from_object_id:required
} {
    Create a new data link between this_object_id and target_object_id.

    @param object_id ID of the object that you want linked to the target
    object.
    @param from_object_id The ID of the target object.
} {
    set backward_rel_id [db_nextval acs_data_links_seq]

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

ad_proc -public application_data_link::delete_from_list {
    -object_id
    -link_object_id_list 
} {
    Delete references

    @param object_id Object to delete links from
    @link_object_id_list List of linked object_ids to delete

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-31
} {
    if {[llength $link_object_id_list]} {
	db_dml delete_links ""
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

ad_proc -public application_data_link::get_links_from {
    -object_id:required
    {-to_type}
} {
    Get a list of objects that are linked from an object
    If to_type is a subtype of content_revision, we lookup 
    content_items that have that content_type

    @param object_id object_id one, get objects linked from this object
    @param to_type object_type of the objects to get links to
} {
    set to_type_where_clause ""
    set content_type_from_clause ""

    if {[info exists to_type] && $to_type ne ""} {
	set to_type_clause [db_map to_type_where_clause]
        if {[content::type::is_content_type -content_type $to_type]} {
	    set to_type_clause [db_map content_type_where_clause]
	    set content_type_from_clause [db_map content_type_from_clause]
	}
    }
    return [db_list links_from {}]
}

ad_proc -public application_data_link::scan_for_links {
    -text
} {
    Search for object references within text
    Supports /o/ /file/ /image/ object URL formats

    @param text Text to scan for object links 

    @return List of linked object_ids

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-31

} {
    set refs [list]
    set ref_data [regexp -inline -all {/(?:o|image|file)/(\d{1,8})} $text]
    foreach {discard ref} $ref_data {
	lappend refs $ref
    } 
    return $refs
}

ad_proc -public application_data_link::update_links_from {
    -object_id
    {-text {}}
    {-link_object_ids {}}
} {
    Update the references to this object in the database

    @param object_id Object_id to update
    @param text Text to scan for references
    @param linked_object_ids List of object ids to update the links to. Links not in this list will be deleted, and any in this list that are not in teh database will be added.

    @return List of updated linked object_ids

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-31
} {
    set old_links [application_data_link::get_links_from -object_id $object_id]
    if {![llength $link_object_ids]} {
	set link_object_ids [application_data_link::scan_for_links -text $text]
    }
    set delete_ids [list]
    foreach old_link $old_links {
	if {[lsearch $link_object_ids $old_link] < 0} {
	    lappend delete_ids $old_link
	}
    }
    application_data_link::delete_from_list -object_id $object_id -link_object_id_list $delete_ids
    foreach new_link $link_object_ids {
	if {![application_data_link::link_exists \
		  -from_object_id $object_id \
		  -to_object_id $new_link]} {
	    application_data_link::new_from -object_id $object_id -to_object_id $new_link
	}
    }
}

ad_proc -public application_data_link::link_exists {
    -from_object_id
    -to_object_id
} {
    Check if a link exists, only checks in the directon requested.

    @param from_object_id
    @param to_object_id

    @return 0 or 1

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-31
} {
    return [db_0or1row link_exists ""]
}
