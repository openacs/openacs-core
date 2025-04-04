ad_library {

    Provides a collection of deprecated procs to provide backward
    compatibility for sites who have not yet removed calls to the
    deprecated functions.

    In order to skip loading of deprecated code, use the following
    snippet in your config file

        ns_section ns/server/${server}/acs
            ns_param WithDeprecatedCode 0

    @cvs-id $Id$
}

if {![ad_with_deprecated_code_p]} {
    ns_log notice "deprecated-procs: skip deprecated code"
    return
}
ns_log notice "deprecated-procs include deprecated code"


##################################################################################
#
# From keyword-procs.tcl
#
##################################################################################

namespace eval cr {}
namespace eval cr::keyword {}

ad_proc -public -deprecated cr::keyword::new {
    {-heading:required}
    {-description ""}
    {-parent_id ""}
    {-keyword_id ""}
    {-object_type "content_keyword"}
    {-package_id ""}
} {
    Create a new keyword
    @see content::keyword::new
} {
    set user_id [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]

    if {$package_id eq ""} {
        set package_id [ad_conn package_id]
    }

    set keyword_id [db_exec_plsql content_keyword_new {}]

    return $keyword_id
}

ad_proc -public -deprecated cr::keyword::delete {
    {-keyword_id:required}
} {
    Delete a keyword.

    @author Peter Marklund
    @see content::keyword::delete
} {
    db_exec_plsql delete_keyword {}
}

ad_proc -public -deprecated cr::keyword::set_heading {
    {-keyword_id:required}
    {-heading:required}
} {
    Update a keyword heading
    @see content::keyword::set_heading
} {
    db_exec_plsql set_heading {}
}

ad_proc -public -deprecated cr::keyword::get_keyword_id {
    {-parent_id:required}
    {-heading:required}
} {
    Get the keyword with the given heading under the given parent.
    Returns the empty string if none exists.

    @see content::keyword::get_keyword_id
} {
    return [content::keyword::get_keyword_id -parent_id $parent_id -heading $heading]
}

ad_proc -public -deprecated cr::keyword::item_unassign {
    {-keyword_id:required}
    {-item_id:required}
} {
    Unassign a single keyword from a content item.

    Returns the supplied item_id for convenience.
    @see content::keyword::item_unassign
} {
    return [content::keyword::item_unassign -keyword_id $keyword_id -item_id $item_id]
}

ad_proc -deprecated -public cr::keyword::item_unassign_children {
    {-item_id:required}
    {-parent_id:required}
} {
    Unassign all the keywords attached to a content item
    that are children of keyword parent_id.

    @return the supplied item_id for convenience.
    @see content::keyword::item_unassign_children
} {
    return [content::keyword::item_unassign_children -item_id $item_id -parent_id $parent_id]
}

ad_proc -public -deprecated cr::keyword::item_assign {
    {-item_id:required}
    {-keyword_id:required}
    {-singular:boolean}
} {
    Assign one or more keywords to a content_item.

    @param singular   If singular is specified, then any keywords with the same parent_id as this keyword_id
                      will first be unassigned.

    @param keyword_id A list of keywords to assign.

    @return the supplied item_id for convenience.
    @see content::keyword::item_assign
} {
    # First, unassign for the parents of each/all
    if {$singular_p} {
        foreach keyword $keyword_id {
            set parent_id [db_string get_parent_id {
                select parent_id
                from cr_keywords
                where keyword_id = :keyword
            }]
            item_unassign_children -item_id $item_id -parent_id $parent_id
        }
    }

    # Now assign for each/all
    foreach keyword $keyword_id {
        db_exec_plsql keyword_assign {}
    }

    return $item_id
}


ad_proc -public -deprecated cr::keyword::item_get_assigned {
    {-item_id:required}
    {-parent_id}
} {
    Returns a list of all keywords assigned to the given cr_item.

    If parent_id is supplied, only keywords that are children of
    parent_id are listed.

    @see content::keyword::item_get_assigned
} {

    if {[info exists parent_id]} {
        set keyword_list [content::keyword::item_get_assigned -parent_id $parent_id -item_id $item_id]
    } else {
        set keyword_list [content::keyword::item_get_assigned -item_id $item_id]
    }

    return $keyword_list
}

