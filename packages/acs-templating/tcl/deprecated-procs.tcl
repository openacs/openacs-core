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

namespace eval template {}
namespace eval template::util {}

ad_proc -public -deprecated template::util::get_cookie { name {default_value ""} } {
    Retrieve the value of a cookie and return it
    Return the default if no such cookie exists

    @see ad_get_cookie
} {
    set headers [ns_conn headers]
    set cookie [ns_set iget $headers Cookie]

    if { [regexp "$name=(\[^;\]+)" $cookie match value] } {
	return [ns_urldecode $value]
    }

    return $default_value
}

ad_proc -public -deprecated template::util::set_cookie { expire_state name value { domain "" } } {
    Create a cookie with specified parameters.  The expiration state
    may be persistent, session, or a number of minutes from the current
    time.

    @see ad_set_cookie
} {

    if { [string match $domain {}] } {
	set path "ns/server/[ns_info server]/module/nssock"
	set domain [ns_config $path Hostname]
    }

    set cookie "$name=[ns_urlencode $value]; path=/; domain=$domain"

    switch -- $expire_state {

	persistent {
	    append cookie ";expires=Wed, 01-Jan-2020 01:00:00 GMT"
	}

	"" -
	session {
	}

	default {

	    set time [expr {[ns_time] + ($expire_state * 60)}]
	    append cookie ";expires=[ns_httptime $time]"
	}
    }

    ns_set put [ns_conn outputheaders] "Set-Cookie" $cookie
}

ad_proc -public -deprecated template::util::clear_cookie { name { domain "" } } {
    Expires an existing cookie.

    @see ad_get_cookie

} {
    if { [string match $domain {}] } {
	set path "ns/server/[ns_info server]/module/nssock"
	set domain [ns_config $path Hostname]
    }

    set cookie "$name=expired; path=/; domain=$domain;"
    append cookie "expires=Tue, 01-Jan-1980 01:00:00 GMT"

    ns_set put [ns_conn outputheaders] "Set-Cookie" $cookie
}

ad_proc -deprecated -public template::util::quote_html {
    html
} {
    Quote possible HTML tags in the contents of the html parameter.
} {

    return [ns_quotehtml $html]
}


ad_proc -deprecated -public template::util::multirow_foreach { name code_text } {
    runs a block of code foreach row in a multirow.

    Using "template::multirow foreach" is recommended over this routine.

    @param name the name of the multirow over which the block of
    code is iterated

    @param code_text the block of code in the for loop; this block can
    reference any of the columns belonging to the
    multirow specified; with the multirow named
    "fake_multirow" containing columns named "spanky"
    and "foobar",to set the column spanky to the value
    of column foobar use:<br>
    <code>set fake_multirow.spanky @fake_multirow.foobar@</code>
    <p>
    note: this block of code is evaluated in the same
    scope as the .tcl page that uses this procedure

    @author simon

    @see template::multirow
} {

    upvar $name:rowcount rowcount $name:columns columns i i
    upvar running_code running_code

    for { set i 1} {$i <= $rowcount} {incr i} {

	set running_code $code_text
	foreach column_name $columns {

	    # first change all references to a column to the proper
	    # rownum-dependent identifier, ie the array value identified
	    # by $<multirow_name>:<rownum>(<column_name>)
	    regsub -all "($name).($column_name)" $running_code "$name:${i}($column_name)" running_code
	}

	regsub -all {@([a-zA-Z0-9_:\(\)]+)@} $running_code {${\1}} running_code

	uplevel {
	    eval $running_code
	}

    }

}

ad_proc -deprecated -public template::util::get_param {
    name
    {section ""}
    {key ""}
} {
    Retrieve a stored parameter, or "" if no such parameter
    If section/key are present, read the parameter from the specified
    section.key in the INI file, and cache them under the given name
} {

    if { ![nsv_exists __template_config $name] } {

	# Extract the parameter from the ini file if possible
	if { $section ne "" } {

	    # Use the name if no key is specified
	    if { $key ne "" } {
		set key $name
	    }

	    set value [ns_config $section $key ""]
	    if {$value eq ""} {
		return ""
	    } else {
		# Cache the value and return it
		template::util::set_param $name $value
		return $value
	    }

	} else {
	    # No such parameter found and no key/section specified
	    return ""
	}
    } else {
	return [nsv_get __template_config $name]
    }
}

ad_proc -public -deprecated  template::util::set_param { name value } {
    Set a stored parameter
} {
    nsv_set __template_config $name $value
}

ad_proc -deprecated template::get_resource_path {} {
    Get the template directory
    The body is doublequoted, so it is interpreted when this file is read
    @see template::resource_path
} "
  return \"[file dirname [file dirname [info script]]]/resources\"
"

##################################################################################
#
# From richtext-procs.tcl
#
##################################################################################
namespace eval template::widget {}

