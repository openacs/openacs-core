# 

ad_library {
    
    Procedures for content types
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-09
    @arch-tag: 4a8a3652-fd5d-49aa-86fc-fade683f06ce
    @cvs-id $Id$
}

namespace eval ::content::type {}

ad_proc -public content::type::create_attribute {
    -content_type:required
    -attribute_name:required
    -datatype:required
    -pretty_name:required
    {-pretty_plural ""}
    {-sort_order ""}
    {-default_value ""}
    {-column_spec ""}
} {
    @param content_type
    @param attribute_name
    @param datatype
    @param pretty_name
    @param pretty_plural
    @param sort_order
    @param default_value
    @param column_spec

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list attribute_name $attribute_name ] \
        [list datatype $datatype ] \
        [list pretty_name $pretty_name ] \
        [list pretty_plural $pretty_plural ] \
        [list sort_order $sort_order ] \
        [list default_value $default_value ] \
        [list column_spec $column_spec ] \
    ] content_type create_attribute]
}


ad_proc -public content::type::create_type {
    -content_type:required
    {-supertype ""}
    -pretty_name:required
    -pretty_plural:required
    {-table_name ""}
    {-id_column ""}
    {-name_method ""}
} {
    @param content_type
    @param supertype
    @param pretty_name
    @param pretty_plural
    @param table_name
    @param id_column
    @param name_method
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list supertype $supertype ] \
        [list pretty_name $pretty_name ] \
        [list pretty_plural $pretty_plural ] \
        [list table_name $table_name ] \
        [list id_column $id_column ] \
        [list name_method $name_method ] \
    ] content_type create_type]
}


ad_proc -public content::type::drop_attribute {
    -content_type:required
    -attribute_name:required
    {-drop_column ""}
} {
    @param content_type
    @param attribute_name
    @param drop_column
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list attribute_name $attribute_name ] \
        [list drop_column $drop_column ] \
    ] content_type drop_attribute]
}


ad_proc -public content::type::drop_type {
    -content_type:required
    {-drop_children_p ""}
    {-drop_table_p ""}
} {
    @param content_type
    @param drop_children_p
    @param drop_table_p
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list drop_children_p $drop_children_p ] \
        [list drop_table_p $drop_table_p ] \
    ] content_type drop_type]
}


ad_proc -public content::type::get_template {
    -content_type:required
    -use_context:required
} {
    @param content_type
    @param use_context

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list use_context $use_context ] \
    ] content_type get_template]
}


ad_proc -public content::type::is_content_type {
    -object_type:required
} {
    @param object_type

    @return CHAR
} {
    return [package_exec_plsql -var_list [list \
        [list object_type $object_type ] \
    ] content_type is_content_type]
}


ad_proc -public content::type::refresh_view {
    -content_type:required
} {
    @param content_type
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
    ] content_type refresh_view]
}


ad_proc -public content::type::register_child_type {
    -parent_type:required
    -child_type:required
    {-relation_tag ""}
    {-min_n ""}
    {-max_n ""}
} {
    @param parent_type
    @param child_type
    @param relation_tag
    @param min_n
    @param max_n
} {
    return [package_exec_plsql -var_list [list \
        [list parent_type $parent_type ] \
        [list child_type $child_type ] \
        [list relation_tag $relation_tag ] \
        [list min_n $min_n ] \
        [list max_n $max_n ] \
    ] content_type register_child_type]
}


ad_proc -public content::type::register_mime_type {
    -content_type:required
    -mime_type:required
} {
    @param content_type
    @param mime_type
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list mime_type $mime_type ] \
    ] content_type register_mime_type]
}


ad_proc -public content::type::register_relation_type {
    -content_type:required
    -target_type:required
    {-relation_tag ""}
    {-min_n ""}
    {-max_n ""}
} {
    @param content_type
    @param target_type
    @param relation_tag
    @param min_n
    @param max_n
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list target_type $target_type ] \
        [list relation_tag $relation_tag ] \
        [list min_n $min_n ] \
        [list max_n $max_n ] \
    ] content_type register_relation_type]
}


ad_proc -public content::type::register_template {
    -content_type:required
    -template_id:required
    -use_context:required
    {-is_default ""}
} {
    @param content_type
    @param template_id
    @param use_context
    @param is_default
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list template_id $template_id ] \
        [list use_context $use_context ] \
        [list is_default $is_default ] \
    ] content_type register_template]
}


ad_proc -public content::type::rotate_template {
    -template_id:required
    -v_content_type:required
    -use_context:required
} {
    @param template_id
    @param v_content_type
    @param use_context
} {
    return [package_exec_plsql -var_list [list \
        [list template_id $template_id ] \
        [list v_content_type $v_content_type ] \
        [list use_context $use_context ] \
    ] content_type rotate_template]
}


ad_proc -public content::type::set_default_template {
    -content_type:required
    -template_id:required
    -use_context:required
} {
    @param content_type
    @param template_id
    @param use_context
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list template_id $template_id ] \
        [list use_context $use_context ] \
    ] content_type set_default_template]
}


ad_proc -public content::type::unregister_child_type {
    -parent_type:required
    -child_type:required
    {-relation_tag ""}
} {
    @param parent_type
    @param child_type
    @param relation_tag
} {
    return [package_exec_plsql -var_list [list \
        [list parent_type $parent_type ] \
        [list child_type $child_type ] \
        [list relation_tag $relation_tag ] \
    ] content_type unregister_child_type]
}


ad_proc -public content::type::unregister_mime_type {
    -content_type:required
    -mime_type:required
} {
    @param content_type
    @param mime_type
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list mime_type $mime_type ] \
    ] content_type unregister_mime_type]
}


ad_proc -public content::type::unregister_relation_type {
    -content_type:required
    -target_type:required
    {-relation_tag ""}
} {
    @param content_type
    @param target_type
    @param relation_tag
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list target_type $target_type ] \
        [list relation_tag $relation_tag ] \
    ] content_type unregister_relation_type]
}


ad_proc -public content::type::unregister_template {
    {-content_type ""}
    -template_id:required
    {-use_context ""}
} {
    @param content_type
    @param template_id
    @param use_context
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list template_id $template_id ] \
        [list use_context $use_context ] \
    ] content_type unregister_template]
}


