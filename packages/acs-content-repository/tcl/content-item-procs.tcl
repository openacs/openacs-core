
ad_library {

    Tcl API for cr_items in the content repository

    @author Dave Bauer (dave@thedesignexperience.org)
    @author Jun Yamog
    @creation-date 2004-05-28
    @cvs-id $Id$
}

namespace eval ::content::item {}

ad_proc -public ::content::item::new {
    -name:required
    {-parent_id ""}
    {-item_id ""}
    {-locale ""}
    {-creation_date ""}
    {-creation_user ""}
    {-context_id ""}
    {-creation_ip ""}
    {-item_subtype ""}
    {-content_type "content_revision"}
    {-object_type "content_item"}
    {-title ""}
    {-description ""}
    {-mime_type ""}
    {-nls_language ""}
    {-text ""}
    {-data ""}
    {-relation_tag ""}
    {-is_live ""}
    {-storage_type ""}
    {-attributes ""}
} {
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28

    Create a new content item This proc creates versioned content
    items where content_type iscontent_revision or subtypes of content
    revision. There are procedures for each other base content
    item. This procdedure uses package_instantiate object. Under
    PostgreSQL the object_type new function must be registered with
    define_function_args.

    @param name
    @param item_id - item_id of this content_item. If this is not
    specified an item_id will be generated automatically
    @param parent_id - parent object of this content_item
    @param object_type - content_item or subtype of content_item
    @param content_type - content_revision or subtype of content_revision
    @param context_id -
    @param creation_user -
    @param creation_ip -
    @param creation_date - defaults to current date and time
    @param storage_type - file, lob, or text (postgresql only)
    @param locale -

    @param attributes - A list of pairs of additional attributes and their values to pass to the constructor. Each pair is a list of two elements: key => value

    @return item_id of the new content item

    @see content::symlink::new content::extlink::new content::folder::new
} {
    if {![string equal "" $attributes]} {
	set var_list $attributes
    } else {
	set var_list [list]
    }
    
    lappend var_list \
	name $name \
        parent_id $parent_id \
        item_id $item_id \
        locale $locale \
        creation_date $creation_date \
        creation_user $creation_user \
        context_id $context_id \
        creation_ip $creation_ip \
        item_subtype $item_subtype \
        content_type $content_type \
        title $title \
        description $description \
        mime_type $mime_type \
        nls_language $nls_language \
        text $text \
        data $data \
        relation_tag $relation_tag \
        is_live $is_live \
        storage_type $storage_type
	
    foreach var [list item_id name parent_id content_type context_id creation_date] {
	lappend var_list [list $var [set $var]]
    }

    # the content type is not the object type of the cr_item so we pass in
    # the cr_item subtype here and content_type as part of var_list

    set item_id [package_instantiate_object \
		     -creation_user $creation_user \
		     -creation_ip $creation_ip \
		     -var_list $var_list \
		     $object_type]
    return $item_id
}

ad_proc -public ::content::item::delete {
    -item_id:required
} {
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28

    Delete a content item
    @param item_id
} {
    set var_list [list [list item_id $item_id]]
    package_exec_plsql \
	-var_list $var_list \
	"content_item" "delete"
}

ad_proc -public ::content::item::rename {
    -item_id:required
    -name:required
} {
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28

    Rename a content item.
    @param item_id
    @param name
} {
    set var_list [list [list item_id $item_id] \
		      [list name $name]
		 ]
    package_exec_plsql \
	-var_list $var_list \
	"content_item" "rename"
}

ad_proc -public ::content::item::move {
    -item_id:required
    -target_folder_id:required
    {-name}
} {
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28

    @param item_id item to move
    @param new_parent_id new parent item
    @param name new name, allows move with rename
} {
    set var_list [list item_id $item_id target_folder_id $target_folder_id]
    if {[exists_and_not_null name]} {
	lappend var_list name $name
    }
    package_exec_plsql \
	-var_list [list item_id $item_id] \
	"content_item" "move"
}

ad_proc -public ::content::item::get {
    -item_id:required
    {-revision "live"}
    {-attributes ""}
} {
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28

    @param item_id
    @param revision live, latest, or best (live if it exists, otherwise latest)
    @param attributes A list of pairs of additional attributes and their values to get. Each pair is a list of two elements: key => value

    @return

    @error
} {

    # get attributes of the content_item use the content_typex view
}

ad_proc -public ::content::item::update {
    -item_id:required
    -attributes:required
} {
    Update standard non-versioned content item attributes (cr_items)
    Valid attributes: name parent_id latest_revision live_revision locale publish_status

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-06-04

    @param item_id item to update

    @param attributes A list of pairs of additional attributes and their values to get. Each pair is a list of two elements: key => value

    @return

    @error
} {

    # do not allow update of item_id, storage_location, storage_type,
    # content_type, or tree_sortkey

    set valid_attributes [list name parent_id latest_revision live_revision locale publish_status]

    set update_text ""

    foreach {attribute value} $attributes {
	if {[lsearch $valid_attributes $attribute] > -1}  {

	    # create local variable to use for binding

	    set $attribute $value
	    if {![string equal "" $update_text]} {
		append update_text ","
	    }
	    append update_text " ${attribute} = :${attribute} "
	}
    }
    if {![string equal "" $update_text]} {

	# we have valid attributes, update them

	set query_text "update cr_items set ${update_text}"
	db_dml item_update $query_text
    }
}

ad_proc -public ::content::item::content_type {
    -item_id:required
} {
    @public get_content_type

    Retrieves the content type of the item. If the item does not exist,
    returns an empty string.

    @param  item_id   The item id

    @return The content type of the item, or an empty string if no such
    item exists
} {
    return [package_exec_plsql \
		-var_list [list [list item_id $item_id]] \
		"content_item" "get_content_type"]
}