ad_proc -public -deprecated template::widget::richtext_htmlarea { element_reference tag_attributes } {
    Implements the richtext widget, which offers rich text editing options.

    If the acs-templating.UseHtmlAreaForRichtextP parameter is set to true (1),
    this will use the htmlArea WYSIWYG editor widget.
    Otherwise, it will use a normal textarea, with a drop-down to select a format.
    The available formats are:
    <ul>
    <li>Enhanced text = Allows HTML, but automatically inserts line and paragraph breaks.
    <li>Plain text = Automatically inserts line and paragraph breaks,
    and quotes all HTML-specific characters, such as less-than, greater-than, etc.
    <li>Fixed-width text = Same as plain text, but conserves spacing; useful for tabular data.
    <li>HTML = normal HTML.
    </ul>
    You can also parameterize the richtext widget with a 'htmlarea_p' attribute,
    which can be true or false, and which will override the parameter setting.

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

  if {$element(mode) eq "edit"} {
      append output {<script type="text/javascript" nonce='$::__csp_nonce'><!--} \n {acs_RichText_WriteButtons();  //--></script>}
      
      set attributes(id) "richtext__$element(form_id)__$element(id)"
      
      if { [info exists element(htmlarea_p)] && $element(htmlarea_p) ne "" } {
          set htmlarea_p [template::util::is_true $element(htmlarea_p)]
      } else {
          set htmlarea_p [parameter::get \
                              -package_id [apm_package_id_from_key "acs-templating"] \
                              -parameter "UseHtmlAreaForRichtextP" \
                              -default 0]
      }

      # Check browser's User-Agent header for compatibility with htmlArea
      ad_return_complaint 1 "use htmlareap = $htmlarea_p"
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
          lappend ::acs_blank_master__htmlareas $attributes(id)
      }

      append output [textarea_internal $element(id) attributes $contents]
      if { $htmlarea_p } {
          append output [subst {<input name="$element(id).format" value="text/html" type="hidden">}]
      } else {
          append output \
              [subst {<br>[_ acs-templating.Format]:}] \
              [menu $element(id).format [template::util::richtext::format_options] $format attributes]
      }
          
      # Spell-checker
      array set spellcheck [template::util::spellcheck::spellcheck_properties -element_ref element]
      if { $spellcheck(render_p) } {
          append output \
              [subst { [_ acs-templating.Spellcheck]: }] \
              [menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] \
                   $spellcheck(selected_option) attributes]
      }
  } else {
      # Display mode
      if { [info exists element(value)] } {
          append output \
              [template::util::richtext::get_property html_value $element(value)] \
              [subst {<input type="hidden" name="$element(id)" value="[ns_quotehtml $contents]">}] \
              [subst {<input type="hidden" name="$element(id).format" value="[ns_quotehtml $format]">}]
      }
  }
      
  return $output
}

##################################################################################
#
# From doc-tcl-procs.tcl
#
##################################################################################

ad_proc -private -deprecated template::util::server_root {} {
    uses ns_library to find the server root, may not always be accurate
    because it essentially asks for the Tcl library path and
    strips off the last /tcl directory.

    @see use $::acs::rootdir instead
} {

  set path_length [expr [llength [file split [ns_library private]]] - 1]
  set svr_root "/[join [lreplace [file split [ns_library private]] $path_length $path_length] / ]"
  return $svr_root
}


ad_proc -private -deprecated template::util::display_value { ref } {
    a proc used for debugging, just prints out a value to the error log

    @see use simple "ns_log ...." instead
} {
    upvar $ref value
    ns_log notice "$ref: $value"
}

ad_proc -private -deprecated template::util::proper_noun { string_ref } {
    capitalizes the first letter of a string
    @return returns formatted string (UNFINISHED. FIXME.)
    @see use "string totitle ..."
} {

}

ad_proc -private -deprecated template::util::string_range { string indices } {
    @see use "string range instead"
} {
    return [string range $string [lindex $indices 0] [lindex $indices 1]]
}

##################################################################################
#
# From query-procs.tcl
#
##################################################################################
namespace eval template::query {}

ad_proc -public -deprecated template::query::iterate { statement_name sql body } {
    @param statement_name Standard db_api statement name used to hook 
                          into query dispatcher

    @param sql Query to use when processing this command

    @param body Code body to be execute for each result row of the 
                returned query

    @see db_foreach
} {

    db_with_handle db {
        set result [db_exec select $db $statement_name $sql 2]

        set rowcount 0

        while { [ns_db getrow $db $result] } {

            upvar __query_iterate_row row

            set row(rownum) [incr rowcount]

            set size [ns_set size $result]

            for { set i 0 } { $i < $size } { incr i } {

                set column [ns_set key $result $i]
                set row($column) [ns_set value $result $i]
            }

            # Execute custom code for each row
            uplevel "upvar 0 __query_iterate_row row; $body"
        }
    }
}

##################################################################################
#
# From parse-procs.tcl
#
##################################################################################

ad_proc -private -deprecated template::get_enclosing_tag { tag } {
    Reach back into the tag stack for the last enclosing instance of a tag.  
    Typically used where the usage of a tag depends on its context, such
    as the "group" tag within a "multiple" tag.
    
    Deprecated, use:
    <pre>
    set tag [template::enclosing_tag &lt;tag-type&gt;]
    set attribute [template::tag_attribute tag &lt;attribute&gt;]
    </pre>
    @param tag  The name of the enclosing tag to look for.

    @see template::enclosing_tag
    @see template::tag_attribute
} {
    set name ""

    variable tag_stack

    set last [expr {[llength $tag_stack] - 1}]

    for { set i $last } { $i >= 0 } { incr i -1 } {

        set pair [lindex $tag_stack $i]

        if {[lindex $pair 0] eq $tag} {
            set name [ns_set get [lindex $pair 1] name]
            break
        }
    }

    return $name
}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
