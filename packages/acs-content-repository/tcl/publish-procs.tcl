
namespace eval publish {

  variable item_id_stack
  variable revision_html
  namespace eval handle {}
}


ad_proc -public publish::get_page_root {} {

    Get the page root. All items will be published to the
    filesystem with their URLs relative to this root.
    The page root is controlled by the PageRoot parameter in CMS.
    A relative path is relative to $::acs::pageroot
    The default is $::acs::pageroot

    @return The page root

    @see publish::get_template_root
    @see publish::get_publish_roots
} {
    # LARS TODO: This parameter doesn't exist, it's a remnant from the CMS package
    set root_path [parameter::get \
                       -package_id [ad_conn package_id] \
                       -parameter PageRoot]

    if { [string index $root_path 0] ne "/" } {
        # Relative path, prepend server_root
        set root_path "$::acs::pageroot/$root_path"
    }

    return [ns_normalizepath $root_path]

}


ad_proc -public publish::get_publish_roots {} {
    Get a list of all page roots to which files may be published.
    The publish roots are controlled by the PublishRoots parameter in CMS,
    which should be a space-separated list of all the roots. Relative paths
    are relative to publish::get_page_root.
    The default is [list [publish::get_page_root]]

    @return A list of all the publish roots

    @see publish::get_template_root
    @see publish::get_page_root

} {
    # LARS TODO: This parameter doesn't exist, it's a remnant from the CMS package
    set root_paths [parameter::get \
                        -package_id [ad_conn package_id] \
                        -parameter PublishRoots]

    if { [llength $root_paths] == 0 } {
        set root_paths [list [get_page_root]]
    }

    # Resolve relative paths
    set page_root [publish::get_page_root]
    set absolute_paths [list]
    foreach path $root_paths {
        if { [string index $path 0] ne "/" } {
            lappend absolute_paths [ns_normalizepath "$page_root/$path"]
        } else {
            lappend absolute_paths $path
        }
    }

    return $absolute_paths
}

ad_proc -public publish::mkdirs { path } {
    Create all the directories necessary to save the specified file

    @param path  The path to the file that is about to be saved
} {
    set index [string last "/" $path]
    if { $index != -1 } {
        file mkdir [string range $path 0 $index-1]
    }
}

###############################################
# Procs to maintain the item_id stack
# main_item_id is always the id at the top of the stack


ad_proc -private publish::push_id { item_id {revision_id ""}} {

  @private push_id

  Push an item id on top of stack. This proc is used
  to store state between <tt>child</tt>, <tt>relation</tt>
  and <tt>content</tt> tags.

  @param item_id
    The id to be put on stack

  @param revision_id  {default ""}
     The id of the revision to use. If missing, live
     revision will most likely be used

  @see publish::pop_id
  @see publish::get_main_item_id
  @see publish::get_main_revision_id

} {
  variable item_id_stack
  variable revision_html

  if { [template::util::is_nil item_id] } {
    error "Null id pushed on stack in publish::push_id"
  }

  # Determine old configuration
  set old_item_id ""
  set old_revision_id ""

  if { [info exists ::content::item_id] } {
    set old_item_id $::content::item_id
  }

  if { [info exists ::content::revision_id] } {
    set old_revision_id $::content::revision_id
  }

  # Preserve old data
  if { ![template::util::is_nil old_item_id] } {

    set pair [list $old_item_id $old_revision_id]

    if { ![template::util::is_nil item_id_stack] } {
      set item_id_stack [linsert $item_id_stack 0 $pair]
    } else {
      # This is the first id pushed - also clear the cache
      set item_id_stack [list $pair]
      array unset revision_html
    }
  } else {
    set item_id_stack [list]
  }

  # Set new data
  set ::content::item_id $item_id
  set ::content::revision_id $revision_id
}


