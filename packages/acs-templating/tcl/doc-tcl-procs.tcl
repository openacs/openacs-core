ad_library {
    Documentation procedures for the ArsDigita Templating System

    @author Simon Huynh (shuynh@arsdigita.com)

    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


namespace eval doc {}
namespace eval doc::util {}
namespace eval template {}
namespace eval template::util {}

ad_proc -private doc::util::dbl_colon_fix { text } {

  regsub -all {::} $text {__} text
  return $text
}

ad_proc -private doc::util::sort_see { element1 element2 } {
    used to sort the see list, which has structure [name {name} type {type} url {url}]
    @param element1 the first of the two list elements to be compared
    @param element2 {default actually, no default value for this because it is required} the 
    second of the two elements to be compared
} {
  
    if { [lindex $element1 3 ] < [lindex $element2 3] } {
	return -1 
    }
    
    if { [lindex $element1 3 ] > [lindex $element2 3] } {
	return 1
    }
    
    return [string compare -nocase [lindex $element1 1] [lindex $element2 1]]
}

ad_proc -private doc::sort_@see { list_ref directive_comments } {
    procedure to deal with @see comments
} {
  upvar $list_ref see_list

  lassign $directive_comments type see_name url

  if {$url eq "" } {
    switch -exact $type {

	namespace {
	  set url "[doc::util::dbl_colon_fix $see_name].html"
	}

	proc {
	  set split_name $see_name
	  doc::util::text_divider split_name ::
	  set name_length [llength $split_name]
	  set see_namespace [join [lrange $split_name 0 $name_length-2] ""]
	  set url "[doc::util::dbl_colon_fix $see_namespace].html#[set see_name]"
	}
    }
  }

  lappend see_list [list name "$see_name" \
                         type "$type" \
                         url "$url" ]
  set see_list [lsort -command doc::util::sort_see $see_list]

}

ad_proc -private doc::util::find_marker_indices { text marker } {
    given a body of text and a text marker, returns a list of position indices
    for each occurrence of the text marker

    @param text body of text to be searched through
    @param marker the text-divider mark

    @return list of indices of the position immediately preceding each
    occurrence of the text marker; if there are no occurrences
    of the text marker, returns a zero-element list

    @see namespace doc
    @see doc::parse_file
    @see doc::parse_namespace
    @see doc::util::text_divider
} {

  set indices_list [list]
  set last_index -1
   
  while { [regexp -indices $marker $text marker_idx] } {
    lappend indices_list [expr {[lindex $marker_idx 0] + $last_index}]
    set text [string range $text [lindex $marker_idx 1]+1 end]
    set last_index [expr {[lindex $marker_idx 1] + $last_index + 1}]
  }

  # check for cases with no markers
  if { [llength $indices_list ] == 0 } {
      set indices_list [list end]
  }

  return $indices_list
}

ad_proc -private doc::util::text_divider { text_ref marker } {
    divides a string variable into a list of strings, all but the first element beginning
    with the indicated text marker; the first element of the created list contains all of
    the string preceding the first occurrence of the text marker
    @param text name of string variable (not the string value itself)
    @param marker the string indicating text division

    @see doc::util::find_marker_indices
} {
    upvar $text_ref text
    
    set indices_list [doc::util::find_marker_indices $text $marker]
    set result_list [list]

    # first check for no markers present
    if { $indices_list eq "end" } {
	set text [list $text]
	return 0
    }
    
    set old_index 0

    foreach index $indices_list {
	lappend result_list [string range $text $old_index $index]
	set old_index [expr {$index + 1}]
    }
    
    lappend result_list [string range $text $old_index end]
    
    set text $result_list
    return 1
}

ad_proc -private -deprecated template::util::server_root {} {
    uses ns_library to find the server root, may not always be accurate
    because it essentially asks for the Tcl library path and
    strips off the last /tcl directory.

    @see use $::acs::rootdir instead
} {

  set path_length [expr [llength [file split [ns_library private]]] - 1]
  set svr_root "/[join [lreplace [file split [ns_library private]] $path_length $path_le\ngth] / ]"
  return $svr_root
}

ad_proc -private template::util::write_from_template { template file_name} {
    takes a .adp template name and the name of the file to
    be written and creates the file; also puts out a notice before
    
    @param template the name of the template to be used in making the file
    @param file_name the name of the file to be created
} {

  upvar template_name template_name
  set template_name $template
  uplevel {
      set read_template [template::util::read_file $template_name]
      set code [template::adp_compile -string $read_template]
      set output [template::adp_eval code]
  }
  upvar output output
  template::util::write_to_file $file_name "$output"

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

ad_proc -private template::util::quote_space {text} {
    just takes a body of text and puts a space behind every double quote;
    this is done so that the text body can be treated as a list
    without causing problems resulting from list elements 
    being separated by characters other than a space

    @param text req/none the body of text to be worked on

    @return same text but with a space behind each quote; double quotes
    that are already trailed by a space are unaffected
} {
    regsub -all {"} $text {" } text
    regsub -all {"  } $text {" } text
    return $text
}

ad_proc -private doc::util::bracket_space {text} {
    puts a space after all closing curly brackets, does not
    add a space when brackets are already followed by a space
} {
    regsub -all {(\})} $text {\1 } text
    regsub -all {(\})  } $text {\1 } text
    return $text
}