ad_proc -deprecated -public cr::keyword::get_options_flat {
    {-parent_id ""}
} {
    Returns a flat options list of the keywords with the given parent_id.

    @see content::keyword::get_options_flat
} {
    return [content::keyword::get_options_flat -parent_id $parent_id]
}

ad_proc -public -deprecated cr::keyword::get_children {
    {-parent_id ""}
} {
    Returns the ids of the keywords having the given parent_id. Returns
    an empty list if there are no children.

    @author Peter Marklund
    @see content::keyword::get_children
} {
    return [content::keyword::get_children -parent_id $parent_id]
}

##################################################################################
#
# From symlink-procs.tcl
#
##################################################################################
namespace eval content_symlink {}

ad_proc -deprecated content_symlink::new {
    {-symlink_id ""}
    -target_id:required
    -parent_id:required
    {-name ""}
    {-label ""}
    {-package_id ""}
} {

    Create a new internal link.

    @param symlink_id Optional pre-assigned object_id for the link
    @param target_id The item_id of the target of the link
    @param parent_id The folder that will contain this symlink
    @param name Name to assign the object (defaults to the name of the target item)
    @param label Label for the symlink (defaults to the URL)
    @param package_id Package Id of the package that created the link
    @see content::symlink::new

} {

    set creation_user [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]

    if {$package_id eq ""} {
        set package_id [ad_conn package_id]
    }

    return [db_exec_plsql symlink_new {}]

}

ad_proc -deprecated content_symlink::edit {
    -symlink_id:required
    -target_id:required
    -label:required
} {

    Edit an existing internal link.  The parameters are required because it
    is assumed that the caller will be pulling the existing values out of
    the database before editing them.

    @param symlink_id Optional pre-assigned object_id for the link
    @param target_id The target item_id of the link
    @param label Label for the symlink (defaults to the target_id item title)

} {

    set modifying_user [ad_conn user_id]
    set modifying_ip [ad_conn peeraddr]

    db_transaction {
        db_dml symlink_update_object {}
        db_dml symlink_update_symlink {}
    }

}

ad_proc -deprecated content_symlink::delete {
    -symlink_id:required
} {

    Delete an external link.

    @param symlink_id  The object id of the link to delete
    @see content::symlink::delete

} {
    db_exec_plsql symlink_delete {}
}

ad_proc -deprecated content_symlink::symlink_p {
    -item_id:required
} {

    Returns true if the given item is a symlink

    @param item_id  The object id of the item to check.
    @see content::symlink::is_symlink

} {
    return [db_string symlink_check {}]
}

ad_proc content_symlink::symlink_name {
    -item_id:required
} {

    Returns the name of an symlink

    @param item_id  The object id of the item to check.

} {
    return [db_string symlink_name {}]
}

ad_proc -public -deprecated content_symlink::resolve {
        -item_id:required
} {
        @param item_id item_id of content_symlink item to resolve

        @return item_id of symlink target
        @see content::symlink::resolve
} {

        return [db_exec_plsql resolve_symlink ""]

}

ad_proc -public -deprecated content_symlink::resolve_content_type {
        -item_id:required
} {

        @param item_id item_id of symlink

        @return content_type of target item
        @see content::symlink::resolve_content_type

} {

        return [db_exec_plsql resolve_content_type ""]

}

##################################################################################
#
# From item-procs.tcl
#
##################################################################################

##########################################
#
# Procs for accessing content item properties

# @namespace item
#
# The item commands allow easy access to properties of the
# content_item object. In the future, a unified API for caching
# item properties will be developed here.

# @see namespace publish

namespace eval item {}

ad_proc -public -deprecated item::get_content {
    {-revision_id ""}
    {-array:required}
    {-item_id ""}
} {

  @public get_revision_content

  Create a onerow datasource called content in the calling frame
  which contains all attributes for the revision (including inherited
  ones).<p>
  The datasource will contain a column called "text", representing the
  main content (blob) of the revision, but only if the revision has a
  textual mime-type.

  @param revision_id The revision whose attributes are to be retrieved

  @option item_id The item_id of the
    corresponding item. You can provide this as an optimization.
    If you don't provide revision_id, you must provide item_id,
    and the item must have a live revision.

  @return 1 on success (and set the array in the calling frame),
    0 on failure

  @see content::item::get_content

} {
    upvar 1 $array content

    if { $item_id eq "" } {
        set item_id [::content::revision::item_id -revision_id  $revision_id]
        if { $item_id eq "" } {
            ns_log notice "item::get_content: no such revision: $revision_id"
            return 0
        }
    } elseif { $revision_id eq "" } {
        set revision_id [::content::item::get_live_revision -item_id $item_id]
    }
    if { $revision_id eq "" } {
        error "You must supply revision_id, or the item must have a live revision."
    }

    return [item::get_revision_content $revision_id $item_id]
}