ad_proc -private publish::pop_id {} {

  @private pop_id

  Pop the item_id and the revision_id off the top of the stack.
  Clear the temporary item cache if the stack becomes empty.

  @return The popped item id, or the empty string if the string is
    already empty

  @see publish::push_id
  @see publish::get_main_item_id
  @see publish::get_main_revision_id

} {
  variable item_id_stack

  set pair [lindex $item_id_stack 0]
  if { [template::util::is_nil pair] } {
    #error "Item id stack is empty in publish::pop_id"
  }

  set item_id_stack [lrange $item_id_stack 1 end]

  # If the stack is now empty, clear the cache
  if { [template::util::is_nil item_id_stack] } {
    array unset revision_html
  }

  lassign $pair ::content::item_id ::content::revision_id

  return $::content::item_id
}


ad_proc -public publish::proc_exists { namespace_name proc_name } {

  @public proc_exists

  Determine if a procedure exists in the given namespace

  @param namespace_name    The fully qualified namespace name,
   such as "template::util"

  @param proc_name         The proc name, such as "is_nil"

  @return 1 if the proc exists in the given namespace, 0 otherwise

} {

    return [expr {[info commands ${namespace_name}::$proc_name] ne ""}]
}

##########################################################
#
# Procs for handling mime types
#


ad_proc -public publish::handle_binary_file {
  item_id revision_id_ref url_ref error_ref args
} {

  @public handle_binary_file

  Helper procedure for writing handlers for binary files.
  It will write the blob of the item to the filesystem,
  but only if -embed is specified. Then, it will attempt to
  merge the image with its template. <br>
  This proc accepts exactly the same options a typical handler.

  @param item_id
     The id of the item to handle

  @param revision_id_ref {<i>required</i>}
     The name of the variable in the calling frame that will
     receive the revision_id whose content blob was written
     to the filesystem.

  @param url_ref
     The name of the variable in the calling frame that will
     receive the relative URL of the file in the file system
     which contains the content blob

  @param error_ref
     The name of the variable in the calling frame that will
     receive an error message. If no error has occurred, this
     variable will be set to the empty string ""

  @option embed
     Signifies that the content should be embedded directly in
     the parent item. <tt>-embed</tt> is <b>required</b> for this
     proc, since it makes no sense to handle the binary file
     in any other way.

  @option revision_id {default The live revision for the item}
     The revision whose content is to be used

  @option no_merge
     If present, do NOT merge with the template, in order to
     prevent infinite recursion in the &lt;content&gt tag. In
     this case, the proc will return the empty string ""

  @return The HTML resulting from merging the item with its
     template, or "" if no template exists or the <tt>-no_merge</tt>
     flag was specified

  @see publish::handle::image

} {

  template::util::get_opts $args

  upvar $error_ref error_msg
  upvar $url_ref file_url
  upvar $revision_id_ref revision_id
  set error_msg ""

  if { ![info exists opts(revision_id)] } {
    set revision_id [::content::item::get_live_revision -item_id $item_id]
  } else {
    set revision_id $opts(revision_id)
  }

  # If the embed tag is true, return the html. Otherwise,
  # just write the image to the filesystem
  if { [info exists opts(embed)] } {

    set file_url [publish::write_content $revision_id \
                   -item_id $item_id -root_path [publish::get_publish_roots]]

    # If write_content aborted, give up
    if { [template::util::is_nil file_url] } {
      set error_msg "No URL found for revision $revision_id, item $item_id"
      return ""
    }

    # Try to use the registered template for the image
    if { ![info exists opts(no_merge)] } {
      set html [publish::merge_with_template $item_id {*}$args]
      # Return the result of merging - could be ""
      return $html
    }

    return ""

  } else {
    set error_msg "No embed specified for handle_binary_file, aborting"
    return ""
  }

}

ad_proc -private publish::html_args { argv } {

  @private html_args

  Concatenate a list of name-value pairs as returned by
  <tt>set_to_pairs</tt> into a list of "name=value" pairs

  @param argv   The list of name-value pairs

  @return An HTML string in format "name=value name=value ..."

  @see publish::set_to_pairs

} {
  set extra_html ""
  if { ![template::util::is_nil argv] } {
    foreach { name value } $argv {
      append extra_html "$name=\"$value\" "
    }
  }

  return $extra_html
}


