ad_library {
    Procs for manipulating keywords.
    
    @author Lars Pind
    @author Mark Aufflick
    @creation-date February 27, 2003
    @cvs-id $Id$
}

namespace eval cr {}
namespace eval cr::keyword {}

ad_proc -public cr::keyword::new {
    {-heading:required}
    {-description ""}
    {-parent_id ""}
    {-keyword_id ""}
    {-object_type "content_keyword"}
} {
    Create a new keyword
} {
    set user_id [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]

    set keyword_id [db_exec_plsql content_keyword_new {}]
    
    return $keyword_id
}

ad_proc -public cr::keyword::set_heading {
    {-keyword_id:required}
    {-heading:required}
} {
    Update a keyword heading
} {
    db_exec_plsql set_heading { }
}

ad_proc -public cr::keyword::get_keyword_id {
    {-parent_id:required}
    {-heading:required}
} {
    Get the keyword with the given heading under the given parent.
    Returns the empty string if none exists.
} {
    return [db_string select_keyword_id {} -default {}]
}

ad_proc -public cr::keyword::item_unassign {
    {-keyword_id:required}
    {-item_id:required}
} {
    Unassign a single keyword from a content item.

    Returns the supplied item_id for convenience.
} {
    db_exec_plsql item_unassign {}

    return $item_id
}

ad_proc -public cr::keyword::item_unassign_children {
    {-item_id:required}
    {-parent_id:required}
} {
    Unassign all the keywords attached to a content item
    that are children of keyword parent_id.

    Returns the supplied item_id for convenience.
} {
    db_dml item_unassign_children {}

    return $item_id
}

ad_proc -public cr::keyword::item_assign {
    {-item_id:required}
    {-keyword_id:required}
    {-singular:boolean}
} {
    Assign a keyword to a content_item.

    If singular_p is specified, then any keywords with the same parent_id as this keyword_id
    will first be unassigned.

    Returns the supplied item_id for convenience.
} {
    if {$singular_p} {
        set parent_id [db_string get_parent_id {}]
        item_unassign_children -item_id $item_id -parent_id $parent_id
    }

    db_exec_plsql keyword_assign {}

    return $item_id
}

ad_proc -public cr::keyword::item_get_assigned {
    {-item_id:required}
    {-parent_id}
} {
    Returns a list of all keywords assigned to the given cr_item.

    If parent_id is supplied, only keywords that are children of
    parent_id are listed.
} {
    if {[info exists parent_id]} {
        set keyword_list [db_list get_child_keywords {}]
    } else {
        set keyword_list [db_list get_keywords {}]
    }

    return $keyword_list
}


