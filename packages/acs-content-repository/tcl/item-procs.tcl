namespace eval item {}


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
  

ad_proc -public item::get_url { item_id } {

  @public get_url
 
  Retrieves the relative URL stub to th item. The URL is relative to the
  page root, and has no extension (Example: "/foo/bar/baz"). 
 
  @param  item_id   The item id
 
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

    set live_revision [db_string glr_get_live_revision ""]

    if { [template::util::is_nil live_revision] } {
        ns_log notice "WARNING: No live revision for item $item_id"
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
    ns_log notice "WARNING: No item URL found for content item $item_id"
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
	ns_log notice "WARNING: No live revision for content item $item_id"
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