ad_proc -public publish::item_include_tag { item_id {extra_args {}} } {

  @public item_include_tag

  Create an include tag to include an item, in the form
  <blockquote><tt>
  include src=/foo/bar/baz item_id=<i>item_id</i>
    param=value param=value ...
  </tt></blockquote>

  @param item_id  The item id

  @param extra_args {}
    A list of extra parameters to be passed to the <tt>include</tt>
    tag, in form {name value name value ...}

  @return The HTML for the include tag

  @see content::item::get_virtual_path
  @see publish::html_args

} {

  # Concatenate all the extra html arguments into a string
  set extra_html [publish::html_args $extra_args]""
  set item_url [::content::item::get_virtual_path -item_id $item_id]
  return "<include src=\"$item_url\" $extra_html item_id=$item_id>"
}


ad_proc -public publish::handle::image { item_id args } {

  The basic image handler. Writes the image blob to the filesystem,
  then either merges with the template or provides a default <img>
  tag. Uses the title for alt text if no alt text is specified
  externally.

} {
  template::util::get_opts $args

  # LARS TODO: Added -no_merge, verify how this is supposed to work
  set html [publish::handle_binary_file \
		$item_id revision_id url error_msg {*}$args -no_merge]

  # If an error happened, abort
  if { ![template::util::is_nil error_msg] } {
    ns_log Warning "publish::handle::image: WARNING: $error_msg"
    return ""
  }

  # Return the HTML if we have any
  if { ![template::util::is_nil html] } {
    return $html
  }

  # If the merging failed, output a straight <img> tag
  db_1row i_get_image_info ""

  # Concatenate all the extra html arguments into a string
  if { [info exists opts(html)] } {
    set extra_html [publish::html_args $opts(html)]
    set have_alt [expr {"alt" in [string tolower $opts(html)]}]
  } else {
    set extra_html ""
    set have_alt 0
  }

  set html "<img src=\"$url\""

  if { ![template::util::is_nil width] } {
    append html " width=\"$width\""
  }

  if { ![template::util::is_nil height] } {
    append html " height=\"$height\""
  }

  append html " $extra_html"

  # Append the alt text if needed
  if { !$have_alt } {
    append html " alt=\"$image_alt\""
  }

  append html ">"

  return $html

}

ad_proc -private publish::merge_with_template { item_id args } {

  @private merge_with_template

  Merge the item with its template and return the resulting HTML. This proc
  is similar to <tt>content::init</tt>

  @param item_id   The item id

  @option revision_id {default The live revision}
    The revision which is to be used when rendering the item

  @option html
    Extra HTML parameters to be passed to the ADP parser, in format
    {name value name value ...}

  @return The rendered HTML, or the empty string on failure

  @see publish::handle_item

} {
  #set ::content::item_id $item_id
  set ::content::item_url [::content::item::get_virtual_path -item_id $item_id]

  template::util::get_opts $args

  # Either auto-get the live revision or use the parameter
  if { [info exists opts(revision_id)] } {
    set revision_id $opts(revision_id)
  } else {
    set revision_id [::content::item::get_live_revision -item_id $item_id]
  }

  # Get the template
  set ::content::template_url [::content::item::get_template -item_id $item_id -use_context public]

  if {$::content::template_url eq {}} {
    ns_log Warning "publish::merge_with_template: no template for item $item_id"
    return ""
  }

  ns_log debug "publish::merge_with_template: template for item $item_id is $::content::template_url"

  # Get the full path to the template
  set root_path [content::get_template_root]
  set file_stub [ns_normalizepath "$root_path/$::content::template_url"]

  # Set the passed-in variables
  if { [info exists opts(html)] } {
    set adp_args $opts(html)
  } else {
    set adp_args ""
  }

  # Parse the template and return the result
  publish::push_id $item_id $revision_id
  ns_log debug "publish::merge_with_template: parsing $file_stub"
  set html [template::adp_parse $file_stub $adp_args]
  publish::pop_id

  return $html
}



