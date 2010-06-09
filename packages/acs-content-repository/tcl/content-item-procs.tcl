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
    {-package_id ""}
    {-creation_ip ""}
    {-item_subtype "content_item"}
    {-content_type "content_revision"}
    {-title ""}
    {-description ""}
    {-mime_type ""}
    {-nls_language ""}
    {-text ""}
    {-data ""}
    {-relation_tag ""}
    {-is_live "f"}
    {-storage_type "file"}
    {-attributes ""}
    {-tmp_filename ""}
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
    @param item_subtype
    @param content_type - content_revision or subtype of content_revision
    @param context_id - Context of the item. usually used in conjunction with permissions.
    @param package_id - Package ID of the object
    @param creation_user -
    @param creation_ip -
    @param creation_date - defaults to current date and time
    @param storage_type - file, lob, or text (postgresql only)
    @param locale -
    @param title - title of content_revision to be created
    @param description of content_revision to be created
    @param text - text of content revision to be created
    @param tmp_filename file containing content to be added to new revision. Caller is responsible to handle cleaning up the tmp file
    @param nls_language - ???
    @param data - ???
    @param attributes - A list of lists ofpairs of additional attributes and
    their values to pass to the constructor. Each pair is a list of two
     elements: key => value such as
    [list [list attribute value] [list attribute value]]

    @return item_id of the new content item

    @see content::symlink::new content::extlink::new content::folder::new
} {
    if {$creation_user eq ""} {
        set creation_user [ad_conn user_id]
    }

    if {$creation_ip eq ""} {
        set creation_ip [ad_conn peeraddr]
    }
    if {$package_id eq ""} {
        set package_id [ad_conn package_id]
    }

    set var_list [list]
    lappend var_list \
        [list name $name] \
        [list parent_id $parent_id ] \
        [list item_id $item_id ] \
        [list locale $locale ] \
        [list creation_date $creation_date ] \
        [list creation_user $creation_user ] \
        [list context_id $context_id ] \
        [list package_id $package_id ] \
        [list creation_ip $creation_ip ] \
        [list item_subtype $item_subtype ] \
        [list content_type $content_type ] \
        [list mime_type $mime_type ] \
        [list nls_language $nls_language ] \
        [list relation_tag $relation_tag ] \
        [list is_live $is_live ] \
        [list storage_type $storage_type]

    # we don't pass title, text, or data to content_item__new
    # because the magic revision creation of the pl/sql proc does
    # not create a proper subtype of content revision, also it
    # can't set attributes of an extended type
    
    # the content type is not the object type of the cr_item so we pass in
    # the cr_item subtype here and content_type as part of
    # var_list
    db_transaction {
        # An explict lock was necessary for PostgreSQL between 8.0 and
        # 8.2; left the following statement here for documentary purposes
        #
        # db_dml lock_objects "LOCK TABLE acs_objects IN SHARE ROW EXCLUSIVE MODE"

	set item_id [package_exec_plsql \
			 -var_list $var_list \
			 content_item new]
	# if we have attributes we pass in everything
	# and create a revision with all subtype attributes that were
	# passed in
	
	# since we can't rely on content_item__new to create a revision
	# we have to pass is_live to content::revision::new and
	# set the live revision there
	if {[exists_and_not_null title] \
            || [exists_and_not_null text] \
		|| [exists_and_not_null data] \
		|| [exists_and_not_null tmp_filename] \
		|| [llength $attributes]} {
	    content::revision::new \
		-item_id $item_id \
		-title $title \
		-description $description \
		-content $text \
		-mime_type $mime_type \
		-content_type $content_type \
		-is_live $is_live \
		-package_id $package_id \
		-creation_user $creation_user \
		-creation_ip $creation_ip \
		-creation_date $creation_date \
		-nls_language $nls_language \
		-tmp_filename $tmp_filename \
		-attributes $attributes
	}
    }    
    return $item_id
}

ad_proc -public ::content::item::delete {
    -item_id:required
} {
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28

    Delete a content item from the database. If the content item
    to delete has children content items referencing its parent
    via acs_objects.context_id then this proc will fail.

    @param item_id
} {
    return [package_exec_plsql \
                -var_list [list [list item_id $item_id]] \
                content_item del]
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
    return [package_exec_plsql \
                -var_list [list \
                               [list item_id $item_id] \
                               [list name $name]
                          ] \
                content_item edit_name]
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
    set var_list [list \
                      [list item_id $item_id] \
                      [list target_folder_id $target_folder_id] ]
    if {[exists_and_not_null name]} {
	lappend var_list [list name $name]
    }
    return [package_exec_plsql \
                -var_list $var_list \
                content_item move]
}

