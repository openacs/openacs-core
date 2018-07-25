ad_library {

    Procs of application data linking

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2005-05-23
}

namespace eval application_data_link {}

# modified 2006/07/25 nfl: db_transaction around db_dml
# modified 2006/07/26 nfl: change db_transaction to catch
ad_proc -public application_data_link::new {
    -this_object_id:required
    -target_object_id:required
    {-relation_tag ""}
} {
    Create a new data link between this_object_id and target_object_id.

    @param this_object_id ID of the object that you want linked to the target
    object.
    @param target_object_id The ID of the target object.
    @param relation_tag Relationship identifier
} {
    if { [catch {
        application_data_link::new_from \
            -object_id $this_object_id \
            -to_object_id $target_object_id \
            -relation_tag $relation_tag

        application_data_link::new_to \
            -object_id $this_object_id \
            -from_object_id $target_object_id \
            -relation_tag $relation_tag

    }]}  {
        # check if error occurred because of existing link
        if { [application_data_link::exist_link -object_id $this_object_id -target_object_id $target_object_id -relation_tag $relation_tag] eq "1" } {
            ns_log Debug "application_data_link::new: link already exists"
        } else {
            ns_log Error "application_data_link::new: link creation failure"
        }
    }
}

ad_proc -public application_data_link::new_from {
    -object_id:required
    -to_object_id:required
    {-relation_tag ""}
} {
    Create a new data link between this_object_id and target_object_id.

    @param object_id ID of the object that you want linked to the target
    object.
    @param to_object_id The ID of the target object.
    @param relation_tag Relationship identifier
} {
    set forward_rel_id [db_nextval acs_data_links_seq]

    # Flush the cache for both items
    util_memoize_flush_regexp "application_data_link::get_linked_not_cached -from_object_id $object_id -relation_tag $relation_tag .*"
    util_memoize_flush_regexp "application_data_link::get_linked_not_cached -from_object_id $to_object_id -relation_tag $relation_tag .*"
    util_memoize_flush_regexp "application_data_link::get_linked_content_not_cached -from_object_id $object_id .*"
    util_memoize_flush_regexp "application_data_link::get_linked_content_not_cached -from_object_id $to_object_id .*"

    db_dml create_forward_link {}
}

ad_proc -public application_data_link::new_to {
    -object_id:required
    -from_object_id:required
    {-relation_tag ""}
} {
    Create a new data link between this_object_id and target_object_id.

    @param object_id ID of the object that you want linked to the target
    object.
    @param from_object_id The ID of the target object.
    @param relation_tag Relationship identifier
} {
    set backward_rel_id [db_nextval acs_data_links_seq]

    # Flush the cache for both items
    util_memoize_flush_regexp "application_data_link::get_linked_not_cached -from_object_id $object_id -relation_tag $relation_tag .*"
    util_memoize_flush_regexp "application_data_link::get_linked_not_cached -from_object_id $from_object_id -relation_tag $relation_tag .*"
    util_memoize_flush_regexp "application_data_link::get_linked_content_not_cached -from_object_id $object_id .*"
    util_memoize_flush_regexp "application_data_link::get_linked_content_not_cached -from_object_id $from_object_id .*"

    db_dml create_backward_link {}
}

# created 2006/07/25 nfl exist a link, returns 0 or 1
ad_proc -public application_data_link::exist_link {
    -object_id:required
    -target_object_id:required
    {-relation_tag ""}
} {
    Check for the existence of a link from an object_id to a target_object_id,
    with optional relation_tag.

    @param object_id The object we're looking for a link from
    @param target_object_id The object we're looking for a link to
    @param relation_tag Relationship identifier
} {
    set linked_objects [ application_data_link::get -object_id $object_id -relation_tag $relation_tag]
    if {$target_object_id in $linked_objects} {
      # found link
      return 1
    } else {
      return 0
    }
}

ad_proc -public application_data_link::delete_links {
    -object_id:required
    {-relation_tag ""}
} {
    Delete application data links for all objects linking to the given
    object_id. Optionally delete by object_id and relation_tag.

    @param object_id Object ID that you want application data links removed
    from.
    @param relation_tag Relationship identifier.
} {
    set rel_ids [db_list linked_objects {}]

    foreach rel_id $rel_ids {
        db_dml delete_link {}
    }
}

ad_proc -public application_data_link::delete_from_list {
    -object_id
    -link_object_id_list
    {-relation_tag ""}
} {
    Delete references

    @param object_id Object to delete links from
    @param link_object_id_list List of linked object_ids to delete
    @param relation_tag Relationship identifier

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-31
} {
    if {[llength $link_object_id_list]} {
        db_dml delete_links ""
    }
}

ad_proc -public application_data_link::get {
    -object_id:required
    {-relation_tag ""}
} {
    Retrieves a list of object_ids for all objects linked to the
    given object_id, tagged with the optional relation_tag.

    @param object_id Retrieve objects linked to this object_id
    @param relation_tag Relationship identifier.
    @return List of linked object ids.
} {
    return [db_list linked_objects {}]
}

ad_proc -public application_data_link::get_linked {
    -from_object_id:required
    -to_object_type:required
    {-relation_tag ""}
} {
    Gets the ID for the object linked to from_object_id and matches the
    to_object_type. Optionally, pass a relationship tag.

    @param from_object_id Object ID of linked-from object.
    @param to_object_type Object type of linked-to object.
    @param relation_tag Relationship identifier

    @return object_id of linked object.
} {
    return [util_memoize [list application_data_link::get_linked_not_cached -from_object_id $from_object_id -to_object_type $to_object_type -relation_tag $relation_tag]]
}

