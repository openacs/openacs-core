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

ad_proc -private -deprecated acs_lookup_magic_object { name } {
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
    return [acs::per_thread_cache eval -key acs-tcl.acs_magic_object($name) {
        acs_lookup_magic_object_no_cache $name
    }]
}

ad_proc -public acs_object_name { object_id } {

    Returns the name of an object.

} {
    return [db_string object_name_get {
        select acs_object.name(:object_id) from dual
    }]
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
    {-array}
    {-element}
} {
    Gets information about an acs_object.

    If called without "-element", it returns a dict containing
    object_id, package_id, object_type, context_id,
    security_inherit_p, creation_user, creation_date_ansi,
    creation_ip, last_modified_ansi, modifying_user, modifying_ip,
    tree_sortkey, object_name.

    If called with "-element" it returns the denoted element (similar
    to e.g. "party::get").
    
    @param array An array in the caller's namespace into which the info should be delivered (upvared)
    @param element to be returned
    @param object_id for which the information should be retrieved
    @error when object_id does not exist
} {
    if {[info exists array]} {
        upvar 1 $array row
    }
    db_1row select_object {
        select o.object_id,
               o.title,
               o.package_id,
               o.object_type,
               o.context_id,
               o.security_inherit_p,
               o.creation_user,
               to_char(o.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date_ansi,
               o.creation_ip,
               to_char(o.last_modified, 'YYYY-MM-DD HH24:MI:SS') as last_modified_ansi,
               o.modifying_user,
               o.modifying_ip,
               acs_object.name(o.object_id) as object_name
        from   acs_objects o
        where  o.object_id = :object_id
    } -column_array row

    if {[info exists element]} {
        return [dict get [array get row] $element]
    } else {
        return [array get row]
    }
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
    return [acs_object::get -object_id $object_id -element $element]
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