ad_proc -public -deprecated item::content_is_null { revision_id } {

  @public content_is_null

  Determines if the content for the revision is null (not mereley
  zero-length)
  @param revision_id The revision id

  @return 1 if the content is null, 0 otherwise

  @see content::item::content_is_null

} {
    set content_test [db_string cin_get_content ""]

    return [template::util::is_nil content_test]
}

ad_proc -public -deprecated item::get_revision_content { revision_id args } {

  @public get_revision_content

  Create a onerow datasource called content in the calling frame
  which contains all attributes for the revision (including inherited
  ones).<p>
  The datasource will contain a column called "text", representing the
  main content (blob) of the revision, but only if the revision has a
  textual mime-type.

  @param revision_id The revision whose attributes are to be retrieved

  @option item_id  {default <i>auto-generated</i>} The item_id of the
    corresponding item.

  @return 1 on success (and create a content array in the calling frame),
    0 on failure

  @see content::item::get_revision_content

} {

  template::util::get_opts $args

  if { ![info exists opts(item_id)] } {
    # Get the item id
    set item_id [::content::revision::item_id -revision_id $revision_id]

    if { [template::util::is_nil item_id] } {
      ns_log warning "item::get_revision_content: No such revision: $revision_id"
      return 0
    }
  } else {
    set item_id $opts(item_id)
  }

  # Get the mime type, decide if we want the text
  content::item::get -item_id $item_id -array_name item_info

  if { [info exists item_info(mime_type)]
       && $item_info(mime_type) ne ""
       && [string match "text/*" $item_info(mime_type)]
   } {
      set text_sql [db_map grc_get_all_content_1]
  } else {
      set text_sql ""
  }

  # Get the content type
  set content_type $item_info(content_type)

  # Get the table name
  set table_name [db_string grc_get_table_names ""]

  upvar content content

  # Get (all) the content (note this is really dependent on file type)
  db_0or1row grc_get_all_content "" -column_array content

  if { ![array exists content] } {
    ns_log warning "item::get_revision_content: No data found for item $item_id, revision $revision_id"
    return 0
  }

  return 1
}


ad_proc -public -deprecated item::content_methods_by_type { content_type args } {

  @public content_methods_by_type

  Determines all the valid content methods for instantiating
  a content type.
  Possible choices are text_entry, file_upload, no_content and
  xml_import. Currently, this proc merely removes the text_entry
  method if the item does not have a text mime type registered to
  it. In the future, a more sophisticated mechanism will be
  implemented.

  @param   content_type  The content type

  @option  get_labels    Return not just a list of types,
    but a list of name-value pairs, as in the -options
    ATS switch for form widgets

  @return A Tcl list of all possible content methods
  @see content::item::content_methods_by_type

} {

  template::util::get_opts $args

  set types [db_list cmbt_get_content_mime_types ""]

  set need_text [expr {[llength $types] > 0}]

  if { [info exists opts(get_labels)] } {
    set methods [list \
      [list "No Content" no_content] \
      [list "File Upload" file_upload]]

    if { $need_text } {
      lappend methods [list "Text Entry" text_entry]
    }

    lappend methods [list "XML Import" xml_import]
  } else {
    set methods [list no_content file_upload]
    if { $need_text } {
      lappend methods text_entry
    }
    lappend methods xml_import
  }

  return $methods
}