ad_proc -public content::item::get_best_revision {
    -item_id:required
} {
    @param item_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item get_best_revision]
}


ad_proc -public content::item::get_content_type {
    -item_id:required
} {
    @param item_id

    @return VARCHAR2(100)
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item get_content_type]
}


ad_proc -public content::item::get_context {
    -item_id:required
} {
    @param item_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item get_context]
}


ad_proc -public content::item::get_id {
    -item_path:required
    {-root_folder_id ""}
    {-resolve_index ""}
} {
    @param item_path
    @param root_folder_id
    @param resolve_index

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        item_path $item_path \
        root_folder_id $root_folder_id \
        resolve_index $resolve_index \
    ] content_item get_id]
}


ad_proc -public content::item::get_latest_revision {
    -item_id:required
} {
    @param item_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item get_latest_revision]
}


ad_proc -public content::item::get_live_revision {
    -item_id:required
} {
    @param item_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item get_live_revision]
}


ad_proc -public content::item::get_parent_folder {
    -item_id:required
} {
    @param item_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item get_parent_folder]
}


ad_proc -public content::item::get_path {
    -item_id:required
    {-root_folder_id ""}
} {
    @param item_id
    @param root_folder_id

    @return VARCHAR2
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        root_folder_id $root_folder_id \
    ] content_item get_path]
}


ad_proc -public content::item::get_publish_date {
    -item_id:required
    {-is_live ""}
} {
    @param item_id
    @param is_live

    @return DATE
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        is_live $is_live \
    ] content_item get_publish_date]
}


ad_proc -public content::item::get_revision_count {
    -item_id:required
} {
    @param item_id

    @return NUMBER
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item get_revision_count]
}


ad_proc -public content::item::get_root_folder {
    {-item_id ""}
} {
    @param item_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item get_root_folder]
}


ad_proc -public content::item::get_template {
    -item_id:required
    -use_context:required
} {
    @param item_id
    @param use_context

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        use_context $use_context \
    ] content_item get_template]
}


ad_proc -public content::item::get_title {
    -item_id:required
    {-is_live ""}
} {
    @param item_id
    @param is_live

    @return VARCHAR2(1000)
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        is_live $is_live \
    ] content_item get_title]
}


ad_proc -public content::item::get_virtual_path {
    -item_id:required
    {-root_folder_id ""}
} {
    @param item_id
    @param root_folder_id

    @return VARCHAR2
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        root_folder_id $root_folder_id \
    ] content_item get_virtual_path]
}


ad_proc -public content::item::is_index_page {
    -item_id:required
    -folder_id:required
} {
    @param item_id
    @param folder_id

    @return VARCHAR2
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        folder_id $folder_id \
    ] content_item is_index_page]
}


ad_proc -public content::item::is_publishable {
    -item_id:required
} {
    @param item_id

    @return CHAR
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item is_publishable]
}


ad_proc -public content::item::is_published {
    -item_id:required
} {
    @param item_id

    @return CHAR
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item is_published]
}


ad_proc -public content::item::is_subclass {
    -object_type:required
    -supertype:required
} {
    @param object_type
    @param supertype

    @return CHAR
} {
    return [package_exec_plsql -var_list [list \
        object_type $object_type \
        supertype $supertype \
    ] content_item is_subclass]
}


ad_proc -public content::item::is_valid_child {
    -item_id:required
    -content_type:required
    {-relation_tag ""}
} {
    @param item_id
    @param content_type
    @param relation_tag

    @return CHAR
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        content_type $content_type \
        relation_tag $relation_tag \
    ] content_item is_valid_child]
}


ad_proc -public content::item::register_template {
    -item_id:required
    -template_id:required
    -use_context:required
} {
    @param item_id
    @param template_id
    @param use_context
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        template_id $template_id \
        use_context $use_context \
    ] content_item register_template]
}


ad_proc -public content::item::relate {
    -item_id:required
    -object_id:required
    {-relation_tag ""}
    {-order_n ""}
    {-relation_type ""}
} {
    @param item_id
    @param object_id
    @param relation_tag
    @param order_n
    @param relation_type

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        object_id $object_id \
        relation_tag $relation_tag \
        order_n $order_n \
        relation_type $relation_type \
    ] content_item relate]
}


ad_proc -public content::item::set_live_revision {
    -revision_id:required
    {-publish_status ""}
} {
    @param revision_id
    @param publish_status
} {
    return [package_exec_plsql -var_list [list \
        revision_id $revision_id \
        publish_status $publish_status \
    ] content_item set_live_revision]
}


ad_proc -public content::item::set_release_period {
    -item_id:required
    {-start_when ""}
    {-end_when ""}
} {
    @param item_id
    @param start_when
    @param end_when
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        start_when $start_when \
        end_when $end_when \
    ] content_item set_release_period]
}


ad_proc -public content::item::unregister_template {
    -item_id:required
    {-template_id ""}
    {-use_context ""}
} {
    @param item_id
    @param template_id
    @param use_context
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
        template_id $template_id \
        use_context $use_context \
    ] content_item unregister_template]
}


ad_proc -public content::item::unrelate {
    -rel_id:required
} {
    @param rel_id
} {
    return [package_exec_plsql -var_list [list \
        rel_id $rel_id \
    ] content_item unrelate]
}


ad_proc -public content::item::unset_live_revision {
    -item_id:required
} {
    @param item_id
} {
    return [package_exec_plsql -var_list [list \
        item_id $item_id \
    ] content_item unset_live_revision]
}

