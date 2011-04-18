ad_library {

    Supporting procs for ACS Object Types

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date August 13, 2000
    @cvs-id $Id$

}

namespace eval acs_object_type {}

ad_proc -public acs_object_type_hierarchy {

    -object_type
    { -indent_string "&nbsp;" }
    { -indent_width "4" }
    { -join_string "<br>" }
    { -additional_html "" }

} {

    Returns an HTML snippet representing a hierarchy of ACS Object Types

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date August 13, 2000
    @param object_type the object type for which to show a hierarchy for.
    @param indent_string string with which to lpad
    @param indent_width number of times to insert <code>indent_string</code> into indentation
    @param join_string string with which to join each row returned by the query
    @param additional_html any additional html you might want to print per line

} {

    set result ""

    if { [exists_and_not_null object_type] } {
        set sql [db_map object_type_not_null]
	set join_string "&nbsp;&gt;&nbsp;"
    } else {
        set sql [db_map object_type_is_null]
    }

    set i 0
    db_foreach object_types "$sql" {

	if { $i > 0 } {
	    append result $join_string
	}
	incr i
	append result [subst {\n    $indent<a href="./one?[export_url_vars object_type]">[lang::util::localize $pretty_name]</a>}]
	append result $additional_html

    }

    return $result

}

ad_proc -public acs_object_type::get {
    -object_type:required
    -array:required
} {
    Get info about an object type. Returns columns 

    <ul>
      <li>object_type,
      <li>supertype,
      <li>abstract_p,
      <li>pretty_name,
      <li>pretty_plural,
      <li>table_name,
      <li>id_column,
      <li>package_name,
      <li>name_method,
      <li>type_extension_table,
      <li>dynamic_p
    </ul>
} {
    upvar 1 $array row
    db_1row select_object_type_info {
        select object_type,
               supertype,
               abstract_p,
               pretty_name,
               pretty_plural,
               table_name,
               id_column,
               package_name,
               name_method,
               type_extension_table,
               dynamic_p
        from   acs_object_types
        where  object_type = :object_type
    } -column_array row
}

ad_proc -private acs_object_type::acs_object_instance_of {
    {-object_id:required}
    {-type:required}
} {
    Returns true if the specified object_id is a subtype of the specified type.
    This is an inclusive check.

    @author Lee Denison (lee@thaum.net)
} {
    acs_object::get -object_id $object_id -array obj

    return [acs_object_type::supertype \
        -supertype $type \
        -subtype $obj(object_type)]
}

ad_proc -private acs_object_type::supertype {
    {-supertype:required}
    {-subtype:required}
} {
    Returns true if subtype is equal to, or a subtype of, supertype.

    @author Lee Denison (lee@thaum.net)
} {
    set supertypes [object_type::supertypes]
    append supertypes $subtype

    return [expr {[lsearch $supertypes $supertype] >= 0}]
}

ad_proc -private acs_object_type::supertypes {
    {-subtype:required}
    {-no_cache:boolean}
} {
    Returns a list of the supertypes of subtypes.

    @author Lee Denison (lee@thaum.net)
} {
    if {$no_cache_p} {
        return [db_list supertypes {}]
    } else {
        return [util_memoize [list acs_object_type::supertypes \
            -subtype $subtype \
            -no_cache]]
    }
}

ad_proc -private acs_object_type::get_table_name {
    -object_type:required
} {
    Return the table name associated with an object_type.

    Allow caching of the table_name as it is unlikely to change without a restart of the server (\which is mandatory after an upgrade)
} {
    return [util_memoize [list acs_object_type::get_table_name_not_cached -object_type $object_ty\pe]]
}

ad_proc -private acs_object_type::get_table_name_not_cached {
    -object_type:required
} {
    Return the table name associated with an object_type.

} {
    return [db_string get_table_name ""]
}