ad_library {
    Rich text input widget and datatype for OpenACS templating system.

    @author Lars Pind (lars@pinds.com)
    @creation-date 2003-01-27
    @cvs-id $Id$
}

namespace eval template {}
namespace eval template::data {}
namespace eval template::data::transform {}
namespace eval template::data::validate {}
namespace eval template::util {}
namespace eval template::util::richtext_or_file {}
namespace eval template::widget {}

ad_proc -public template::util::richtext_or_file { command args } {
    Dispatch procedure for the richtext_or_file object
} {
  template::util::richtext_or_file::$command {*}$args
}

ad_proc -public template::util::richtext_or_file::create {
    {storage_type {}}
    {mime_type {}}
    {text {}}
    {filename {}}
    {tmp_filename {}}
    {content_url {}}
} {
    Create a richtext_or_file datastructure.
} {
    return [list $storage_type $mime_type $text $filename $tmp_filename $content_url]
}

ad_proc -public template::util::richtext_or_file::acquire { type { value "" } } {
    Create a new richtext_or_file value with some predefined value
    Basically, create and set the richtext_or_file value
} {
  set richtext_or_file_list [template::util::richtext_or_file::create]
  return [template::util::richtext_or_file::set_property $type $richtext_or_file_list $value]
}

ad_proc -public template::util::richtext_or_file::formats {} {
    Returns a list of valid richtext_or_file formats
} {
    return { text/enhanced text/plain text/html text/fixed-width }
}

ad_proc -public template::util::richtext_or_file::format_options {} {
    Returns a formatting option list
} {
    return { 
        {"Enhanced Text" text/enhanced}
        {"Plain Text" text/plain}
        {"Fixed-width Text" text/fixed-width}
        {"HTML" text/html}
    }
}

ad_proc -public template::data::validate::richtext_or_file {
    value_ref
    message_ref
} {
    Validate submitted richtext_or_file by checking that the format is valid, HTML doesn't
    contain illegal tags, etc.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if the submitted value is valid, false (0) otherwise
} {


    upvar 2 $message_ref message $value_ref richtext_or_file_list

    set storage_type [lindex $richtext_or_file_list 0]
    set mime_type    [lindex $richtext_or_file_list 1]
    set text         [lindex $richtext_or_file_list 2]
    set filename     [lindex $richtext_or_file_list 3]
    set tmp_filename [lindex $richtext_or_file_list 4]
    set content_url  [lindex $richtext_or_file_list 5]

    if { $text ne "" && [lsearch -exact [template::util::richtext_or_file::formats] $mime_type] == -1 } {
	set message "Invalid text format, '$mime_type'."
	return 0
    }

    # enhanced text and HTML needs to be security checked
    if { [lsearch { text/enhanced text/html } $mime_type] == -1 } {
        set check_result [ad_html_security_check $text]
        if { $check_result ne "" } {
            set message $check_result
            return 0
        }
    }

    return 1
}    

ad_proc -public template::data::transform::richtext_or_file {
    element_ref
} {
    Transform submitted data into a valid richtext_or_file data structure (list)

    @param element_ref Reference variable to the form element

    @return Submitted data in the richtext_or_datafile list form

} {

    upvar $element_ref element
    set element_id $element(id)

    # We need to return the empty list in order for form builder to think of it 
    # as a non-value in case of a required element.

    set storage_type [ns_queryget $element_id.storage_type]
    switch $storage_type {
        text {
            set text [ns_queryget $element_id.text]
            if { $text eq "" } {
                return [list]
            }
            set mime_type [ns_queryget $element_id.mime_type]

            return [list [list "text" $mime_type $text {} {} {}]]
        }  
        file {
            set file [template::util::file_transform $element_id.file]
            if { $file eq "" } {
                return [list]
            }
            set filename [template::util::file::get_property filename $file]
            set tmp_filename [template::util::file::get_property tmp_filename $file]
            set mime_type [template::util::file::get_property mime_type $file]

            return [list [list "file" $mime_type {} $filename $tmp_filename {}]]
        }
        default {
            return [list]
        }
    }
}

ad_proc -public template::util::richtext_or_file::set_property { what richtext_or_file_list value } {
    Set a property of the richtext_or_file datatype. Valid proerties are: 

    <ul>
      <li>storage_type
      <li>mime_type
      <li>text
      <li>filename
      <li>tmp_filename
      <li>content_url
    </ul>
} {
    set storage_type [lindex $richtext_or_file_list 0]
    set mime_type    [lindex $richtext_or_file_list 1]
    set text         [lindex $richtext_or_file_list 2]
    set filename     [lindex $richtext_or_file_list 3]
    set tmp_filename [lindex $richtext_or_file_list 4]
    set content_url  [lindex $richtext_or_file_list 5]

    switch $what {
        storage_type {
            # Replace contents with value
            return [list $value $mime_type $text $filename $tmp_filename $content_url]
        }
        mime_type {
            # Replace format with value
            return [list $storage_type $value $text $filename $tmp_filename $content_url]
        }
        text {
            # Replace contents with value
            return [list $storage_type $mime_type $value $filename $tmp_filename $content_url]
        }
        filename {
            return [list $storage_type $mime_type $text $value $tmp_filename $content_url]
        }
        tmp_filename {
            return [list $storage_type $mime_type $text $filename $value $content_url]
        }
        content_url {
            return [list $storage_type $mime_type $text $filename $tmp_filename $value]
        }
        default {
            error "Invalid property $what, valid properties are storage_type, mime_type, text, filename, tmp_filanme, content_url."
        }
    }
}