ad_proc -private application_data_link::get_linked_not_cached {
    -from_object_id:required
    -to_object_type:required
    {-relation_tag ""}
} {
    Gets the ID for the object linked to from_object_id and matches the
    to_object_type. Optionally, pass a relationship tag.

    @param from_object_id Object ID of linked-from object.
    @param to_object_type Object type of linked-to object.
    @param relation_tag   Relationship identifier

    @return object_id of linked object.
} {
    return [db_list linked_object {}]
}

ad_proc -public application_data_link::get_linked_content {
    -from_object_id:required
    -to_content_type:required
    {-relation_tag ""}
} {
    Gets the content of the linked object.

    @param from_object_id Object ID of linked-from object.
    @param to_content_type Content type of linked-to object.
    @param relation_tag

    @return item_id for the content item.
} {
    return [util_memoize [list application_data_link::get_linked_content_not_cached -from_object_id $from_object_id -to_content_type $to_content_type -relation_tag $relation_tag]]
}

ad_proc -private application_data_link::get_linked_content_not_cached {
    -from_object_id:required
    -to_content_type:required
    {-relation_tag ""}
} {
    Gets the content of the linked object.

    @param from_object_id Object ID of linked-from object.
    @param to_content_type Content type of linked-to object.
    @param relation_tag

    @return item_id for the content item.
} {
    return [db_list linked_object {}]
}

ad_proc -public application_data_link::get_links_from {
    -object_id:required
    {-to_type}
    {-relation_tag ""}
} {
    Get a list of objects that are linked from an object,
    possible using the relation_tag.
    If to_type is a subtype of content_revision, we lookup
    content_items that have that content_type

    @param object_id object_id one, get objects linked from this object
    @param to_type object_type of the objects to get links to
} {
    set to_type_where_clause ""
    set content_type_from_clause ""

    if {[info exists to_type] && $to_type ne ""} {
        set to_type_clause [db_map to_type_where_clause]
            if {[content::type::is_content_type -object_type $to_type]} {
            set to_type_clause [db_map content_type_where_clause]
            set content_type_from_clause [db_map content_type_from_clause]
        }
    }
    return [db_list links_from {}]
}

ad_proc -public application_data_link::get_links_to {
    -object_id:required
    {-from_type}
    {-relation_tag ""}
} {
    Get a list of objects that are linked to an object,
    possible using the relation_tag.
    If from_type is a subtype of content_revision, we lookup
    content_items that have that content_type

    @param object_id object_id two, get objects linked to this object
    @param from_type object_type of the objects to get links from
} {
    set from_type_where_clause ""
    set content_type_from_clause ""

    if {[info exists from_type] && $from_type ne ""} {
        set from_type_clause [db_map from_type_where_clause]
            if {[content::type::is_content_type -content_type $from_type]} {
            set from_type_clause [db_map content_type_where_clause]
            set content_type_from_clause [db_map content_type_from_clause]
        }
    }
    return [db_list links_to {}]
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
    set http_url [string trimright [ad_url] /]/
    set https_url [string map {http https} $http_url]
    set re "(?:\")(?:$http_url|$https_url|/)(?:o|image|file)/(\\d{1,8})"
    set ref_data [regexp -inline -all $re $text]
    foreach {discard ref} $ref_data {
            lappend refs $ref
    }
    if {[llength $refs]} {
        set refs [db_list confirm_object_ids {}]
    }
    return $refs
}

ad_proc -public application_data_link::update_links_from {
    -object_id
    {-text {}}
    {-link_object_ids {}}
    {-relation_tag ""}
} {
    Update the references to this object in the database,
    optionally update links using the given relation_tag.

    @param object_id Object_id to update
    @param text Text to scan for references
    @param link_object_ids List of object ids to update the links to. Links not in this list will be deleted, and any in this list that are not in the database will be added.
    @param relation_tag Relationship identifier

    @return List of updated linked object_ids

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-31
} {
    set old_links [application_data_link::get_links_from \
                       -object_id $object_id \
                       -relation_tag $relation_tag]

    if {![llength $link_object_ids]} {
        set link_object_ids [application_data_link::scan_for_links -text $text]
    }
    set delete_ids [list]
    foreach old_link $old_links {
        if {$old_link ni $link_object_ids} {
            lappend delete_ids $old_link
        }
    }
    application_data_link::delete_from_list \
                -object_id $object_id \
                -link_object_id_list $delete_ids \
                -relation_tag $relation_tag

    foreach new_link $link_object_ids {
        if {![application_data_link::link_exists \
                -from_object_id $object_id \
                -to_object_id $new_link \
                -relation_tag $relation_tag]
        } {
            application_data_link::new_from \
                -object_id $object_id \
                -to_object_id $new_link \
                -relation_tag $relation_tag
        }
    }
}

ad_proc -public application_data_link::link_exists {
    -from_object_id
    -to_object_id
    {-relation_tag ""}
} {
    Check if a link exists, only checks in the directon requested.
    Optionally check if the link has the given tag.

    @param from_object_id
    @param to_object_id
    @param relation_tag

    @return 0 or 1

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2006-08-31
} {
    return [db_0or1row link_exists ""]
}

ad_proc -public application_data_link::relation_tag_where_clause {
    {-relation_tag ""}
} {
    Utility proc to return relation tag where clause fragment.
    We show all object links regardless of tag if relation_tag is empty string.

    @param relation_tag Relationship identifier
} {
    if {$relation_tag eq ""} {
        return ""
    } else {
        return [db_map where_clause]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