ad_proc -public ::content::item::get {
    -item_id:required
    {-revision "live"}
    {-array_name "content_item"}
} {
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-05-28

    @param item_id
    @param revision live, latest, or best (live if it exists, otherwise latest)
    @param array_name name of array to upvar content into
    @return upvars array_name containing all attributes of the content
    type except content
    @return returns 0 if item does not exists or 1 if query was sucessful

    @error
} {
    upvar $array_name local_array
    if {[lsearch {live latest} $revision] == -1} {
        error "content::item::get revision was '${revision}'. It must be 'live' or 'latest'"
    }
    set content_type [content_type -item_id $item_id]
    if {$content_type eq ""} {
        # content_type query was unsucessful, item does not exist
        return 0
    }
    if {"content_folder" eq $content_type} {
        return [db_0or1row get_item_folder "" -column_array local_array]
    }
    set table_name [db_string get_table_name "select table_name from acs_object_types where object_type=:content_type"]
    set table_name "${table_name}x"    
    # get attributes of the content_item use the content_typex view
    return [db_0or1row get_item "" -column_array local_array]
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

    foreach {attribute_list} $attributes {
	set attribute [lindex $attribute_list 0]
	set value [lindex $attribute_list 1]	
	if {[lsearch $valid_attributes $attribute] > -1}  {

	    # create local variable to use for binding

	    set $attribute $value
	    if {$update_text ne ""} {
		append update_text ","
	    }
	    append update_text " ${attribute} = :${attribute} "
	}
    }
    if {$update_text ne ""} {

	# we have valid attributes, update them

	set query_text "update cr_items set ${update_text} where item_id=:item_id"
	db_dml item_update $query_text
    }
}

ad_proc -public ::content::item::content_type {
    -item_id:required
} {
    @public get_content_type

    Retrieves the content type of the item. If the item does not exist,
    returns an empty string.

    @param  item_id   The item_id of the content item

    @return The content type of the item, or an empty string if no such
    item exists
} {
    return [package_exec_plsql \
		-var_list [list [list item_id $item_id]] \
		content_item get_content_type]
}





ad_proc -public content::item::get_content_type {
    -item_id:required
} {
    Retrieves the content type of the item. If the item does not exist,
    returns an empty string.

    @param  item_id   The item_id of the content item

    @return The content type of the item, or an empty string if no such
    item exists
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_item get_content_type]
}


ad_proc -public content::item::get_context {
    -item_id:required
} {
    @param item_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_item get_context]
}


ad_proc -public content::item::get_id {
    -item_path:required
    {-root_folder_id ""}
    {-resolve_index ""}
} {
  Looks up the item_path starting with the root folder and returns item_id for that
  content item or empty, if none exists

  @param item_path
  @param root_folder_id
  @param resolve_index

  @return The item_id of the found item, or the empty string on failure
} {
    return [package_exec_plsql -var_list [list \
        [list item_path $item_path ] \
        [list root_folder_id $root_folder_id ] \
        [list resolve_index $resolve_index ] \
    ] content_item get_id]
}

ad_proc -public content::item::get_best_revision {
    -item_id:required
} {
  Attempts to retrieve the live revision for the item. If no live revision
  exists, attempts to retrieve the latest revision. If the item has no
  revisions, returns an empty string.

  @param  item_id   The item_id of the content item
 
  @return The best revision_id for the item, or an empty string if no
          revisions exist

  @see content::revision::item_id
  @see content::item::get_live_revision 
  @see content::item::get_latest_revision
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_item get_best_revision]
}

ad_proc -public content::item::get_latest_revision {
    -item_id:required
} {
  Retrieves the latest revision for the item. If the item has no live
  revision, returns an empty string.
 
  @param  item_id   The item_id of the content item
 
  @return The latest revision_id for the item, or an empty string if no
          revisions exist

  @see content::revision::item_id
  @see content::item::get_best_revision
  @see content::item::get_live_revision 
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_item get_latest_revision]
}


