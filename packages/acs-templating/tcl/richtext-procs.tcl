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
namespace eval template::util::richtext {}
namespace eval template::widget {}

ad_proc -public template::util::richtext { command args } {
    Dispatch procedure for the richtext object
} {
  eval template::util::richtext::$command $args
}

ad_proc -public template::util::richtext::create {
    {contents {}}
    {format {}}
} {
    return [list $contents $format]
}

ad_proc -public template::util::richtext::acquire { type { value "" } } {
    Create a new richtext value with some predefined value
    Basically, create and set the richtext value
} {
  set richtext_list [template::util::richtext::create]
  return [template::util::richtext::set_property $type $richtext_list $value]
}

ad_proc -public template::util::richtext::formats {} {
    Returns a list of valid richtext formats
} {
    return { text/enhanced text/plain text/html text/fixed-width }
}

ad_proc -public template::util::richtext::format_options {} {
    Returns a formatting option list
} {
    return { 
        {"Enhanced Text" text/enhanced}
        {"Plain Text" text/plain}
        {"Fixed-width Text" text/fixed-width}
        {"HTML" text/html}
    }
}

ad_proc -public template::data::validate::richtext { value_ref message_ref } {

    upvar 2 $message_ref message $value_ref richtext_list

    set contents    [lindex $richtext_list 0]
    set format      [lindex $richtext_list 1]

    if { ![empty_string_p $contents] && [lsearch -exact [template::util::richtext::formats] $format] == -1 } {
	set message "Invalid format, '$format'."
	return 0
    }

    # enhanced text and HTML needs to be security checked
    if { [lsearch { text/enhanced text/html } $format] != -1 } {
        set check_result [ad_html_security_check $contents]
        if { ![empty_string_p $check_result] } {
            set message $check_result
            return 0
        }
    }

    return 1
}    

ad_proc -public template::data::transform::richtext { element_ref } {

    upvar $element_ref element
    set element_id $element(id)

    set contents [ns_queryget $element_id]
    set format [ns_queryget $element_id.format]

    if { [empty_string_p $contents] } {
        # We need to return the empty list in order for form builder to think of it 
        # as a non-value in case of a required element.
        return [list]
    } else {
        return [list [list $contents $format]]
    }
}

ad_proc -public template::util::richtext::set_property { what richtext_list value } {
    Set a property of the richtext datatype. 

    @param what One of
      <ul>
        <li>contents (synonyms content, text)</li>
        <li>format (synonym mime_type)</li>
      </ul>

    @param richtext_list the richtext list to modify
    @param value the new value

    @return the modified list
} {
    set contents [lindex $richtext_list 0]
    set format   [lindex $richtext_list 1]

    switch $what {
        contents - content - text {
            # Replace contents with value
            return [list $value $format]
        }
        format - mime_type {
            # Replace format with value
            return [list $contents $value]
        }
        default {
            error "Invalid property $what, valid properties are text (synonyms content, contents), mime_type (synonym format)."
        }
    }
}

ad_proc -public template::util::richtext::get_property { what richtext_list } {
    
    Get a property of the richtext datatype. Valid proerties are: 
    
    @param what the name of the property. Must be one of:
    <ul>
    <li>contents (synonyms content, text) - returns the actual contents of the textarea field</li>
    <li>format (synonym mime_type) - returns the mimetype, e.g. 'text/plain'</li>
    <li>html_value - returns the content converted to html format, regardless of the format the content is actually in. In case it is already text/html no conversion will be applied.</li></ul>

    @param richtext_list a richtext datatype value, usually created with ad_form.
} {
    set contents  [lindex $richtext_list 0]
    set format    [lindex $richtext_list 1]

    switch $what {
        content - contents - text {
            return $contents
        }
        format - mime_type {
            return $format
        }
        html_value {
            if { ![empty_string_p $contents] } {
                return [ad_html_text_convert -from $format -to "text/html" -- $contents]
            } else {
                return {}
            }
        }

        default {
            error "Parameter supplied to util::richtext::get_property 'what' must be one of: 'contents', 'format', 'html_value'. You specified: '$what'."
        }
    }
}