ad_proc -public -deprecated item::get_mime_info { revision_id {datasource_ref mime_info} } {

  @public get_mime_info

  Creates a onerow datasource in the calling frame which holds the
  mime_type and file_extension of the specified revision. If the
  revision does not exist, does not create the datasource.

  @param  revision_id     The revision id
  @param  datasource_ref  {default mime_info} The name of the
    datasource to be created. The datasource  will have two columns,
    mime_type and file_extension.

  return    1 (one) if the revision exists, 0 (zero) otherwise.
  @see proc content::item::get

} {
    set sql [db_map gmi_get_mime_info]

    return [uplevel "db_0or1row ignore \"$sql\" -column_array $datasource_ref"]
}

ad_proc -public -deprecated item::get_extended_url { item_id args } {

  Retrieves the relative URL of the item with a file extension based
  on the item's mime_type (Example: "/foo/bar/baz.html").

  @param  item_id   The item id

  @option template_extension   Signifies that the file extension should
      be retrieved using the mime_type of the template assigned to
      the item, not from the item itself. The live revision of the
      template is used. If there is no template which could be used to
      render the item, or if the template has no live revision, the
      extension defaults to ".html"

  @option revision_id {default the live revision} Specifies the
      revision_id which will be used to retrieve the item's mime_type.
      This option is ignored if the -template_extension
      option is specified.

  @return The relative URL of the item with the appropriate file extension
          or an empty string on failure
  @see proc item::get_url
  @see proc item::get_mime_info
  @see proc item::get_template_id

} {

  set item_url [get_url $item_id]

  if { [template::util::is_nil item_url] } {
    ns_log warning "item::get_extended_url: No item URL found for content item $item_id"
    return ""
  }

  template::util::get_opts $args

  # Get full path
  set file_url [ns_normalizepath "/$item_url"]

  # Determine file extension
  if { [info exists opts(template_extension)] } {

    set file_extension "html"

    # Use template mime type
    set template_id [get_template_id $item_id]

    if { ![template::util::is_nil template_id] } {
      # Get extension from the template mime type
      set template_revision_id [::content::item::get_best_revision -item_id $template_id]

      if { ![template::util::is_nil template_revision_id] } {
        get_mime_info $template_revision_id mime_info

        if { [info exists mime_info(file_extension)] } {
          set file_extension $mime_info(file_extension)
        }
      }

    }
  } else {
    # Use item mime type if template extension does not exist

    # Determine live revision, if none specified
    if { ![info exists opts(revision_id)] } {
      set revision_id [::content::item::get_live_revision -item_id $item_id]

      if { [template::util::is_nil revision_id] } {
        ns_log warning "item::get_best_revision: No live revision for content item $item_id"
        return ""
      }

    } else {
      set revision_id $opts(revision_id)
    }

    get_mime_info $revision_id mime_info
    if { [info exists mime_info(file_extension)] } {
        set file_extension $mime_info(file_extension)
    } else {
        set file_extension "html"
    }
  }

  append file_url ".$file_extension"

  return $file_url
}

#######################################################
#
# the following have no counter parts in content::item::*
# but use no direct sql calls.
#
#######################################################
ad_proc -public -deprecated item::get_element {
    {-item_id:required}
    {-element:required}
} {
    Return the value of a single element (attribute) of a content
    item.

    @param item_id The id of the item to get element value for
    @param element The name (column name) of the element. See
                   item::get for valid element names.
    @see content::item::get
} {
    ::content::item::get -item_id $item_id -array row
    return $row($element)
}

ad_proc -public -deprecated item::publish {
    {-item_id:required}
    {-revision_id ""}
} {
    Publish a content item. Updates the live_revision and publish_date attributes, and
    sets publish_status to live.

    @param item_id The id of the content item
    @param revision_id The id of the revision to publish. Defaults to the latest revision.

    @author Peter Marklund
    @see content::item::publish
} {
    ::content::item::unpublish -item_id $item_id -revision_id $revision_id
}

ad_proc -public -deprecated item::unpublish {
    {-item_id:required}
    {-publish_status "production"}
} {
    Unpublish a content item.

    @param item_id The id of the content item
    @param publish_status The publish_status to put the item in after unpublishing it.

    @author Peter Marklund
    @see content::item::unpublish
} {
  ::content::item::unpublish -item_id $item_id -publish_status $publish_status
}

#######################################################
#
# all the following procs are deprecated and do not have
# direct sql calls.
#
#######################################################