ad_proc -public publish::handle::text { item_id args } {

  Return the text body of the item

} {

  template::util::get_opts $args

  if { ![info exists opts(revision_id)] } {
    set revision_id [::content::item::get_live_revision -item_id $item_id]
  } else {
    set revision_id $opts(revision_id)
  }

  if { [info exists opts(embed)] } {
    # Render the child item and embed it in the code
    if { ![info exists opts(no_merge)] } {
      set html [publish::merge_with_template $item_id {*}$args]
    } else {

        db_transaction {
            db_exec_plsql get_revision_id {}

            # Query for values from a previous revision
            set html [db_string get_previous_content ""]
        }
    }
  } else {

    # Just create an include tag

    # Concatenate all the extra html arguments into a string
    if { [info exists opts(html)] } {
      set extra_args $opts(html)
    } else {
      set extra_args ""
    }

    set html [publish::item_include_tag $item_id $extra_args]
  }

  return $html
}


ad_proc -public publish::get_mime_handler { mime_type } {

  @public get_mime_handler

  Return the name of a proc that should be used to render items with
  the given mime-type.
  The mime type handlers should all follow the naming convention

  <blockquote>
  <tt>proc publish::handle::<i>mime_prefix</i>::<i>mime_suffix</i></tt>
  </blockquote>

  If the specific mime handler could not be found, <tt>get_mime_handler</tt>
  looks for a generic procedure with the name

  <blockquote>
  <tt>proc publish::handle::<i>mime_prefix</i></tt>
  </blockquote>

  If the generic mime handler does not exist either,
  <tt>get_mime_handler</tt> returns ""

  @param mime_type
    The full mime type, such as "text/html" or "image/jpg"

  @return The name of the proc which should be used to handle the mime-type,
   or an empty string on failure.

  @see publish::handle_item

} {
  set mime_pair [split $mime_type "/"]
  lassign $mime_pair mime_prefix mime_suffix

  # Look for the specific handler
  if { [proc_exists "::publish::handle::${mime_prefix}" $mime_suffix] } {
    return "::publish::handle::${mime_prefix}::$mime_suffix"
  }

  # Look for the generic handler
  if { [proc_exists "::publish::handle" $mime_prefix] } {
    return "::publish::handle::${mime_prefix}"
  }

  # Failure
  return ""
}


ad_proc -private publish::get_main_item_id {} {

  @private get_main_item_id

  Get the main item id from the top of the stack

  @return the main item id

  @see publish::pop_id
  @see publish::push_id
  @see publish::get_main_revision_id

} {

  if { ![template::util::is_nil ::content::item_id] } {
    set ret $::content::item_id
  } else {
    error "Item id stack is empty"
  }

  return $ret
}


ad_proc -private publish::get_main_revision_id {} {

  @private get_main_revision_id

  Get the main item revision from the top of the stack

  @return the main item id

  @see publish::pop_id
  @see publish::push_id
  @see publish::get_main_item_id

} {

  if { [template::util::is_nil ::content::revision_id] } {
    set item_id [get_main_item_id]
    set ret [::content::item::get_live_revision -item_id $item_id]
  } else {
    set ret $::content::revision_id
  }

  return $ret
}

