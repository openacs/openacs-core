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

	set sql "
	select object_type,
	       pretty_name,
               '' as indent
	  from acs_object_types
	 start with object_type = :object_type
       connect by prior supertype = object_type
         order by level desc
    "

	set join_string "&nbsp;&gt;&nbsp;"

    } else {

	set sql "
	select object_type,
	       pretty_name,
	       replace(lpad(' ', (level - 1) * $indent_width), ' ', '$indent_string') as indent
	  from acs_object_types
         start with supertype is null
       connect by supertype = prior object_type
    "

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


ad_proc -public acs_object_type_hierarchy_pg_sql {

    -object_type
    -indent_string
    -indent_width

} {

    Returns pg version of sql for acs_object_type_hierarchy routine.  This 
    routine is called by the query dispatcher.

    @author Dan Wickstrom (dcwickstrom@earthlink.net)
    @creation-date April 24, 2001
    @param object_type the object type for which to show a hierarchy for.
    @param indent_string string with which to lpad
    @param indent_width number of times to insert <code>indent_string</code> into indentation

} {

    if { [exists_and_not_null object_type] } {

	set sql "
	select ot2.object_type,
	       ot2.pretty_name,
               '' as indent,
               tree_level(ot2.tree_sortkey) as level
	  from acs_object_types ot1, acs_object_types ot2
         where ot1.object_type = :object_type
           and ot2.tree_sortkey <= ot1.tree_sortkey
           and ot1.tree_sortkey like (ot2.tree_sortkey || '%')
         order by level desc
    "

    } else {
        #FIXME: what is the equivalent of oracle's replace function?
	set sql "
	select object_type,
	       pretty_name,
	       replace(lpad(' ', (tree_level(tree_sortkey) - 1) * $indent_width), ' ', '$indent_string') as indent
	  from acs_object_types
         where tree_sortkey like (select tree_sortkey || '%'
                                    from acs_object_types
                                   where supertype is null)
    "

    }

    return $sql
}