ad_proc -public -deprecated item::get_title { item_id } {

  @public get_title

  Get the title for the item. If a live revision for the item exists,
  use the live revision. Otherwise, use the latest revision.

  @param item_id The item id

  @return The title of the item

  @see item::get_best_revision
  @see content::item::get_title

} {
    return [::content::item::get_title -item_id $item_id]
}

ad_proc -public -deprecated item::get_publish_status { item_id } {

  @public get_publish_status

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

  @param item_id The item id

  @return The publish status of the item, or the empty string on failure

  @see proc item::is_publishable

} {

  return [::content::item::get_publish_status -item_id $item_id]
}

ad_proc -public -deprecated item::is_publishable { item_id } {

  Determine if the item is publishable. The item is publishable only
  if:
  <ul>
   <li>All child relations, as well as item relations, are satisfied
     (according to min_n and max_n)</li>
   <li>The workflow (if any) for the item is finished</li>
  </ul>

  @param  item_id   The item id

  @see content::item::is_publishable

  @return    1 if the item is publishable, 0 otherwise

} {
    return [string equal [::content::item::is_publishable -item_id $item_id] "t"]
}

ad_proc -public -deprecated item::get_content_type { item_id } {

  @public get_content_type

  Retrieves the content type of the item. If the item does not exist,
  returns an empty string.

  @param  item_id   The item id

  @return The content type of the item, or an empty string if no such
          item exists

  @see content::item::get_content_type

} {
    return [::content::item::get_content_type -item_id $item_id]
}

ad_proc -public -deprecated item::get_item_from_revision { revision_id } {

  @public get_item_from_revision

  Gets the item_id of the item to which the revision belongs.

  @param  revision_id   The revision id

  @return The item_id of the item to which this revision belongs
  @see content::item::get_live_revision
  @see content::revision::item_id

} {
    return [::content::revision::item_id -revision_id $revision_id]
}

ad_proc -public -deprecated item::get_id { url {root_folder ""}} {

  @public get_id

  Looks up the URL and gets the item id at that URL, if any.

  @param  url           The URL
  @param  root_folder   {default The Sitemap}
    The ID of the root folder to use for resolving the URL

  @return The item ID of the item at that URL, or the empty string
    on failure
  @see proc item::get_url
  @see content::item::get_id

} {

  # Strip off file extension
  set last [string last "." $url]
  if { $last > 0 } {
    set url [string range $url 0 $last-1]
  }

  if {$root_folder ne ""} {
    return [::content::item::get_id -item_path $url]
  } else {
    return [::content::item::get_id -item_path $url -root_folder_id $root_folder]
  }
}

ad_proc -public -deprecated item::get_template_id { item_id {context public} } {

  @public get_template_id

  Retrieves the template which can be used to render the item. If there is
  a template registered directly to the item, returns the id of that template.
  Otherwise, returns the id of the default template registered to the item's
  content_type. Returns an empty string on failure.

  @param  item_id   The item id
  @param  context   {default 'public'} The context in which the template
   will be used.

  @return The template_id of the template which can be used to render the
    item, or an empty string on failure

  @see proc item::get_template_url
  @see content::item::get_template

} {
  return [::content::item::get_template -item_id $item_id -use_context $context]
}

ad_proc -public -deprecated item::get_template_url { item_id {context public} } {

  @public get_template_url

  Retrieves the relative URL of the template which can be used to
  render the item. The URL is relative to the TemplateRoot as it is
  specified in the ini file.

  @param  item_id   The item id
  @param  context   {default 'public'} The context in which
    the template will be used.

  @return The template_id of the template which can be used to render the
    item, or an empty string on failure

  @see proc item::get_template_id
  @see content::item::get_path

} {

  set template_id [::content::item::get_template -item_id $item_id -use_context $context]

  if { $template_id eq "" } {
    return ""
  }

  return [::content::item::get_virtual_path -item_id $template_id]
}

ad_proc -public -deprecated item::get_url {
    {-root_folder_id "null"}
    item_id
} {

  @public get_url

  Retrieves the relative URL stub to the item. The URL is relative to the
  page root, and has no extension (Example: "/foo/bar/baz").

  @param  item_id         The item id
  @param  root_folder_id  Starts path resolution from this folder.
                          Defaults to the root of the sitemap (when null).

  @return The relative URL to the item, or an empty string on failure
  @see proc item::get_extended_url
  @see content::item::get_virtual_path

} {

  if {$root_folder_id eq "null"} {
    return [::content::item::get_virtual_path -item_id $item_id]
  } else {
    return [::content::item::get_virtual_path -item_id $item_id -root_folder_id $root_folder_id]
  }

}