ad_proc -public content::item::get_live_revision {
    -item_id:required
} {
  Retrieves the live revision for the item. If the item has no live
  revision, returns an empty string.
 
  @param  item_id   The item_id of the content item
 
  @return The live revision_id for the item, or an empty string if no
          live revision exists

  @see content::revision::item_id
  @see content::item::get_best_revision 
  @see content::item::get_latest_revision 
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_item get_live_revision]
}


ad_proc -public content::item::get_parent_folder {
    -item_id:required
} {
    @param item_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
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
        [list item_id $item_id ] \
        [list root_folder_id $root_folder_id ] \
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
        [list item_id $item_id ] \
        [list is_live $is_live ] \
    ] content_item get_publish_date]
}


ad_proc -public content::item::get_revision_count {
    -item_id:required
} {
    @param item_id

    @return NUMBER
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_item get_revision_count]
}


ad_proc -public content::item::get_root_folder {
    {-item_id ""}
} {
    @param item_id

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_item get_root_folder]
}


ad_proc -public content::item::get_template {
    -item_id:required
    -use_context:required
} {
  Retrieves the template which can be used to render the item. If there is
  a template registered directly to the item, returns the id of that template.
  Otherwise, returns the id of the default template registered to the item's
  content_type. Returns an empty string on failure.
 
  @param  item_id   The item_id
  @param  context   The context in which the template will be used (e.g. public)
 
  @return The template_id of the template which can be used to render the
    item, or an empty string on failure
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
        [list use_context $use_context ] \
    ] content_item get_template]
}


ad_proc -public content::item::get_title {
    -item_id:required
    {-is_live ""}
} {
  Get the title for the item. If a live revision for the item exists,
  use the live revision. Otherwise, use the latest revision.
 
  @param item_id    The item_id of the content item
  @param is_live
 
  @return The title of the item
 
  @see content::item::get_best_revision
  @see content::item::get_title
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
        [list is_live $is_live ] \
    ] content_item get_title]
}


ad_proc -public content::item::get_virtual_path {
    -item_id:required
    {-root_folder_id ""}
} {
  Retrieves the relative path to the item. The path is relative to the
  page root, and has no extension (Example: "/foo/bar/baz"). 
 
  @param  item_id         The item_id for the item, for which the path is computed
  @param  root_folder_id  Starts path resolution from this folder.
                          Defaults to the root of the sitemap (when null).

  @return The path to the item, or an empty string on failure
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
        [list root_folder_id $root_folder_id ] \
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
        [list item_id $item_id ] \
        [list folder_id $folder_id ] \
    ] content_item is_index_page]
}


ad_proc -public content::item::is_publishable {
    -item_id:required
} {

  Determine if the item is publishable. The item is publishable only
  if:
  <ul>
   <li>All child relations, as well as item relations, are satisfied
     (according to min_n and max_n)</li>
   <li>The workflow (if any) for the item is finished</li>
  </ul>
 
  @param  item_id   The item_id of the content item

  @see content::item::is_publishable
 
  @return    't' if the item is publishable, 'f' otherwise
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_item is_publishable]
}


ad_proc -public content::item::is_published {
    -item_id:required
} {
    @param item_id

    @return CHAR
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
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
        [list object_type $object_type ] \
        [list supertype $supertype ] \
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
        [list item_id $item_id ] \
        [list content_type $content_type ] \
        [list relation_tag $relation_tag ] \
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
        [list item_id $item_id ] \
        [list template_id $template_id ] \
        [list use_context $use_context ] \
    ] content_item register_template]
}


ad_proc -public content::item::relate {
    -item_id:required
    -object_id:required
    {-relation_tag ""}
    {-order_n ""}
    {-relation_type "cr_item_rel"}
} {
    @param item_id
    @param object_id
    @param relation_tag
    @param order_n
    @param relation_type

    @return NUMBER(38)
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
        [list object_id $object_id ] \
        [list relation_tag $relation_tag ] \
        [list order_n $order_n ] \
        [list relation_type $relation_type ] \
    ] content_item relate]
}


ad_proc -public content::item::set_live_revision {
    -revision_id:required
    {-publish_status "ready"}
} {
    @param revision_id
    @param publish_status
} {
    return [package_exec_plsql -var_list [list \
        [list revision_id $revision_id ] \
        [list publish_status $publish_status ] \
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
        [list item_id $item_id ] \
        [list start_when $start_when ] \
        [list end_when $end_when ] \
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
        [list item_id $item_id ] \
        [list template_id $template_id ] \
        [list use_context $use_context ] \
    ] content_item unregister_template]
}


