# 

ad_library {
    
    Procedures for content types
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-09
    @arch-tag: 4a8a3652-fd5d-49aa-86fc-fade683f06ce
    @cvs-id $Id$
}

namespace eval ::content::type {}

namespace eval ::content::type::attribute {}

ad_proc -public content::type::new {
    -content_type:required
    {-supertype "content_revision"}
    -pretty_name:required
    -pretty_plural:required
    -table_name:required
    -id_column:required
    {-name_method ""}
} {
    @param content_type
    @param supertype
    @param pretty_name
    @param pretty_plural
    @param table_name
    @param id_column
    @param name_method
    @return type_id
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

ad_proc -public content::type::delete {
    -content_type:required
    {-drop_children_p ""}
    {-drop_table_p ""}
    {-drop_objects_p "f"}
} {
    @param content_type
    @param drop_children_p
    @param drop_table_p
    @param drop_objets_p Drop the objects of this content type along with all entries in cr_items and cr_revisions. Will not be done by default.
} {
    if {$drop_objects_p eq "f"} {
	return [package_exec_plsql -var_list [list \
						  [list content_type $content_type ] \
						  [list drop_children_p $drop_children_p ] \
						  [list drop_table_p $drop_table_p ] \
						 ] content_type drop_type]
    } else {
	return [package_exec_plsql -var_list [list \
						  [list content_type $content_type ] \
						  [list drop_children_p $drop_children_p ] \
						  [list drop_table_p $drop_table_p ] \
						  [list drop_objects_p $drop_objects_p ] \
						 ] content_type drop_type]
    }
}

ad_proc -public content::type::attribute::new {
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
    @param column_spec Specification for column to pass to the
 database. Not optional if the column does not already exist in the table.

    @return attribute_id for created attribute
} {
    if {[db_type] eq "oracle"} {
	switch -- $column_spec {
	    text { set column_spec clob }
	    boolean { set column_spec "char(1)" }
	}
    } else {
	switch -- $column_spec {
	    clob { set column_spec text }
	}
    }

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



ad_proc -public content::type::attribute::delete {
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



ad_proc -public content::type::get_template {
    -content_type:required
    {-use_context "public"}
} {
    @param content_type
    @param use_context

    @return template_id
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

    @return t or f
} {
    return [package_exec_plsql -var_list [list \
        [list object_type $object_type ] \
    ] content_type is_content_type]
}


ad_proc -public content::type::refresh_view {
    -content_type:required
} {
    @param content_type

    Creates or replaces the view associated with the supplied content type. By convention,
    this view is called TYPEx .
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
    @return 0
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
    Associate a content_type with a mime_type (both params are strings, e.g. folder , application/pdf )
    @param content_type
    @param mime_type
    @return 0
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
    @return 0
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
    {-use_context "public"}
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
    -content_type:required
    {-use_context "public"}
} {
    Force all items of content_type to use a new template. This will also cause items of this content
    type with no template assigned to use the new template. Finally, sets new template as default for
    this type. (IS THIS RIGHT ???? ----------------- ??????? )

    @param template_id
    @param content_type
    @param use_context
} {
    return [package_exec_plsql -var_list [list \
        [list template_id $template_id ] \
        [list content_type $v_content_type ] \
        [list use_context $use_context ] \
    ] content_type rotate_template]
}


ad_proc -public content::type::set_default_template {
    -content_type:required
    -template_id:required
    {use_context "public"}
} {
    @param content_type
    @param template_id
    @param use_context
    @return 0
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
    @see content::type::register_child_type
    @return 0
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
    @see content::type::register_mime_type
    @return 0
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
    @see content::type::register_relation_type
    @return 0
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
    @see content::type::register_template
    @return 0
} {
    return [package_exec_plsql -var_list [list \
        [list content_type $content_type ] \
        [list template_id $template_id ] \
        [list use_context $use_context ] \
    ] content_type unregister_template]
}

ad_proc -public content::type::content_type_p {
    -content_type:required
    -mime_type:required
} {
    Checks if the mime_type is of the content_type, e.g if application/pdf is of content_type "image" (which it should not...)

    Cached

    @param content_type content type to check against
    @param mime_type mime type to check for
} {
    return [util_memoize [list content::type::content_type_p_not_cached -mime_type $mime_type -content_type $content_type]]
}

ad_proc -public content::type::content_type_p_not_cached {
    -content_type:required
    -mime_type:required
} {
    Checks if the mime_type is of the content_type, e.g if application/pdf is of content_type "image" (which it should not...)
    @param content_type content type to check against
    @param mime_type mime type to check for
} {
    return [db_string content_type_p "" -default 0]
}
