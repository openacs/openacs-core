
ad_library {
    
    Procedures for content_keywords
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-09
    @arch-tag: dc56be97-e611-4f34-a5b6-264b46a6ad7b
    @cvs-id $Id$
}

namespace eval ::content::keyword {}

ad_proc -public content::keyword::write_to_file {
    -item_id:required
    -root_path:required
} {
    @param item_id
    @param root_path
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
        [list root_path $root_path ] \
    ] content_keyword write_to_file]
}


ad_proc -public content::keyword::delete {
    -keyword_id:required
} {
    @param keyword_id
    @return 0 
} {
    return [package_exec_plsql -var_list [list \
        [list keyword_id $keyword_id ] \
    ] content_keyword del]
}


ad_proc -public content::keyword::get_description {
    -keyword_id:required
} {
    @param keyword_id

    @return string with description 
} {
    return [package_exec_plsql -var_list [list \
        [list keyword_id $keyword_id ] \
    ] content_keyword get_description]
}


ad_proc -public content::keyword::get_heading {
    -keyword_id:required
} {
    @param keyword_id

    @return string with heading
} {
    return [package_exec_plsql -var_list [list \
        [list keyword_id $keyword_id ] \
    ] content_keyword get_heading]
}


ad_proc -public content::keyword::get_path {
    -keyword_id:required
} {
    @param keyword_id

    @return "/" delimited path in the keyword tree to the supplied keyword
} {
    return [package_exec_plsql -var_list [list \
        [list keyword_id $keyword_id ] \
    ] content_keyword get_path]
}


ad_proc -public content::keyword::is_assigned {
    -item_id:required
    -keyword_id:required
    {-recurse ""}
} {
    @param item_id
    @param keyword_id
    @param recurse

    @return t or f
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
        [list keyword_id $keyword_id ] \
        [list recurse $recurse ] \
    ] content_keyword is_assigned]
}


ad_proc -public content::keyword::is_leaf {
    -keyword_id:required
} {
    @param keyword_id

    @return t or f
} {
    return [package_exec_plsql -var_list [list \
        [list keyword_id $keyword_id ] \
    ] content_keyword is_leaf]
}


ad_proc -public content::keyword::item_assign {
    -item_id:required
    -keyword_id:required
    {-context_id ""}
    {-creation_user ""}
    {-creation_ip ""}
} {
    @param item_id
    @param keyword_id
    @param context_id
    @param creation_user
    @param creation_ip

    Associate a keyword with a CR item.

    @return 0
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
        [list keyword_id $keyword_id ] \
        [list context_id $context_id ] \
        [list creation_user $creation_user ] \
        [list creation_ip $creation_ip ] \
    ] content_keyword item_assign]
}


ad_proc -public content::keyword::item_unassign {
    -item_id:required
    -keyword_id:required
} {
    @param item_id
    @param keyword_id

    @return 0
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
        [list keyword_id $keyword_id ] \
    ] content_keyword item_unassign]
}


ad_proc -public content::keyword::new {
    -heading:required
    {-description ""}
    {-parent_id ""}
    {-keyword_id ""}
    -creation_date
    {-creation_user ""}
    {-creation_ip ""}
    -object_type
} {
    @param heading
    @param description
    @param parent_id
    @param keyword_id
    @param creation_date
    @param creation_user
    @param creation_ip
    @param object_type

    @return keyword_id of created keyword
} {
    set var_list [list \
        [list heading $heading ] \
        [list description $description ] \
        [list parent_id $parent_id ] \
        [list keyword_id $keyword_id ] \
        [list creation_user $creation_user ] \
        [list creation_ip $creation_ip ] \
    ]
    if {[info exists creation_date] && $creation_date ne ""} {
        lappend var_list [list creation_date $creation_date ]
    }
    if {[info exists object_type] && $object_type ne ""} {
        lappend var_list [list object_type $object_type ]
    }
    return [package_exec_plsql -var_list $var_list content_keyword new]
}


ad_proc -public content::keyword::set_description {
    -keyword_id:required
    -description:required
} {
    @param keyword_id
    @param description
    @return 0
} {
    return [package_exec_plsql -var_list [list \
        [list keyword_id $keyword_id ] \
        [list description $description ] \
    ] content_keyword set_description]
}


ad_proc -public content::keyword::set_heading {
    -keyword_id:required
    -heading:required
} {
    @param keyword_id
    @param heading
    @return 0
} {
    return [package_exec_plsql -var_list [list \
        [list keyword_id $keyword_id ] \
        [list heading $heading ] \
    ] content_permission set_heading]
}


ad_proc -public content::keyword::get_children {
    {-parent_id ""}
} {
    Returns the ids of the keywords having the given parent_id. Returns
    an empty list if there are no children.

    @author Peter Marklund
} {
    return [db_list select_child_keywords {
        select keyword_id
        from cr_keywords
        where parent_id = :parent_id
    }]
}

ad_proc -public content::keyword::get_keyword_id {
    {-parent_id:required}
    {-heading:required}
} {
    Get the keyword with the given heading under the given parent.
    Returns the empty string if none exists.
} {
    return [db_string select_keyword_id {
	select keyword_id 
	from   cr_keywords
	where  parent_id = :parent_id
	and    heading = :heading
    } -default {}]
}

ad_proc -public content::keyword::get_options_flat {
    {-parent_id ""}
} {
    Returns a flat options list of the keywords with the given parent_id.
} {
    return [db_list_of_lists select_keyword_options [subst {
	select heading, keyword_id
	from   cr_keywords
	where  [ad_decode $parent_id "" "parent_id is null" "parent_id = :parent_id"]
	order  by lower(heading)}]]
}

ad_proc -public content::keyword::item_get_assigned {
    {-item_id:required}
    {-parent_id}
} {
    Returns a list of all keywords assigned to the given cr_item.

    If parent_id is supplied, only keywords that are children of
    parent_id are listed.
} {
    if {[info exists parent_id]} {
        set keyword_list [db_list get_child_keywords {
            select km.keyword_id
            from cr_item_keyword_map km,
                 cr_keywords kw
            where km.item_id = :item_id
            and   kw.parent_id = :parent_id
            and   kw.keyword_id = km.keyword_id
	}]
    } else {
        set keyword_list [db_list get_keywords {
            select keyword_id from cr_item_keyword_map
            where item_id = :item_id
	}]
    }

    return $keyword_list
}


ad_proc -public content::keyword::item_unassign_children {
    {-item_id:required}
    {-parent_id:required}
} {
    Unassign all the keywords attached to a content item
    that are children of keyword parent_id.

    Returns the supplied item_id for convenience.
} {
    db_dml item_unassign_children {
	delete from cr_item_keyword_map
	where item_id = :item_id
	and   keyword_id in (select p.keyword_id
			     from   cr_keywords p
			     where  p.parent_id = :parent_id)
    }
    return $item_id
}