ad_proc -private publish::handle_item { item_id args } {

  @private handle_item

  Render an item either by looking it up in the temporary cache,
  or by using the appropriate mime handler. Once the item is rendered, it
  is stored in the temporary cache under a key which combines the item_id,
  any extra HTML parameters, and a flag which specifies whether the item
  was merged with its template. <br>
  This proc takes the same arguments as the individual mime handlers.

  @param item_id  The id of the item to be rendered

  @option revision_id {default The live revision}
    The revision which is to be used when rendering the item

  @option no_merge
    Indicates that the item should NOT be merged with its
    template. This option is used to avoid infinite recursion.

  @option refresh
    Re-render the item even if it exists in the cache.
    Use with caution - circular dependencies may cause infinite recursion
    if this option is specified

  @option embed
     Signifies that the content should be statically embedded directly in
     the HTML. If this option is not specified, the item may
     be dynamically referenced, f.ex. using the <tt>&lt;include&gt;</tt>
     tag

  @option html
     Extra HTML parameters to be passed to the item handler, in format
     {name value name value ...}

  @return The rendered HTML for the item, or an empty string on failure

  @see publish::handle_binary_file
  @see publish::handle::text
  @see publish::handle::image

} {

  template::util::get_opts $args

  variable revision_html

  # Process options
  if { ![info exists opts(revision_id)] } {
    set revision_id [::content::item::get_live_revision -item_id $item_id]
  } else {
    set revision_id $opts(revision_id)
  }

  if { [template::util::is_nil revision_id] } {
    ns_log warning "publish::handle_item: No live revision for $item_id"
    return ""
  }

  if { ![info exists opts(no_merge)] } {
    set merge_str "merge"
  } else {
    set merge_str "no_merge"
  }

  # Create a unique key
  set revision_key "$merge_str $revision_id"
  if { [info exists opts(html)] } {
    lappend revision_key $opts(html)
  }

  # Pull the item out of the cache
  if { ![info exists opts(refresh)]
       && [info exists revision_html($revision_key)]
   } {
    ns_log debug "publish::handle_item: Fetching $item_id from cache"
    return $revision_html($revision_key)

  } else {

    # Render the item and cache it
    ns_log debug "publish::handle_item: Rendering item $item_id"

    content::item::get -item_id $item_id -array_name item_info
    set item_handler [get_mime_handler $item_info(mime_type)]

    if { $item_handler eq "" } {
      ns_log warning "publish::handle_item: No mime handler for mime type $mime_info(mime_type)"
      return ""
    }

    # Call the appropriate handler function
    set code [list $item_handler $item_id {*}$args]

    # Pass the revision_id
    if { ![info exists opts(revision_id)] } {
      lappend code -revision_id $revision_id
    }

    set html [{*}$code]
    ns_log debug "publish::handle_item: Caching html for revision $revision_id"
    set revision_html($revision_key) $html

    return $html
  }
}


ad_proc -public publish::get_html_body { html } {

  @public get_html_body

  Strip the &lt;body&gt; tags from the HTML, leaving just the body itself.
  Useful for including templates in each other.

  @param html
    The html to be processed

  @return Everything between the &lt;body&gt; and the &lt;/body&gt; tags
     if they exist; the unchanged HTML if they do not

} {

  if { [regexp -nocase {<body[^>]*>(.*)</body>} $html match body_text] } {
    return $body_text
  } else {
    return $html
  }
}


ad_proc -public publish::render_subitem {
  main_item_id relation_type relation_tag \
  index is_embed extra_args {is_merge t}
} {

  @private render_subitem

  Render a child/related item and return the resulting HTML, stripping
  off the headers.

  @param main_item_id  The id of the parent item

  @param relation_type
    Either <tt>child</tt> or <tt>relation</tt>.
    Determines which tables are searched for subitems.

  @param relation_tag
   The relation tag to look for

  @param index
    The relative index of the subitem. The subitem with
    lowest <tt>order_n</tt> has index 1, the second lowest <tt>order_n</tt>
    has index 2, and so on.

  @param is_embed
    If "t", the child item may be embedded directly
    in the HTML. Otherwise, it may be dynamically included. The proc
    does not process this parameter directly, but passes it to
    <tt>handle_item</tt>

  @param extra_args
    Any additional HTML arguments to be used when
    rendering the item, in form {name value name value ...}

  @param is_merge {default t}
    If "t", <tt>merge_with_template</tt> may
    be used to render the subitem. Otherwise, <tt>merge_with_template</tt>
    should not be used, in order to prevent infinite recursion.

  @return The rendered HTML for the child item

  @see publish::merge_with_template
  @see publish::handle_item

} {
  # Get the child item

  if {$relation_type eq "child"} {
      set subitems [db_list rs_get_subitems ""]
  } else {
      set subitems [db_list cs_get_subitems_related ""]
  }

  set sub_item_id [lindex $subitems $index-1]

  if { [template::util::is_nil sub_item_id] } {
    ns_log notice "publish::render_subitem: No such subitem"
    return ""
  }

  # Call the appropriate handler function
  set code [list handle_item $sub_item_id -html $extra_args]

  if {$is_embed == "t"} {
    lappend code -embed
  }

  return [get_html_body [{*}$code]]
}