ad_proc -public content::item::unrelate {
    -rel_id:required
} {
    @param rel_id
} {
    return [package_exec_plsql -var_list [list \
        [list rel_id $rel_id ] \
    ] content_item unrelate]
}


ad_proc -public content::item::unset_live_revision {
    -item_id:required
} {
    @param item_id
} {
    return [package_exec_plsql -var_list [list \
        [list item_id $item_id ] \
    ] content_item unset_live_revision]
}

ad_proc -public content::item::copy {
    -item_id:required
    -target_folder_id:required
    {-creation_user ""}
    {-creation_ip ""}
    {-name ""}
} {
    @author Jun Yamog
    @creation-date 2004-06-27

    copy a content item to a new content item

    @param item_id - item_id of the content to be copied from. source content item
    @param target_folder_id - destination folder where the new content item is be passed
    @param creation_user - 
    @param creation_ip -
    @param name - the name of the new item, useful if you are copying in the same folder.

    @return item_id of the new copied item
} {
    return [package_exec_plsql \
                -var_list [list \
                               [list item_id $item_id] \
                               [list target_folder_id $target_folder_id] \
                               [list creation_user $creation_user] \
                               [list creation_ip $creation_ip] \
                               [list name $name]] \
                           content_item copy]
}

ad_proc -public content::item::upload_file {
    {-upload_file:required}
    {-parent_id:required}
    {-package_id ""}
} {
    Store the file uploaded under the parent_id if a file was uploaded
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-21
    
    @param upload_file

    @param parent_id

    @return the revision_id of the generated item
    
    @error 
} {

    set filename [template::util::file::get_property filename $upload_file]
    if {$filename ne "" } {
	set tmp_filename [template::util::file::get_property tmp_filename $upload_file]
	set mime_type [template::util::file::get_property mime_type $upload_file]
	set tmp_size [file size $tmp_filename]
	set extension [file extension $filename]
	if {![exists_and_not_null title]} {

	    # maltes: The following regsub garbles the title and consequently the filename as well. 
	    # "info_c+w.zip" will become "info_c+"
	    # This is bad, first of all because a letter is missing entirely. Additionally 
	    # the title in itself should be the original filename, after all this is what
	    # the user uploaded, not something stripped of its extension.
	    # So I commented this out until someone can either fix the regsub but more importantly
	    # can explain why the title should not contain the extension.

            # DRB: removing the explicit "." isn't sufficient because the "." in the
            # extension also matches any char unless it is escaped.  Like Malte, I
            # see no reason to get rid of the extension in the title anyway ...

	    # regsub -all ".${extension}\$" $filename "" title
	    set title $filename
	}
	
	set existing_filenames [db_list get_parent_existing_filenames {}]
	set filename [util_text_to_url \
			  -text ${title} -existing_urls "$existing_filenames" -replacement "_"]

        set revision_id [cr_import_content \
			     -storage_type "file" -title $title -package_id $package_id $parent_id $tmp_filename $tmp_size $mime_type $filename]

	content::item::set_live_revision -revision_id $revision_id

	return $revision_id
    } 
}

ad_proc -public content::item::get_id_by_name {
    {-name:required}
    {-parent_id:required}
} {
    Returns The item_id of the a content item with the passed in name

    @param name Name of the content item
    @param parent_id Parent_id of the content item

    @return The item_id belonging to the name, empty string if no item_id was found
} {
    return [db_string get_item_id_by_name {} -default ""]
}

#
#
#

ad_proc -public ::content::item::get_publish_status { 
    -item_id:required
} {
  Get the publish status of the item. The publish status will be one of
  the following: 
  <ul>
    <li><tt>production</tt> - The item is still in production. The workflow
      (if any) is not finished, and the item has no live revision.</li>
    <li><tt>ready</tt> - The item is ready for publishing</li> 
    <li><tt>live</tt> - The item has been published</li>
    <li><tt>expired</tt> - The item has been published in the past, but 
     its publication has expired</li>
  </ul>
 
  @param item_id  The item_id of the content item
 
  @return The publish status of the item, or the empty string on failure
 
  @see proc content::item::is_publishable

} {

  set publish_status [db_string gps_get_publish_status \
                          "select publish_status from cr_items where item_id = :item_id"]

  return $publish_status
}