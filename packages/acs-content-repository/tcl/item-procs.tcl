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

ad_proc -public item::get_title { item_id } {

  @public get_title
 
  Get the title for the item. If a live revision for the item exists,
  use the live revision. Otherwise, use the latest revision.
 
  @param item_id The item id
 
  @return The title of the item
 
  @see proc item::get_best_revision

} {

    set title [db_string gt_get_title ""]

    return $title
}

ad_proc -public item::get_publish_status { item_id } {

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

  set publish_status [db_string gps_get_publish_status ""]

  return $publish_status
}

ad_proc -public item::is_publishable { item_id } {

  @public is_publishable
 
  Determine if the item is publishable. The item is publishable only
  if:
  <ul>
   <li>All child relations, as well as item relations, are satisfied
     (according to min_n and max_n)</li>
   <li>The workflow (if any) for the item is finished</li>
  </ul>
 
  @param  item_id   The item id
 
  @return    1 if the item is publishable, 0 otherwise

} {
    set is_publishable [db_string ip_is_publishable_p ""]

    return [string equal $is_publishable t]
} 


ad_proc -public item::get_revision_content { revision_id args } {

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
 
  @see proc item::get_mime_info 
  @see proc item::get_content_type

} {

  template::util::get_opts $args
 
  if { [template::util::is_nil opts(item_id)] } {
    # Get the item id
    set item_id [get_item_from_revision $revision_id]

    if { [template::util::is_nil item_id] } {
      ns_log warning "item::get_revision_content: No such revision: $reivision_id"
      return 0
    }  
  } else {
    set item_id $opts(item_id)
  }

  # Get the mime type, decide if we want the text
  get_mime_info $revision_id

  if { [exists_and_not_null mime_info(mime_type)] && \
           [string equal [lindex [split $mime_info(mime_type) "/"] 0] "text"] } {
      set text_sql [db_map grc_get_all_content_1]
  } else {
      set text_sql ""
  }
 
  # Get the content type
  set content_type [get_content_type $item_id]

  # Get the table name
  set table_name [acs_object_type::get_table_name -object_type $content_type]

  upvar content content

  # Get (all) the content (note this is really dependent on file type)
  db_0or1row grc_get_all_content "" -column_array content

  if { ![array exists content] } { 
    ns_log warning "item::get_revision_content: No data found for item $item_id, revision $revision_id"
    return 0
  }
  
  return 1
}

  
ad_proc -public item::content_methods_by_type { content_type args } {

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
 
  @return A TCL list of all possible content methods

} {
  
  template::util::get_opts $args

  set types [db_list cmbt_get_content_mime_types ""]

  set need_text [expr [llength $types] > 0]

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


ad_proc -public item::get_content_type { item_id } {

  @public get_content_type
 
  Retrieves the content type of tyhe item. If the item does not exist,
  returns an empty string.
 
  @param  item_id   The item id
 
  @return The content type of the item, or an empty string if no such
          item exists

} {

    set content_type [db_string gct_get_content_type ""]

    if { [info exists content_type] } {
        return $content_type
    } else {
        return ""
    }
}


ad_proc -public item::get_item_from_revision { revision_id } {

  @public get_item_from_revision
 
  Gets the item_id of the item to which the revision belongs.
 
  @param  revision_id   The revision id
 
  @return The item_id of the item to which this revision belongs
  @see proc item::get_live_revision 
  @see proc item::get_best_revision

} {
    set item_id [db_string gifr_get_one_revision ""]
    return $item_id
}


ad_proc -public item::get_id { url {root_folder ""}} {

  @public get_id
 
  Looks up the URL and gets the item id at that URL, if any.
 
  @param  url           The URL
  @param  root_folder   {default The Sitemap}
    The ID of the root folder to use for resolving the URL
 
  @return The item ID of the item at that URL, or the empty string
    on failure
  @see proc item::get_url

} {

  # Strip off file extension
  set last [string last "." $url]
  if { $last > 0 } {
    set url [string range $url 0 [expr $last - 1]]
  }

  if { ![template::util::is_nil root_folder] } {
    set root_sql ", :root_folder, 'f'"
  } else {
    set root_sql ", null, 'f'"
  }

  # Get the path
  set item_id [db_string id_get_item_id ""]

  if { [info exists item_id] } {
    return $item_id
  } else {
    return ""
  }
}


ad_proc -public item::content_is_null { revision_id } {

  @public content_is_null
 
  Determines if the content for the revision is null (not mereley
  zero-length)
  @param revision_id The revision id
 
  @return 1 if the content is null, 0 otherwise

} {
    set content_test [db_string cin_get_content ""]

    return [template::util::is_nil content_test]
}


ad_proc -public item::get_template_id { item_id {context public} } {

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

} {

    set template_id [db_string gti_get_template_id ""]

    if { [info exists template_id] } {
        return $template_id
    } else {
        return ""
    }
}


ad_proc -public item::get_template_url { item_id {context public} } {

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

} {

  set template_id [get_template_id $item_id $context]

  if { [template::util::is_nil template_id] } {
    return ""
  }

  return [get_url $template_id]
}
  

ad_proc -public item::get_url {
    {-root_folder_id "null"}
    item_id
} {

  @public get_url
 
  Retrieves the relative URL stub to th item. The URL is relative to the
  page root, and has no extension (Example: "/foo/bar/baz"). 
 
  @param  item_id         The item id
  @param  root_folder_id  Starts path resolution from this folder.
                          Defaults to the root of the sitemap (when null).

  @return The relative URL to the item, or an empty string on failure
  @see proc item::get_extended_url

} {

  # Get the path
    set item_path [db_string gu_get_path ""]

    if { [info exists item_path] } {
        return $item_path
    } else {
        return ""
    }
}


ad_proc -public item::get_live_revision { item_id } {

  @public get_live_revision
 
  Retrieves the live revision for the item. If the item has no live
  revision, returns an empty string.
 
  @param  item_id   The item id
 
  @return The live revision id for the item, or an empty string if no
          live revision exists
  @see proc item::get_best_revision 
  @see proc item::get_item_from_revision

} {

    set live_revision [db_string glr_get_live_revision "" -default ""]

    if { [template::util::is_nil live_revision] } {
        ns_log warning "item::get_live_revision: No live revision for item $item_id"
        return ""
    } else {
        return $live_revision
    }
}


ad_proc -public item::get_mime_info { revision_id {datasource_ref mime_info} } {

  @public get_mime_info
 
  Creates a onerow datasource in the calling frame which holds the
  mime_type and file_extension of the specified revision. If the
  revision does not exist, does not create the datasource.
 
  @param  revision_id     The revision id
  @param  datasource_ref  {default mime_info} The name of the
    datasource to be created. The datasource  will have two columns, 
    mime_type and file_extension.
 
  return    1 (one) if the revision exists, 0 (zero) otherwise.
  @see proc item::get_extended_url

} {
    set sql [db_map gmi_get_mime_info]

    return [uplevel "db_0or1row ignore \"$sql\" -column_array $datasource_ref"]
}


ad_proc -public item::get_best_revision { item_id } {

  @public get_best_revision
 
  Attempts to retrieve the live revision for the item. If no live revision
  exists, attempts to retrieve the latest revision. If the item has no
  revisions, returns an empty string.
 
  @param  item_id   The item id
 
  @return The best revision id for the item, or an empty string if no
          revisions exist
  @see proc item::get_live_revision 
  @see proc item::get_item_from_revision

} {
   
    return [db_string gbr_get_best_revision ""]
}


ad_proc -public item::get_extended_url { item_id args } {

  @public get_content_type
 
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
      set template_revision_id [get_best_revision $template_id]

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
    if { [template::util::is_nil opts(revision_id)] } {
      set revision_id [get_live_revision $item_id]

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

ad_proc -public item::get_type { item_id } {
  Returns the content type of the specified item, or empty string
  if the item_id is invalid
} {
  if { [db_0or1row get_content_type ""] } {
    return $content_type
  } else {
    return ""
  }
}

ad_proc item::copy {
    -item_id:required
    -target_folder_id:required
} {

    Copy the given item.

    @param item_id The content item to copy
    @param target_folder_id The folder which will hold the new copy

} {

    set creation_user [ad_conn user_id]
    set creation_ip [ad_conn peeraddr]

    db_exec_plsql copy_item {}

}

ad_proc -public item::get {
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
} {
    upvar $array row

    db_1row select_item_data {
        select *
        from cr_items
        where item_id = :item_id
    } -column_array row
}

ad_proc -public item::get_element {
    {-item_id:required}
    {-element:required}
} {
    Return the value of a single element (attribute) of a content
    item.

    @param item_id The id of the item to get element value for
    @param element The name (column name) of the element. See
                   item::get for valid element names.
} {
    get -item_id $item_id -array row
    return $row($element)
}

ad_proc -public item::get_content { 
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
 
  @see proc item::get_mime_info 
  @see proc item::get_content_type

} {
    upvar 1 $array content

    if { [empty_string_p $item_id] } {
        set item_id [get_item_from_revision $revision_id]
        if { [empty_string_p $item_id] } {
            ns_log notice "item::get_content: no such revision: $reivision_id"
            return 0
        }  
    } elseif { [empty_string_p $revision_id] } {
        set revision_id [item::get_live_revision $item_id]
    }
    if { [empty_string_p $revision_id] } {
        error "You must supply revision_id, or the item must have a live revision."
    }
    
    return [get_revision_content $revision_id $item_id]
}

  
ad_proc -public item::publish {
    {-item_id:required}
    {-revision_id ""}
} {
    Publish a content item. Updates the live_revision and publish_date attributes, and
    sets publish_status to live.

    @param item_id The id of the content item
    @param revision_id The id of the revision to publish. Defaults to the latest revision.

    @author Peter Marklund
} {
    if { [empty_string_p $revision_id] } {
        set revision_id [item::get_element -item_id $item_id -element latest_revision]
    }

    db_exec_plsql set_live { }
}

ad_proc -public item::unpublish {
    {-item_id:required}
    {-publish_status "production"}
} {
    Unpublish a content item.

    @param item_id The id of the content item
    @param publish_status The publish_status to put the item in after unpublishing it.

    @author Peter Marklund
} {

    db_exec_plsql unset_live {
    }

    db_dml update_publish_status {
    }
}