#######################################################
#
# The content tags


ad_proc -private publish::set_to_pairs { params {exclusion_list ""} } {

  @private set_to_pairs

  Convert an ns_set into a list of name-value pairs, in form
  {name value name value ...}

  @param params   The ns_set id
  @param exclusion_list {}
     A list of keys to be ignored

  @return A list of name-value pairs representing the data in the ns_set

} {

  set extra_args [list]
  for { set i 0 } { $i < [ns_set size $params] } { incr i } {
    set key   [ns_set key $params $i]
    set value [ns_set value $params $i]
    if { $key ni $exclusion_list } {
      lappend extra_args $key $value
    }
  }

  return $extra_args
}


ad_proc -private publish::process_tag { relation_type params } {

  @private process_tag

  Process a <tt>child</tt> or <tt>relation</tt> tag. This is
  a helper proc for the tags, which acts as a wrapper for
  <tt>render_subitem</tt>.

  @param relation_type  Either <tt>child</tt> or <tt>relation</tt>
  @param params         The ns_set id for extra HTML parameters

  @see publish::render_subitem

} {

  set tag   [template::get_attribute content $params tag]
  set index [template::get_attribute content $params index 1]
  set embed [ns_set find $params embed]
  if { $embed != -1 } { set embed t } else { set embed f }
  set parent_item_id [ns_set iget $params parent_item_id]

  # Concatenate all other keys into the extra arguments list
  set extra_args [publish::set_to_pairs $params \
    {tag index embed parent_item_id}]

  # Render the item, append it to the page
  # set item_id [publish::get_main_item_id]

  set command "publish::render_subitem"
  append command \
    " \[template::util::nvl \"$parent_item_id\" \$::content::item_id\]"
  append command " $relation_type $tag $index $embed"
  append command " \{$extra_args\}"

  template::adp_append_code "append __adp_output \[$command\]"
}


ad_proc -private publish::foreach_publish_path { url code {root_path ""} } {

  @private foreach_publish_path

  Execute some Tcl code for each root path in the PublishRoots
  parameter

  @param url       Relative URL to append to the roots
  @param code      Execute this code
  @param root_path {default The empty string}
     Use this root path instead of the paths specified in the INI
     file

  @see publish::get_publish_roots

} {
  if { ![template::util::is_nil root_path] } {
    set paths $root_path
  } else {
    # set paths [get_publish_roots]
    set paths "./"
  }

  upvar filename filename
  upvar current_page_root current_page_root

  foreach root_path $paths {
    ns_log debug "publish::foreach_publish_path: root_path: $root_path"
    set current_page_root $root_path
    set filename [ns_normalizepath "/$root_path/$url"]
    uplevel $code
  }
}

ad_proc -private publish::write_multiple_blobs {
  url revision_id {root_path ""}
} {

  @private write_multiple_blobs

  Write the content of some revision to multiple publishing roots.

  @param url          Relative URL of the file to write
  @param revision_id  Write the blob for this revision
  @param root_path    Use this root path (default empty)

  @see publish::get_publish_roots
  @see publish::write_multiple_files

} {
  foreach_publish_path $url {
    mkdirs $filename

    db_1row get_storage_type "
           select storage_type
             from cr_items
            where item_id = (select item_id
                               from cr_revisions
                              where revision_id = :revision_id)"

    db_blob_get_file wmb_get_blob_file "
      select content from cr_revisions where revision_id = $revision_id
    " -file $filename

    ns_chmod $filename 0764
    ns_log debug "publish::write_multiple_blobs: Wrote revision $revision_id to $filename"
  } $root_path
}