ad_proc -public -deprecated item::get_best_revision { item_id } {

  @public get_best_revision

  Attempts to retrieve the live revision for the item. If no live revision
  exists, attempts to retrieve the latest revision. If the item has no
  revisions, returns an empty string.

  @param  item_id   The item id

  @return The best revision id for the item, or an empty string if no
          revisions exist
  @see content::item::get_live_revision
  @see content::item::get_latest_revision
  @see content::item::get_best_revision
} {
  return [::content::item::get_best_revision -item_id $item_id]
}

ad_proc -public -deprecated item::get_latest_revision { item_id } {

  Retrieves the latest revision for the item. If the item has no live
  revision, returns an empty string.

  @param  item_id   The item id

  @return The latest revision id for the item, or an empty string if no
          revisions exist

  @see content::item::get_live_revision
  @see content::item::get_latest_revision
  @see content::item::get_best_revision
} {
  return [::content::item::get_latest_revision -item_id $item_id]
}

ad_proc -public -deprecated item::get_live_revision { item_id } {

  @public get_live_revision

  Retrieves the live revision for the item. If the item has no live
  revision, returns an empty string.

  @param  item_id   The item id

  @return The live revision id for the item, or an empty string if no
          live revision exists
  @see item::get_best_revision
  @see content::revision::item_id
  @see content::item::get_live_revision

} {
  return [::content::item::get_live_revision -item_id $item_id]
}

ad_proc -public -deprecated item::get_type { item_id } {
  Returns the content type of the specified item, or empty string
  if the item_id is invalid
  @see content::item::get_content_type

} {
  return [::content::item::get_content_type -item_id $item_id]
}

ad_proc -deprecated item::copy {
    -item_id:required
    -target_folder_id:required
} {

    Copy the given item.

    @param item_id The content item to copy
    @param target_folder_id The folder which will hold the new copy
    @see content::item::copy

} {
    ::content::item::copy -item_id $item_id \
        -target_folder_id $target_folder_id \
        -creation_user [ad_conn user_id] \
        -creation_ip [ad_conn peeraddr]
}

ad_proc -public -deprecated item::get {
    {-item_id:required}
    {-array:required}
} {
    Get information about a content item.

    @param item_id The id of the item to get info for
    @param array The name of the array to populate with values.
                 The keys are: ITEM_ID, PARENT_ID, NAME, LOCALE,
                 LIVE_REVISION, LATEST_REVISION, PUBLISH_STATUS,
                 CONTENT_TYPE, STORAGE_TYPE, STORAGE_AREA_KEY,
                 ARCHIVE_DATE, PACKAGE_ID

    @author Peter Marklund
    @see content::item::get
} {
    upvar $array row

    ::content::item::get -item_id $item_id -array row
}

ad_proc -public -deprecated item::delete {
    {-item_id:required}
} {
    Delete a content item from the database. If the content item
    to delete has children content items referencing its parent
    via acs_objects.context_id then this proc will fail.

    @author Peter Marklund
    @see content::item::delete
} {
    ::content::item::delete -item_id $item_id
}

##################################################################################
#
# From extlink-procs.tcl
#
##################################################################################

namespace eval content_extlink {}

ad_proc -deprecated content_extlink::new {
    {-extlink_id ""}
    -url:required
    -parent_id:required
    {-name ""}
    {-label ""}
    {-description ""}
    {-package_id ""}
} {

    Create a new external link.

    @see content::extlink::new

    @param extlink_id Optional pre-assigned object_id for the link
    @param url The URL of the external resource
    @param parent_id The folder that will contain this extlink
    @param name Name to assign the object (defaults to "link extlink_id")
    @param label Label for the extlink (defaults to the URL)
    @param description An extended description of the link (defaults to NULL)
    @param package_id Package Id of the package that created the link

} {

    set creation_user [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]

    if {$package_id eq ""} {
        set package_id [ad_conn package_id]
    }

    return [db_exec_plsql extlink_new {}]

}