ad_proc -public template::util::richtext_or_file::get_property { what richtext_or_file_list } {

    Get a property of the richtext_or_file datatype. Valid proerties are: 

    <ul>
      <li>storage_type
      <li>mime_type
      <li>text
      <li>filename
      <li>tmp_filename
      <li>content_url
    </ul>
} {
    set storage_type [lindex $richtext_or_file_list 0]
    set mime_type    [lindex $richtext_or_file_list 1]
    set text         [lindex $richtext_or_file_list 2]
    set filename     [lindex $richtext_or_file_list 3]
    set tmp_filename [lindex $richtext_or_file_list 4]
    set content_url  [lindex $richtext_or_file_list 5]

    switch $what {
        storage_type {
            return $storage_type
        }
        mime_type {
            return $mime_type
        }
        text {
            return $text
        }
        filename {
            return $filename
        }
        tmp_filename {
            return $tmp_filename
        }
        content_url {
            return $content_url
        }
        file {
            return [list $filename $tmp_filename $mime_type]
        }
        html_value {
            switch $storage_type {
                text {
                    return [ad_html_text_convert -from $mime_type -to "text/html" -- $text]
                }
                file {
                    return "<a href=\"[ns_quotehtml $content_url]\">Download file</a>"
                }
            }
            return {}
        }
        default {
            error "Invalid property $what, valid properties are storage_type, mime_type, text, filename, tmp_filanme, content_url, html_value, file."
        }
    }
}

ad_proc -public template::widget::richtext_or_file {
    element_reference
    tag_attributes
} { 
    Render a richtext_or_file widget

    @param element_reference Reference variable to the form element
    @param tag_attributes Attributes to include in the generated HTML

    @return Form HTML for the widget

} { 
  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  if { [info exists element(value)] } {
      set storage_type [template::util::richtext_or_file::get_property storage_type $element(value)]
      set mime_type    [template::util::richtext_or_file::get_property mime_type $element(value)]
      set text         [template::util::richtext_or_file::get_property text $element(value)] 
      set filename     [template::util::richtext_or_file::get_property filename $element(value)] 
      set tmp_filename [template::util::richtext_or_file::get_property tmp_filename $element(value)] 
      set content_url  [template::util::richtext_or_file::get_property content_url $element(value)] 
  } else {
      set storage_type {}
      set mime_type    {}
      set text         {}
      set filename     {}
      set tmp_filename {}
      set content_url  {}
  }
  
  set output {}

  if {$element(mode) eq "edit"} {
      if { $storage_type eq "" } {
          append output [subst {
              <input type="radio" name="$element(id).storage_type" id="$element(id).storage_type_text" value="text"
                checked>
              <label for="$element(id).storage_type_text">Enter text</label><blockquote>
          }]
          template::add_event_listener \
              -id "$element(id).storage_type_file" \
              -script [subst {acs_RichText_Or_File_InputMethodChanged('$element(form_id)', '$element(id)', this);}]

      } else {
          append output [subst {
              <input type="hidden" name="$element(id).storage_type" value="[ns_quotehtml $storage_type]">
          }]
      }

      if { $storage_type eq "" || $storage_type eq "text" } {
          append output [subst {<script type="text/javascript" nonce='$::__csp_nonce'><!--}] \
              \n {acs_RichText_WriteButtons();  //--></script>} \
              [textarea_internal "$element(id).text" attributes $text] \
              [subst {<br>Format: \
                          [menu "$element(id).mime_type" \
                               [template::util::richtext_or_file::format_options] \
                               $mime_type \
                               attributes]}]
      }

      if { $storage_type eq "" } {
          append output [subst {
              </blockquote>
              <input type="radio" name="$element(id).storage_type" id="$element(id).storage_type_file" value="file">
              <label for="$element(id).storage_type_file">Upload a file</label>
              <blockquote>
          }]
          template::add_event_listener \
              -id "$element(id).storage_type_file" \
              -script [subst {acs_RichText_Or_File_InputMethodChanged('$element(form_id)', '$element(id)', this);}]

      }

      if {$storage_type eq "file"} {
          append output \
              [template::util::richtext_or_file::get_property html_value $element(value)] \
              "<p>Replace uploaded file: " \
              [subst {<input type="file" name="$element(id).file">}]
      }
      if { $storage_type eq "" } {
          append output [subst {<input type="file" name="$element(id).file" disabled>}]
      }
      
      if { $storage_type eq "" } {
          append output "</blockquote>"
      }
  } else {
      # Display mode
      if { [info exists element(value)] } {
          append output [template::util::richtext_or_file::get_property html_value $element(value)]
          append output "<input type=\"hidden\" name=\"$element(id).mime_type\" value=\"[ns_quotehtml $mime_type]\">"
          append output "<input type=\"hidden\" name=\"$element(id).storage_type\" value=\"[ns_quotehtml $storage_type]\">"
          append output "<input type=\"hidden\" name=\"$element(id).text\" value=\"[ns_quotehtml $text]\">"
      }
  }
      
  return $output
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
