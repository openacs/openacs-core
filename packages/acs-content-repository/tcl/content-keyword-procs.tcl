# 

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
    if {[exists_and_not_null creation_date]} {
        lappend var_list [list creation_date $creation_date ]
    }
    if {[exists_and_not_null object_type]} {
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
