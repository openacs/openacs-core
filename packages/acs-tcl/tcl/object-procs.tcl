ad_library {

    Object support for ACS.

    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 11 Aug 2000
    @cvs-id $Id$

}

namespace eval acs_object {}

ad_proc -private acs_lookup_magic_object { name } {

    Returns the object ID of a magic object (performing no memoization).

} {
    return [db_string magic_object_select {
	select object_id from acs_magic_objects where name = :name
    }]
}

ad_proc acs_magic_object { name } {

    Returns the object ID of a magic object.

    @param name the name of the magic object (as listed in the
        <code>acs_magic_objects</code> table).
    @return the object ID.
    @error if no object exists with that magic name.

} {
    return [util_memoize [list acs_lookup_magic_object $name]]
}

ad_proc acs_object_name { object_id } {

    Returns the name of an object.

} {
    return [db_string object_name_get {}]
}

ad_proc acs_object_type { object_id } {

    Returns the type of an object.

} {
    return [db_string object_type_select {
        select object_type
        from acs_objects
        where object_id = :object_id
    } -default ""]
}

ad_proc acs_object::get { 
    {-object_id:required}
    {-array:required}
} {
    Gets information about an acs_object.

    @array The name of an array in the caller's namespace where the info should be delivered.
} {
    upvar 1 $array row
    db_1row select_object {} -column_array row
}


ad_proc acs_object::get_element { 
    {-object_id:required}
    {-element:required}
} {
    Gets a specific element from the info returned by acs_object::get.

    @see acs_object::get
} {
    acs_object::get -object_id $object_id -array row
    return $row($element)
}

