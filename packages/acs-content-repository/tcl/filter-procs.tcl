###########
# Register the filter to automatically look up paths to content
# items and retrieve the appropriate item id
###########

namespace eval content {

variable item_id
variable item_url
variable template_url
variable revision_id

# Find the directory in the file system where templates are stored.
# There are a variety of ways in which this can be set. The proc
# looks for that directory in the following places in this order:
# (1) the TemplateRoot parameter of the package for which the request is 
#     made, i.e., [ad_conn package_id]
# (2) the TemplateRoot parameter of the acs-content-repository
# If it is not found in any of these places, it defaults to 
# [acs_root_dir]/templates
#
# If the value resulting from the search does not start with a '/'
# it is taken to be relative to [acs_root_dir]

proc get_template_root {} {

  # Look for package-defined root
  set package_id [ad_conn package_id]
  set template_root \
      [ad_parameter -package_id $package_id TemplateRoot dummy ""]

  if { [empty_string_p $template_root] } {
    # Look for template root defined in the CR
    set package_id [apm_package_id_from_key "acs-content-repository"]

    set template_root [ad_parameter -package_id $package_id \
	TemplateRoot dummy "templates"]
  }

  if { [string index $template_root 0] != "/" } {
    # Relative path, prepend server_root
    set template_root "[acs_root_dir]/$template_root"
  }

  return [ns_normalizepath $template_root]

}

# return true if the request has content associated with it

proc has_content {} {

  variable item_id

  return [info exists item_id]
} 

proc get_item_id {} {

  variable item_id

  return $item_id
} 

proc get_content {} {
 
  variable item_id
  variable revision_id

  if { [template::util::is_nil item_id] } {
    ns_log notice "No active item in content::get_content"
    return
  }

  # Get the live revision
  template::query get_revision revision_id onevalue "
    select live_revision from cr_items where item_id = :item_id
  " -cache "item_live_revision $item_id"

  if { [template::util::is_nil revision_id] } {
    ns_log notice "No live revision for item $item_id"
    return
  }

  # Get the mime type, decide if we want the text
  template::query get_mime_type mime_type onevalue "
    select mime_type from cr_revisions 
      where revision_id = :revision_id
  " -cache "revision_mime_type $revision_id" -persistent \
    -timeout 3600
  
  if { [template::util::is_nil mime_type] } {
    ns_log notice "No such revision: $reivision_id"
    return
  }  

  if { [string equal [lindex [split $mime_type "/"] 0] "text"] } {
    set text_sql ",\n    content.blob_to_string(content) as text"
  } else {
    set text_sql ""
  }
 
  # Get the content type
  template::query get_content_type content_type onevalue "
    select content_type from cr_items 
    where item_id = :item_id
  " -cache "item_content_type $item_id" -persistent \
    -timeout 3600

  # Get the table name
  template::query get_table_name table_name onevalue "
    select table_name from acs_object_types 
    where object_type = :content_type
  " -cache "type_table_name $content_type" -persistent \
    -timeout 3600

  upvar content content

  # Get (all) the content (note this is really dependent on file type)
  template::query get_content content onerow "select 
    x.*, 
    :item_id as item_id $text_sql, 
    :content_type as content_type
  from
    cr_revisions r, ${table_name}x x
  where
    r.revision_id = :revision_id
  and 
    x.revision_id = r.revision_id
  " -cache "content_for_revision $revision_id" -persistent \
    -timeout 3600

  if { ![array exists content] } { 
    ns_log Notice "No data found for item $item_id, revision $revision_id"
    return 0
  }

}

proc get_template_url {} {

  variable template_url

  return $template_url
}

# Set a data source in the calling frame with folder URL and label
# Useful for generating a context bar

proc get_folder_labels { { varname "folders" } } {
 
  variable item_id

  # this repeats the query used to look up the item in the first place
  # but there does not seem to be a clear way around this

  set query "
    select
      0 as tree_level, '' as name , 'Home' as title
    from
      dual
    UNION
    select
      t.tree_level, i.name, content_item.get_title(t.context_id) as title
    from (
      select 
        context_id, level as tree_level
      from 
        acs_objects
      where
        context_id <> content_item.get_root_folder
      connect by
        prior context_id = object_id
      start with
        object_id = :item_id
      ) t, cr_items i
    where
      i.item_id = t.context_id
    order by
      tree_level
  "

  set url ""

  # build the folder URL out as we iterate over the query
  template::query get_url $varname multirow $query -uplevel -eval {
    append url "$row(name)/"
    set row(url) ${url}index.acs
  }
}

proc init { urlvar rootvar {content_root ""} {template_root ""} {context "public"}} {

  upvar $urlvar url $rootvar root_path

  variable item_id
  variable revision_id
  
  # if a .tcl file exists at this url, then don't do any queries
  if { [file exists [ns_url2file "$url.tcl"]] } {
    return 0
  }

  # Get the content ID, content type 
  set query "
    select 
      item_id, content_type
    from 
      cr_items
    where
      item_id = content_item.get_id(:url, :content_root)"

  # cache this query persistently for 1 hour
  template::query get_item_info item_info onerow $query \
	  -cache "get_id_filter $url $content_root" \
	  -persistent -timeout 216000

  # No item found, so do not handle this request
  if { ![info exists item_info] } { 
    ns_log Notice "No content found for url $url"
    return 0 
  }

  variable item_url
  set item_url $url

  set item_id $item_info(item_id)
  set content_type $item_info(content_type)

  # Make sure that a live revision exists
  template::query get_live_revision live_revision onevalue "
    select live_revision from cr_items where item_id = :item_id
  " -cache "item_live_revision $item_id"

  if { [template::util::is_nil live_revision] } {
    ns_log Notice "No live revision found for content item $item_id"
    return 0
  }

  set revision_id $live_revision

  variable template_path

  # Get the template 
  set OFFquery "select 
    content_template.get_path(
      content_item.get_template(:item_id, 'public'),
      :template_root) as template_url 
  from   dual"

  set query "select 
    content_template.get_path(
      content_item.get_template(:item_id, :context),
      :template_root) as template_url 
  from 
    dual"


  template::query get_template_url template_url onevalue $query

  if { [string equal $template_url {}] } { 
    ns_log Notice "No template found to render content item $item_id in context '$context'"
    return 0
  }

  set url $template_url
  set root_path [get_template_root]

  return 1
}

# render the template and write it to the file system

proc deploy { url_stub } {
  
  set output_path [ns_info pageroot]$url_stub

  init url_stub root_path

  set output [template::adp_parse $file_stub]

  template::util::write_file $output_path $output
}

# end of content namespace

}
