ad_library {

    Supporting procs for ACS Object Types

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date August 13, 2000
    @cvs-id $Id$

}

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
	append result "\n    $indent<a href=./one?[export_url_vars object_type]>$pretty_name</a>"
	append result $additional_html

    }

    return $result

}