ad_proc -deprecated content_extlink::edit {
    -extlink_id:required
    -url:required
    -label:required
    -description:required
} {

    Edit an existing external link.  The parameters are required because it
    is assumed that the caller will be pulling the existing values out of
    the database before editing them.

    @param extlink_id Optional pre-assigned object_id for the link
    @param url The URL of the external resource
    @param label Label for the extlink (defaults to the URL)
    @param description An extended description of the link (defaults to NULL)

    @see content::extlink::edit
} {

    set modifying_user [ad_conn user_id]
    set modifying_ip [ad_conn peeraddr]

    db_transaction {
        db_dml extlink_update_object {}
        db_dml extlink_update_extlink {}
    }
}

ad_proc -deprecated content_extlink::delete {
    -extlink_id:required
} {

    Delete an external link.
    @see content::extlink::delete

    @param extlink_id  The object id of the link to delete

} {
    db_exec_plsql extlink_delete {}
}

ad_proc -deprecated content_extlink::extlink_p {
    -item_id:required
} {

    Returns true if the given item is an external link.

    @see content::extlink::is_extlink
    @param item_id  The object id of the item to check.

} {
    return [db_string extlink_check {}]
}

ad_proc -deprecated content_extlink::extlink_name {
    -item_id:required
} {

    Returns the name of an extlink

    @param item_id  The object id of the item to check.

    @see content::extlink::name
} {
    return [db_string extlink_name {}]
}


##################################################################################
#
# From filter-procs.tcl
#
##################################################################################

namespace eval content {}

ad_proc -deprecated -public content::get_folder_labels { { varname "folders" } } {
    Set a data source in the calling frame with folder URL and label
    Useful for generating a context bar.

    This function returns a hard-coded name for the root level. One should use for path generation for items the
    appropriate API, such as e.g. content::item::get_virtual_path

    @see content::item::get_virtual_path
} {

    variable item_id

    # this repeats the query used to look up the item in the first place
    # but there does not seem to be a clear way around this

    # build the folder URL out as we iterate over the query
    set query [db_map get_url]
    db_multirow -extend {url} $varname ignore_get_url $query  {
        append url "$name/"
    }
}


##################################################################################
#
# From folder-procs.tcl
#
##################################################################################

namespace eval folder {}

ad_proc -public -deprecated folder::delete {
    {-folder_id:required}
} {
    Deprecated. See content::folder::delete instead.
    Delete a content folder. If the folder
    to delete has children content items referencing it
    via acs_objects.context_id then this proc will fail.

    @author Peter Marklund
    @see content::folder::delete
} {
    db_exec_plsql delete_folder {}
}

##################################################################################
#
# From search-procs.tcl
#
##################################################################################
ad_proc -deprecated content_search__datasource {
    object_id
} {
    Provides data source for search interface.  Used to access content items
    after search.

    DEPRECATED: does not comply with OpenACS naming convention

    @see content_search::datasource
} {
    return [content_search::datasource $object_id]
}

ad_proc -deprecated content_search__url {
    object_id
} {
    Provides a URL for linking to content items which show up in a search
    result set.

    DEPRECATED: does not comply with OpenACS naming convention

    @see content_search::url
} {
    return [content_search::url $object_id]
}

ad_proc -deprecated image_search__datasource {
    object_id
} {
    Provides data source for search interface.  Used to access content items
    after search.

    DEPRECATED: does not comply with OpenACS naming convention

    @see image_search::datasource
} {
    return [image_search::datasource $object_id]
}

ad_proc -deprecated image_search__url {
    object_id
} {
    Provides a URL for linking to content items which show up in a search
    result set.

    DEPRECATED: does not comply with OpenACS naming convention

    @see image_search::url
} {
    return [image_search::url $object_id]
}

ad_proc -deprecated template_search__datasource {
    object_id
} {
    Provides data source for search interface.  Used to access content items
    after search.

    DEPRECATED: does not comply with OpenACS naming convention

    @see template_search::datasource
} {
    return [template_search::datasource $object_id]
}

ad_proc -deprecated template_search__url {
    object_id
} {
    Provides a URL for linking to content items which show up in a search
    result set.

    DEPRECATED: does not comply with OpenACS naming convention

    @see template_search::url
} {
    return [template_search::url $object_id]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
