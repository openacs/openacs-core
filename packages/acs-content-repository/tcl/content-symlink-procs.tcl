# 

ad_library {
    
    Procedures for content symlink
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-09
    @arch-tag: 31c66882-e912-4db4-84fe-8a2b0890ffb0
    @cvs-id $Id$
}

namespace eval ::content::symlink {}

ad_proc -public content::symlink::copy {
    -symlink_id:required
    -target_folder_id:required
    -creation_user:required
    {-creation_ip ""}
} {
    @param symlink_id
    @param target_folder_id
    @param creation_user
    @param creation_ip
} {
    return [package_exec_plsql -var_list [list \
        [list symlink_id $symlink_id ] \
        [list target_folder_id $target_folder_id ] \
        [list creation_user $creation_user ] \
        [list creation_ip $creation_ip ] \
    ] content_symlink copy]
}


ad_proc -public content::symlink::delete {
    -symlink_id:required
} {
    @param symlink_id
} {
    return [package_exec_plsql -var_list [list \
        [list symlink_id $symlink_id ] \
    ] content_symlink delete]
}


ad_proc -public content::symlink::is_symlink {
    -item_id:required
} {
    @param item_id

    @return CHAR
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_symlink is_symlink]
}


ad_proc -public content::symlink::new {
    {-name ""}
    {-label ""}
    -target_id:required
    -parent_id:required
    {-symlink_id ""}
    -creation_date
    {-creation_user ""}
    {-creation_ip ""}
} {
    This procedure allows you to create a new Symlink
    @param name Name of the new content item. Used instead of "symlink_to_item target_id"
    @param label 
    @param target_id Item_id of the item to which the link should point
    @param parent_id item_id (preferably folder_id) of the parent (folder) where the link is associated and shown in. 
    @param symlink_id
    @param creation_date
    @param creation_user
    @param creation_ip

    @return NUMBER(38)
} {
    set var_list [list \
        [list name $name ] \
        [list label $label ] \
        [list target_id $target_id ] \
        [list parent_id $parent_id ] \
        [list symlink_id $symlink_id ] \
        [list creation_user $creation_user ] \
        [list creation_ip $creation_ip ] \
    ]
    if {[exists_and_not_null creation_date]} {
        lappend var_list [list creation_date $creation_date ]
    }
    return [package_exec_plsql -var_list $var_list content_symlink new]
}


ad_proc -public content::symlink::resolve {
    -item_id:required
} {
    Return the item_id of the target item to which the symlink points
    @param item_id item_id of the symlink

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_symlink resolve]
}


ad_proc -public content::symlink::resolve_content_type {
    -item_id:required
} {
    @param item_id

    @return VARCHAR2(100)
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_symlink resolve_content_type]
}
