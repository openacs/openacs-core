# 

ad_library {
    
    Procudures for content template
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-09
    @arch-tag: a2fad1c8-17eb-412c-a62e-9704d346b27b
    @cvs-id $Id$
}

namespace eval ::content::template {}

ad_proc -public content::template::new {
    -name:required
    {-text ""}
    {-parent_id ""}
    {-is_live ""}
    {-template_id ""}
    -creation_date
    {-creation_user ""}
    {-creation_ip ""}
    {-package_id ""}
} {
    @param name
    @param text
    @param parent_id
    @param is_live
    @param template_id
    @param creation_date
    @param creation_user
    @param creation_ip

    @return template_id of created template
} {
    set arg_list [list \
        [list name $name ] \
        [list text $text ] \
        [list parent_id $parent_id ] \
        [list is_live $is_live ] \
        [list template_id $template_id ] \
        [list creation_user $creation_user ] \
        [list creation_ip $creation_ip ] \
        [list package_id $package_id ] \
    ]
    if {[exists_and_not_null creation_date]} {
        lappend arg_list [list creation_date $creation_date ]
    }
    return [package_exec_plsql -var_list  $arg_list content_template new]
}


ad_proc -public content::template::delete {
    -template_id:required
} {
    @param template_id
    @return 0
} {
    return [package_exec_plsql -var_list [list \
        [list template_id $template_id ] \
    ] content_template del]
}


ad_proc -public content::template::get_path {
    -template_id:required
    {-root_folder_id ""}
} {
    @param template_id
    @param root_folder_id
    @throws -20000: Invalid item ID: %'', get_path__item_id;

    @return "/" delimited path from root to supplied template_id
} {
    return [package_exec_plsql -var_list [list \
        [list template_id $template_id ] \
        [list root_folder_id $root_folder_id ] \
    ] content_template get_path]
}


ad_proc -public content::template::get_root_folder {
} {

    @return folder_id of Template Root Folder
} {
    return [package_exec_plsql -var_list [list \
    ] content_template get_root_folder]
}


ad_proc -public content::template::is_template {
    -template_id:required
} {
    @param template_id

    @return t or f
} {
    return [package_exec_plsql -var_list [list \
        [list template_id $template_id ] \
    ] content_template is_template]
}