ad_proc -public -deprecated template::widget::richtext_htmlarea { element_reference tag_attributes } {
    Implements the richtext widget, which offers rich text editing options.

    If the acs-templating.UseHtmlAreaForRichtextP parameter is set to true (1), this will use the htmlArea WYSIWYG editor widget.
    Otherwise, it will use a normal textarea, with a drop-down to select a format. The available formats are:
    <ul>
    <li>Enhanced text = Allows HTML, but automatically inserts line and paragraph breaks.
    <li>Plain text = Automatically inserts line and paragraph breaks, and quotes all HTML-specific characters, such as less-than, greater-than, etc.
    <li>Fixed-width text = Same as plain text, but conserves spacing; useful for tabular data.
    <li>HTML = normal HTML.
    </ul>
    You can also parameterize the richtext widget with a 'htmlarea_p' attribute, which can be true or false, and which will override the parameter setting.

    @see template::widget::richtext
} {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  if { [info exists element(value)] } {
      set contents [template::util::richtext::get_property contents $element(value)]
      set format   [template::util::richtext::get_property format $element(value)]
  } else {
      set contents {}
      set format {}
  }
  
  set output {}

  if { [string equal $element(mode) "edit"] } {
      append output {<script language="javascript"><!--} \n {acs_RichText_WriteButtons();  //--></script>}
      
      set attributes(id) "richtext__$element(form_id)__$element(id)"
      
      if { [exists_and_not_null element(htmlarea_p)] } {
          set htmlarea_p [template::util::is_true $element(htmlarea_p)]
      } else {
          set htmlarea_p [parameter::get \
                              -package_id [apm_package_id_from_key "acs-templating"] \
                              -parameter "UseHtmlAreaForRichtextP" \
                              -default 0]
      }

      # Check browser's User-Agent header for compatibility with htmlArea
      if { $htmlarea_p } {
          set user_agent [string tolower [ns_set get [ns_conn headers] User-Agent]]
          if { [string first "opera" $user_agent] != -1 } { 
              # Opera - doesn't work, even though Opera claims to be IE
              set htmlarea_p 0
          } elseif { [regexp {msie ([0-9]*)\.([0-9]+)} $user_agent matches major minor] } {
              # IE, works for browsers > 5.5
              if { $major < 5 || ($major == 5  && $minor < 5) } {
                  set htmlarea_p 0
              }
          } elseif { [regexp {gecko/0*([1-9][0-9]*)} $user_agent match build] } {
              if { $build < 20030210 } {
                  set htmlarea_p 0
              }
          } else {
              set htmlarea_p 0
          }
      }

      if { $htmlarea_p } {
          # Tell the blank-master to include the special stuff for htmlArea in the page header
          global acs_blank_master__htmlareas
          lappend acs_blank_master__htmlareas $attributes(id)
      }

      append output [textarea_internal "$element(id)" attributes $contents]
      if { $htmlarea_p } {
          append output "<input name=\"$element(id).format\" value=\"text/html\" type=\"hidden\">"
      } else {
          append output "<br>Format: [menu "$element(id).format" [template::util::richtext::format_options] $format attributes]"
      }
          
      # Spell-checker
      array set spellcheck [template::util::spellcheck::spellcheck_properties -element_ref element]
      if { $spellcheck(render_p) } {
          append output " Spellcheck: [menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] $spellcheck(selected_option) attributes]"
      }
  } else {
      # Display mode
      if { [info exists element(value)] } {
          append output [template::util::richtext::get_property html_value $element(value)]
          append output "<input type=\"hidden\" name=\"$element(id)\" value=\"[ad_quotehtml $contents]\">"
          append output "<input type=\"hidden\" name=\"$element(id).format\" value=\"[ad_quotehtml $format]\">"
      }
  }
      
  return $output
}



ad_proc -public template::widget::richtext { element_reference tag_attributes } {
    Implements the richtext widget, which offers rich text editing options.

    This version supports the rte editor.


    If the acs-templating.UseHtmlAreaForRichtextP parameter is set to true (1), this will use the htmlArea WYSIWYG editor widget.
    Otherwise, it will use a normal textarea, with a drop-down to select a format. The available formats are:
    <ul>
    <li>Enhanced text = Allows HTML, but automatically inserts line and paragraph breaks.
    <li>Plain text = Automatically inserts line and paragraph breaks, and quotes all HTML-specific characters, such as less-than, greater-than, etc.
    <li>Fixed-width text = Same as plain text, but conserves spacing; useful for tabular data.
    <li>HTML = normal HTML.
    </ul>
    You can also parameterize the richtext widget with a 'htmlarea_p' attribute, which can be true or false, and which will override the parameter setting.

    Derived from the htmlarea richtext widget for htmlarea by lars@pinds.com

    modified for RTE http://www.kevinroth.com/ by davis@xarg.net
} {

    upvar $element_reference element

    if { [info exists element(html)] } {
        array set attributes $element(html)
    }

    array set attributes $tag_attributes

    if { [info exists element(value)] } {
        set contents [template::util::richtext::get_property contents $element(value)]
        set format   [template::util::richtext::get_property format $element(value)]
    } else {
        set contents {}
        set format {}
    }

    if { [string equal $element(mode) "edit"] } {

        set attributes(id) "richtext__$element(form_id)__$element(id)"

        if { [exists_and_not_null element(htmlarea_p)] } {
            set htmlarea_p [template::util::is_true $element(htmlarea_p)]
        } else {
            set htmlarea_p [parameter::get \
                                -package_id [apm_package_id_from_key "acs-templating"] \
                                -parameter "UseHtmlAreaForRichtextP" \
                                -default 0]
        }

        set output "[textarea_internal $element(id) attributes $contents]\n<br />Format: [menu $element(id).format [template::util::richtext::format_options] {} {}]"

        if { $htmlarea_p } {
            # Tell the blank-master to include the special stuff for htmlArea in the page header
            global acs_blank_master__htmlareas
            lappend acs_blank_master__htmlareas $element(form_id)


            regsub -all "\n" $contents "\\n" contents
            regsub -all "\r" $contents "" contents
            # Beware: & means "repeat the string being replaced"
            regsub -all "'" $contents "\\&#39;" contents

            # What we are generating here is the call to write the richtext widget but we also 
            # need to pass what to generate in for browsers for which the richtext widget
            # won't work but which do have js enabled should output since we need the 
            # format widget (this for Safari among some others)
            set output "<script type='text/javascript'><!--\nwriteRichText('$element(id)','$contents',500,200,true,false,'<input name=\"$element(id).format\" value=\"text/html\" type=\"hidden\"/>','[string map {\n \\n} $output]'); //--></script><noscript id=\"rte-noscr-$element(id)\">$output</noscript>"

        }
        # Spell-checker
        array set spellcheck [template::util::spellcheck::spellcheck_properties -element_ref element]
        if { $spellcheck(render_p) } {
            append output " Spellcheck: [menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] $spellcheck(selected_option) attributes]"
        }
    } else {
        # Display mode
        if { [info exists element(value)] } {
            append output [template::util::richtext::get_property html_value $element(value)]
            append output "<input type=\"hidden\" name=\"$element(id)\" value=\"[ad_quotehtml $contents]\">"
            append output "<input type=\"hidden\" name=\"$element(id).format\" value=\"[ad_quotehtml $format]\">"
        }
    }
    
    return $output
}