ad_proc -private doc::util::escape_square_brackets {text} {
    escapes out all square brackets
} {
    regsub -all {(\[)} $text {\\\1} text
    regsub -all {(\])} $text {\\\1} text
    return $text
}


ad_proc -private doc::util::make_text_listable {text_ref} {
    upvar $text_ref text
    set text [doc::util::bracket_space $text]
    set text [template::util::quote_space $text]
    set text [doc::util::escape_square_brackets $text]
}


ad_proc -private template::util::comment_text_normalize {text} {
    escapes quotes and removes comment tags
    from a body of commented text
    @param text
    @return text
} { 
    regsub -all {"} $text {\"} text
    regsub -all {(\n)\s*#\s*} $text {\1 } text
    regsub {(\A)\s*#\s*} $text {\1 } text
    return $text
}

ad_proc -private template::util::alphabetized_index {list entry} {
    takes an alphabetized list and an entry
    
    @param list {let's see how this parses out} the alphabetized list
    @param entry req the value to be inserted

    @return either the proper list index for an alphabetized insertion or -1 if the entry is
    already in the list
} {

    set result [lsearch -exact $list $entry]
    if { $result != -1 } {
	return -1
    }
    
    for {set i 0} {$i < [llength $list] } { incr i } {
	if { [string compare -nocase $entry [lindex $list $i]] < 0 } {
	    return $i 
	}
    }
    
    return $i

}



ad_proc -private template::util::proc_element_compare { element1 element2 } {
    used to compare two different elements in a list of parsed data for public or private procs
} {
    return [string compare -nocase [lindex $element2 1 0 1] [lindex $element1 1 0 1]]
}

ad_proc -private doc::set_proc_name_source_text_comment_text { proc_block } {
    called by parse_comment_text
    @param comment_text this should include the source text
} {
    upvar source_txt source_txt
    upvar proc_name proc_name
    upvar comment_text comment_text

    doc::util::text_divider proc_block {\n\s*proc\s+}
    
    set comment_text [lindex $proc_block 0]
    set source_text [join [lrange $proc_block 1 end] "" ]

    set proc_name [lindex [template::util::comment_text_normalize $source_text] 1]

}


ad_proc -private doc::parse_comment_text { proc_block } {
    called by parse_namespace

    @param comment_text body of comment text to be parsed through
    @param source_text source text of the procedure
} {

    doc::set_proc_name_source_text_comment_text $proc_block

    doc::util::make_text_listable comment_text

# this will need to be changed
#    set proc_name [lindex [template::util::comment_text_normalize $source_text] 1]

    #set these values to blank in case they are not specified in the comment text

    foreach column { description author return } {
	set info_$column ""
    }

    # if we wanted to include the source text for the procedure as well:
    # set proc_info [list [list proc_name $proc_name] [list source $source_text]]

    set proc_param [list]
    set proc_option [list]
    set proc_see [list]

    set directives [lsort -index 0 [template::parse_directives $comment_text]]

    foreach directive $directives {

	set directive_type [lindex $directive 0] 
	set directive_comments [template::util::quote_space [lindex $directive 1]]

	switch -exact $directive_type {
	
	    public -

	    private {
		set public_private $directive_type
		set info_description [lrange $directive_comments 1 end ]
	    }

	    author -
	    
	    return {
		set info_$directive_type $directive_comments		
	    }

	    option -

	    param {
		set directive_name [lindex $directive_comments 0]

		if { [string match -nocase {default *} [lindex $directive_comments 1]] } {    
		    lappend proc_$directive_type [list name "$directive_name" \
			default "[lrange [lindex $directive_comments 1] 1 end]" \
			description "[lrange $directive_comments 2 end]" ]
		} else {
		    if {$directive_type eq "param"} {
			set default_comment "required"
		    } else {
			set default_comment ""
		    }
		    lappend proc_$directive_type [list name "$directive_name" \
			    default "$default_comment" \
			    description "[lrange $directive_comments 1 end]" ]
		    
		}
	    }

	    see {
		doc::sort_@see proc_$directive_type $directive_comments
	    }
	}
    }

    set proc_info [list proc_name "$proc_name" author "$info_author" description "$info_description" return "$info_return" ]

    set proc_result [list data [list "$proc_info" "$proc_param" "$proc_option" "$proc_see"] name "$proc_name"]

    upvar namespace_$public_private proc_list
    # set proc_list [lindex $namespace_proc 1]

    lappend proc_list $proc_result
    set proc_list [lsort $proc_list]

}

ad_proc -private doc::parse_namespace { text_lines }  {
    text between two namespace markers in a Tcl library file and 
    parses out procedure source and comments

    @author simon

    @param text_lines namespace text body
}  {

    # total_result_listing will contain our complete data set,
    # namespace_list is just a temp variable used for easy bookkeeping;
    # it contains an alphabetized lists of namespaces only
    upvar 2 result total_result_listing
    upvar 2 namespace_list namespace_list

    set text_list $text_lines
    if { [doc::util::text_divider text_list {\n#\s*@(?:public|private)\s+} ] } {
	
	# @private or @public directives were found, continue with parsing
    } else {
	
	return 0
    }

    # before parsing out the proc info, we'll deal with the comments for the namespace itself

    set namespace_comments [lindex $text_list 0 ]

    set parsed_namespace [template::parse_directives [template::util::quote_space $namespace_comments]]

    # just in case these variables aren't set from the comment text
    set namespace_author ""
    set namespace_see ""
    set has_comments 0

    foreach directive $parsed_namespace {
        set directive_type [lindex $directive 0]
        set directive_comments [template::util::comment_text_normalize [lindex $directive 1]]

        switch -exact $directive_type {

            namespace {

                set namespace_name [lindex $directive_comments 0]
                set namespace_description [lrange $directive_comments 1 end]
                if {$namespace_description ne "" } {
		    set has_comments 1
		}
            }

            see {
		doc::sort_@see namespace_$directive_type $directive_comments
		set has_comments 1
		
            }

            author {
                set namespace_author $directive_comments
		set has_comments 1
            }
        }
    }

    # the variable has_comments is set to 1 if it appears
    # as though descriptive comments were written to describe the namespace --
    # as would be expected if the namespace were being described 
    # for the first time; otherwise
    # it is set to 0;  the problem i'm trying to resolve here is multiple uses 
    # of the @namespace directive and determining which occurrence of the 
    # directive is followed by comments
    # by comments we want to parse into our static files

    # namespace_index tells us where to insert the info, or is -1 if 
    # the namespace has already been described
    set namespace_index [template::util::alphabetized_index $namespace_list $namespace_name]


    if { $namespace_index == -1 } {
        # this namespace is already recorded, so we will just add 
	# or revise info about its procs

        set namespace_entry [lindex $total_result_listing [lsearch -exact $namespace_list $namespace_name]]

	set namespace_info [lindex $namespace_entry 0 1]
	set namespace_public [lindex $namespace_entry 1 1]
	set namespace_private [lindex $namespace_entry 2 1]
		
    } else {
        set namespace_info [list name "$namespace_name" overview "$namespace_description" author "$namespace_author" see "$namespace_see"]
	set namespace_public ""
	set namespace_private ""
	
    }
    
    if { $has_comments } {
	
	# this check determines whether or not we want the comments
	# following this occurrence of the @namespace directive for 
	# this namespace to be included in our static files

        set namespace_info [list name "$namespace_name" overview "$namespace_description" author "$namespace_author" see "$namespace_see"]

    }

    set procedure_list [lrange $text_list 1 end]

    foreach proc_block $procedure_list {

	# each pro_block text block contains both the directive-marked comments and 
	# the source code for the procedyre
	doc::parse_comment_text $proc_block
    }

    if { $namespace_index >= 0 } {
	# if the namespace has not already been described, then we group all info together
	# {{info - name, overview} {public proc info} {private proc info}}
	# and insert it into the monster list of all namespaces

	set total_result_listing [linsert $total_result_listing $namespace_index [list [list info $namespace_info] [list public $namespace_public] [list private $namespace_private]]]
	
	set namespace_list [linsert $namespace_list $namespace_index $namespace_name]

    } else {
	
	# the name and overview info is already set, we'll just replace the augmented
	# listings for private and public procedures

        set namespace_index [lsearch -exact $namespace_list $namespace_name ]
	
	set total_result_listing [lreplace $total_result_listing $namespace_index $namespace_index [list [list info "$namespace_info"] [list public "$namespace_public"] [list private "$namespace_private"]]]
    }

}


ad_proc -private doc::parse_file { path } {
    Parse API documentation from a Tcl page
    API documentation is parsed as follows:
    <ul>
    <li>Document is scanned until a @namespace directive is encountered.
    The remainder of the file is scanned for @private or @public
    directives.
    <li>When one of these directives is encountered, the file is scanned up
    to a proc declaration and the text in between is parsed as documentation
    for a single procedure.  
    <li>The text between the initial @private or @public
    directive and the next directive is considered a general comment on
    the procedure
    </ul>
    Valid directives in a procedure doc include:
    <ul>
    <li>@author
    <li>@param (for hard parameters)
    <li>@see (should have the form namespace::procedure.  A reference to an
	    entire namespace should be namespace::.  By convention the
	    API for each namespace should be in a file of the same name, 
	    so that a link can be generated automatically).
    <li>@option (for switches such as -foo)
    <li>@return
    </ul>

    <p>
    Reads the text for a file and scans for a namespace directive.  When
    one is encountered, reads until the next namespace or EOF and calls
    doc::parse_namespace on the accumulated lines to get procedure
    documentation.
    <p>
    creates a multirow variable in the variable name designated by result_ref
    with columns namespace_name, proc_name, public_private, 
    author, param, option, see, return and source_text
    <p>
    Note that this format is suitable for passing to array set for
    creating a lookup on namespace name.
} {
  set text [template::util::read_file $path]

  if { [doc::util::text_divider text {\n#\s*@namespace\s+} ] } {

    # the @namespace directive was found, proceed with parsing through comment text
    set result_list [lrange $text 1 end]

    foreach namespace_body $result_list {
      doc::parse_namespace $namespace_body
    }

    return 1
  } else {

    # no @namespace directives found
    return 0
  }

}

ad_proc -private doc::parse_tcl_library { dir_list } {
    takes the absolute path of the Tcl library directory and parses through it

    @see doc::parse_file 
    @see template::util::comment_text_normalize


    @return a long lists of lists of lists, each list element contains 
    a three-element list of the format 

    - { {info} {public procedures listing } {private procedures listing}}
} {

  # namespace_list will be a list containing namespace names only, and should be ordered
  # with respect to namespaces in the same order as the list result

  upvar namespace_list namespace_list 
  set namespace_list [list]

  set result [list]

  foreach dir $dir_list {

      #debug
      #template::util::display_value dir

      # using this lame hack since most aD servers are running an earlier version of Tcl than 8.3,
      # which supports the -directory switch that this hack emulates
      append file_list [glob -nocomplain $dir/*.tcl $dir/*/*.tcl $dir/*/*/*.tcl $dir/*/*/*/*.tcl ]
      append file_list " "
  }

  #debugging
  #template::util::display_value file_list

  foreach tcl_file $file_list {
      ns_log notice "doc::parse_tcl_library: parsing through $tcl_file for documentation"
      
      set comments_parsed_p [doc::parse_file $tcl_file]
      if {! $comments_parsed_p } {
	 ns_log notice "doc::parse_tcl_library: no @namespace directives found in $tcl_file"
      }
  }

  return $result

}





# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
