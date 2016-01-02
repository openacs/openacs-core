###########
# Register the filter to automatically look up paths to content
# items and retrieve the appropriate item id
###########

namespace eval content {

    variable item_id
    variable item_url
    variable template_url
    variable revision_id
}




ad_proc -public content::get_template_root {} {
    Find the directory in the file system where templates are stored.
    There are a variety of ways in which this can be set. The proc
    looks for that directory in the following places in this order:
    (1) the TemplateRoot parameter of the package for which the request is
        made, i.e., [ad_conn package_id]
    (2) the TemplateRoot parameter of the acs-content-repository

    If it is not found in any of these places, it defaults to

    $::acs::rootdir/templates

    If the value resulting from the search does not start with a '/'
    it is taken to be relative to $::acs::rootdir

    @return the template root (full path from /)
} {
    # Look for package-defined root
    set package_id [ad_conn package_id]
    set template_root \
        [parameter::get -package_id $package_id -parameter TemplateRoot -default ""]

    if { $template_root eq "" } {
        # Look for template root defined in the CR
        set package_id [apm_package_id_from_key "acs-content-repository"]

        set template_root [parameter::get -package_id $package_id \
                               -parameter TemplateRoot -default "templates"]
    }

    if { [string index $template_root 0] ne "/" } {
        # Relative path, prepend server_root
        set template_root "$::acs::rootdir/$template_root"
    }

    return [ns_normalizepath $template_root]

}


ad_proc -public content::has_content {} {
    return true if the request has content associated with it

    @return 1 if ::content::item_id is defined
} { 
    variable item_id

    return [info exists item_id]
}

ad_proc -public content::get_item_id {} {
    @return current value of ::content::item_id
} {

    variable item_id

    return $item_id
}

ad_proc -public content::get_content { { content_type {} } } {
    sets the content in the array "content" in the callers scope
    assumes item_id or revision_id is set in the ::content namespace.

    @param content_type 
} {
    variable item_id
    variable revision_id

    if { [template::util::is_nil item_id] } {
        ns_log warning "content::get_content: No active item in content::get_content"
        return
    }

    if { [template::util::is_nil revision_id] } {
	# Try to get the live revision
	ns_log notice "content::get_content: trying to get live revision"
	set revision_id [db_string get_revision ""]
	if { [template::util::is_nil revision_id] } {
	    ns_log notice "content::get_content: No live revision for item $item_id"
	    return
	}
    }

    # Get the mime type, decide if we want the text
    set mime_type [db_string get_mime_type ""]

    if { [template::util::is_nil mime_type] } {
        ns_log notice "content::get_content: No such revision: $revision_id"
        return
    }

    if { [string equal -length 4 "text" $mime_type] } {
        set text_sql [db_map content_as_text]
    } else {
        set text_sql ""
    }

    # Get the content type
    if { $content_type eq "" } {
        set content_type [db_string get_content_type ""]
    }

    # Get the table name
    set table_name [db_string get_table_name ""]

    upvar content content

    # Get (all) the content (note this is really dependent on file type)
    if {![db_0or1row get_content "" -column_array content]} {
        ns_log notice "content::get_content: No data found for item $item_id, revision $revision_id"
        return 0
    }
}


ad_proc -public content::get_template_url {} {
    @return current value of ::content::template_url
} {
    variable template_url

    return $template_url
}


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

ad_proc -public content::get_content_value { revision_id } {
    @return content element corresponding to the provided revision_id
} { 
    db_transaction {
        db_exec_plsql gcv_get_revision_id {}

        # Query for values from a previous revision
        set content [db_string gcv_get_previous_content ""]

    }

    return $content
}


ad_proc -public content::init {
    {-resolve_index "f"}
    {-revision "live"}
    urlvar
    rootvar
    {content_root ""}
    {template_root ""}
    {context "public"}
    {rev_id ""}
    {content_type ""}
} {
    Initialize the namespace variables for the ::content procs and 
    figures out which template to use and  set up the template 
    for the required content type etc.
} {
    upvar $urlvar url $rootvar root_path
    variable root_folder_id
    variable item_id
    variable revision_id

    set root_folder_id $content_root
    # if a .tcl file exists at this url, then don't do any queries
    if { [file exists [ns_url2file "$url.tcl"]] } {
        return 0
    }

    # cache this query persistently for 1 hour
    set item_info(item_id) [::content::item::get_id -item_path $url \
                                -root_folder_id $content_root \
                                -resolve_index $resolve_index]
    set item_info(content_type) [::content::item::get_content_type \
                                     -item_id $item_info(item_id)]

    # No item found, so do not handle this request
    if {$item_info(item_id) eq ""} {
        set item_info(item_id) [::content::item::get_id -item_path $url \
                                    -root_folder_id $content_root \
                                    -resolve_index $resolve_index]
        set item_info(content_type) [::content::item::get_content_type \
                                         -item_id $item_info(item_id)]
        if {$item_info(item_id) eq ""} {
            ns_log notice "content::init: no content found for url $url"
            return 0
        }
    }

    variable item_url
    set item_url $url

    set item_id $item_info(item_id)
    if { $content_type eq "" } {
        set content_type $item_info(content_type)
    }

    # TODO accept latest revision as well. DaveB
    # Make sure that a live revision exists
    if { $rev_id eq "" } {
      if {"best" eq $revision} {
	  # lastest_revision unless live_revision is set, then live_revision
	  set revision_id [::content::item::get_best_revision -item_id $item_id]
      } else {
	  # default live_revision
	  set revision_id [::content::item::get_live_revision -item_id $item_id]
      }

      if {$revision_id eq ""} {
            ns_log notice "content::init: no live revision found for content item $item_id"
            return 0
        }

    } else {
        set revision_id $rev_id
    }

    variable template_path

    # Get the template 
    set template_found_p [db_0or1row get_template_url "" -column_array info]

    if { !$template_found_p || $info(template_url) eq {} } { 
        ns_log notice "content::init: No template found to render content item $item_id in context '$context'"
        return 0
    }

    set url $info(template_url)
    set root_path [get_template_root]

    # Added so that published templates are regenerated if they are missing.
    # This is useful for default templates.  
    # (OpenACS - DanW, dcwickstrom@earthlink.net)

    set file ${root_path}/${url}.adp
    if { ![file exists $file] } {

        file mkdir [file dirname $file]
        set text [content::get_content_value $info(template_id)]
        template::util::write_file $file $text
    }

    set file ${root_path}/${url}.tcl
    if { ![file exists $file] } {

        file mkdir [file dirname $file]
        set text "\# Put the current revision's attributes in a onerow datasource named \"content\".
\# The detected content type is \"$content_type\".

content::get_content $content_type

if { \"text/html\" ne \$content(mime_type) && !\[ad_html_text_convertable_p -from \$content(mime_type) -to text/html\] } {
    \# don't render its content
    cr_write_content -revision_id \$content(revision_id)
    ad_script_abort
}

\# Ordinary text/* mime type.
template::util::array_to_vars content

set text \[cr_write_content -string -revision_id \$revision_id\]
if { !\[string equal \"text/html\" \$content(mime_type)\] } {
    set text \[ad_html_text_convert -from \$content(mime_type) -to text/html -- \$text\]
}

set context \[list \$title\]

ad_return_template
"

      template::util::write_file $file $text
  }

  return 1
}



ad_proc -public content::deploy { url_stub } {
    render the template and write it to the file system
    with template::util::write_file
} {
    set output_path $::acs::pageroot$url_stub

    init url_stub root_path

    set output [template::adp_parse $file_stub]

    template::util::write_file $output_path $output
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
