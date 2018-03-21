ad_library {

    Object support for ACS.

    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 11 Aug 2000
    @cvs-id $Id$

}

namespace eval acs_object {}

ad_proc -private acs_lookup_magic_object_no_cache { name } {
    Non memoized version of acs_magic_object.

    @return the magic object's object ID 

    @see acs_magic_object
} {
    return [db_string magic_object_select {} ]
}

ad_proc -private acs_lookup_magic_object { name } {
    Non memoized version of acs_magic_object.

    @return the magic object's object ID 

    @see acs_magic_object
} {
    return [util_memoize [list acs_lookup_magic_object_no_cache $name]]
}

ad_proc -public acs_magic_object { name } {
    Returns the object ID of a magic object.

    @param name the name of the magic object (as listed in the
        <code>acs_magic_objects</code> table).
    @return the object ID.

    @error if no object exists with that magic name.
} {
    set key ::acs::magic_object($name)
    if {[info exists $key]} {
        return [set $key]
    } else {
        return [set $key [acs_lookup_magic_object $name]]
    }
}

ad_proc -public acs_object_name { object_id } {

    Returns the name of an object.

} {
    return [db_string object_name_get {}]
}

ad_proc -public acs_object_type { object_id } {

    Returns the type of an object.

} {
    return [db_string object_type_select {
        select object_type
        from acs_objects
        where object_id = :object_id
    } -default ""]
}

ad_proc -public acs_object::get { 
    {-object_id:required}
    {-array:required}
} {
    Gets information about an acs_object.

    Returns object_id, package_id, object_type, context_id, security_inherit_p, 
    creation_user, creation_date_ansi, creation_ip, last_modified_ansi,
    modifying_user, modifying_ip, tree_sortkey,  object_name

    @param array An array in the caller's namespace into which the info should be delivered (upvared)
} {
    upvar 1 $array row
    db_1row select_object {} -column_array row
}

ad_proc -public acs_object::package_id {
    {-object_id:required}
} {
    Gets the package_id of the object

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2006-08-10
    
    @param object_id the object to get the package_id for
    
    @return package_id of the object. Empty string if the package_id is not stored
} {
    return [util_memoize [list acs_object::package_id_not_cached -object_id $object_id]]
}

ad_proc -private acs_object::package_id_not_cached {
    {-object_id:required}
} {
    Gets the package_id of the object

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2006-08-10
    
    @param object_id the object to get the package_id for
    
    @return package_id of the object. Empty string if the package_id is not stored
} {
    return [db_string get_package_id {} -default ""]
}


ad_proc -public acs_object::get_element { 
    {-object_id:required}
    {-element:required}
} {
    Gets a specific element from the info returned by acs_object::get.

    @param object_id the object to get data for
    @param element the field to return

    @return the value of the specified element

    @see acs_object::get
} {
    acs_object::get -object_id $object_id -array row
    return $row($element)
}

ad_proc -public acs_object::object_p {
    -id:required
} {

    @author Jim Lynch (jim@jam.sessionsnet.org)
    @author Malte Sussdorff

    @creation-date 2007-01-26

    @param id ID of the potential acs-object

    @return true if object whose id is $id exists

} {
    return [db_string object_exists {} -default 0]
}

ad_proc -public acs_object::set_context_id {
    {-object_id:required}
    {-context_id:required}
} {
    Sets the context_id of the specified object.
} {
    db_dml update_context_id {}
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