ad_proc -private publish::write_multiple_files { url text {root_path ""}} {

  @private write_multiple_files

  Write a relative URL to the multiple publishing roots.

  @param url        Relative URL of the file to write
  @param text       A string of text to be written to the URL
  @param root_path  Use this root path (default empty)

  @see template::util::write_file
  @see publish::get_publish_roots
  @see publish::write_multiple_blobs

} {
    ns_log debug "publish::write_multiple_files: root_path = $root_path"
  foreach_publish_path $url {
    mkdirs $filename
    template::util::write_file $filename $text
    ns_chmod $filename 0764
    ns_log debug "publish::write_multiple_files: Wrote text to $filename"
  } $root_path
}


ad_proc -public publish::write_content { revision_id args } {

  @public write_content

  Write the content (blob) of a revision into a binary file in the
  filesystem. The file will be published at the relative URL under
  each publish root listed under the PublishRoots parameter in the
  server's INI file (the value returnded by publish::get_page_root is
  used as the default). The file extension will be based on the
  revision's mime-type. <br>
  For example, an revision whose mime-type is "image/jpeg"
  for an item at "Sitemap/foo/bar" may be written as
  /web/your_server_name/www/foo/bar.jpg

  @param revision_id
    The id of the revision to write

  @option item_id   {default The item_id of the revision}
    Specifies the item  to which this revision belongs (merely
    for optimization purposes)

  @option text
    If specified, indicates that the content of the
    revision is readable text (clob), not a binary file

  @option root_path {default All paths in the PublishPaths parameter}
    Write the content to this path only.

  @return The relative URL of the file that was written, or an empty
          string on failure

  @see content::get_content_value
  @see publish::get_publish_roots

} {

  template::util::get_opts $args

  if { ![info exists opts(root_path)] } {
    set root_path ""
  } else {
    set root_path $opts(root_path)
  }

  db_transaction {

      # Get the item id if none specified
      if { ![info exists opts(item_id)] } {
          set item_id [db_string get_one_revision ""]

	  if { [template::util::is_nil item_id] } {
	      ns_log warning "publish::write_content: No such revision $revision_id"
	      return ""
	  }
      } else {
	  set item_id $opts(item_id)
      }


      #set file_url [item::get_extended_url $item_id -revision_id $revision_id]
      set base_path [content::item::get_virtual_path -item_id $item_id]
      content::item::get -item_id $item_id -array_name item_info
      set mime_type $item_info(mime_type)
      set ext [db_string get_extension {
	  select file_extension from cr_mime_types where mime_type = :mime_type
      }]
      set file_url $base_url.$ext

      # LARS HACK: Delete the file if it already exists
      # Not sure what we should really do here, since on the one hand, the below db commands
      # crap out if the file already exists, but on the other hand, we shouldn't accidentally
      # overwrite files
      if { [file exists $root_path$file_url] } {
          file delete -- $root_path$file_url
      }

      # Write blob/text to file
      ns_log debug " publish::write_content: writing item $item_id to $file_url"

      if { [info exists opts(text)] } {
          db_transaction {
              db_exec_plsql gcv_get_revision_id {
                  begin
                  content_revision.to_temporary_clob(:revision_id);
                  end;
              }

              # Query for values from a previous revision

              set text [db_string gcv_get_previous_content ""]
          }

	  write_multiple_files $file_url $text $root_path
      } else {

	  # Determine if the blob is null. If it is, give up (or else the
	  # ns_ora blob_get_file will crash).
	  if { [content::item::content_is_null $revision_id] } {
	      ns_log warning "publish::write_content: No content supplied for revision $revision_id"
	      return ""
	  }

	  # Write the blob
	  write_multiple_blobs $file_url $revision_id $root_path
      }
  }

  # Return either the full path or the relative URL
  return $file_url
}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
