# 

ad_library {
    
    Procudures for content template
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-09
    @arch-tag: a2fad1c8-17eb-412c-a62e-9704d346b27b
    @cvs-id $Id$
}

namespace eval ::content::template {}


ad_proc -public content::template::del {
    -template_id:required
} {
    @param template_id
} {
    return [package_exec_plsql -var_list [list \
        template_id $template_id \
    ] content_template del]
}


ad_proc -public content::template::get_path {
    -template_id:required
    {-root_folder_id ""}
} {
    @param template_id
    @param root_folder_id

    @return VARCHAR2
} {
    return [package_exec_plsql -var_list [list \
        template_id $template_id \
        root_folder_id $root_folder_id \
    ] content_template get_path]
}


ad_proc -public content::template::get_root_folder {
} {

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
    ] content_template get_root_folder]
}


ad_proc -public content::template::is_template {
    -template_id:required
} {
    @param template_id

    @return VARCHAR2
} {
    return [package_exec_plsql -var_list [list \
        template_id $template_id \
    ] content_template is_template]
}


ad_proc -public content::template::new {
    -name:required
    {-text ""}
    {-parent_id ""}
    {-is_live ""}
    {-template_id ""}
    {-creation_date ""}
    {-creation_user ""}
    {-creation_ip ""}
} {
    @param name
    @param text
    @param parent_id
    @param is_live
    @param template_id
    @param creation_date
    @param creation_user
    @param creation_ip

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        name $name \
        text $text \
        parent_id $parent_id \
        is_live $is_live \
        template_id $template_id \
        creation_date $creation_date \
        creation_user $creation_user \
        creation_ip $creation_ip \
    ] content_template new]
}
