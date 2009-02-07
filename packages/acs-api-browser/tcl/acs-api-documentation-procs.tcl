# /packages/acs-core/api-documentation-procs.tcl

ad_library {

    Routines for generating API documentation.

    @author Jon Salz (jsalz@mit.edu)
    @author Lars Pind (lars@arsdigita.com)
    @creation-date 21 Jun 2000
    @cvs-id $Id$

}

ad_proc -private api_first_sentence { string } {

    Returns the first sentence of a string.

} {

    if { [regexp {^(.+?\.)\s} $string "" sentence] } {
	return $sentence
    }
    return $string
}

ad_proc -public api_read_script_documentation {
    path
} {

    Reads the contract from a Tcl content page.

    @param path the path of the Tcl file to examine, relative to the
        OpenACS root directory.
    @return a list representation of the documentation element array, or
        an empty list if the file does not contain a <code>doc_page_contract</code>
        block.
    @error if the file does not exist.

} {
    # First, examine the file to determine whether the first non-comment
    # line begins with the string "ad_page_contract".
    set has_contract_p 0

    if { ![file exists "[acs_root_dir]/$path"] } {
	return -code error "File $path does not exist"
    }

    set file [open "[acs_root_dir]/$path" "r"]
    while { [gets $file line] >= 0 } {
	# Eliminate any comment characters.
	regsub -all {#.*$} $line "" line
	set line [string trim $line]
	if { $line ne "" } {
	    set has_contract_p [regexp {^ad_page_contract\s} $line]
	    break
	}
    }
    close $file

    if { !$has_contract_p } {
	return [list]
    } 

    doc_set_page_documentation_mode 1
    set errno [catch { source "[acs_root_dir]/$path" } error]
    doc_set_page_documentation_mode 0
    if { $errno == 1 } {
	global errorInfo
	if { [regexp {^ad_page_contract documentation} $errorInfo] } {
	    array set doc_elements $error
	}
    } else {
	global errorCode
	global errorInfo
	return -code $errno -errorcode $errorCode -errorinfo $errorInfo $error
 }

    if { [info exists doc_elements] } {
	return [array get doc_elements]
    }
    return [list]
}
    
ad_proc -private api_format_see_list { sees } { 
    Generate an HTML list of referenced procs and pages.
} { 
    append out "<br><strong>See Also:</strong>\n<ul>"
    foreach see $sees { 
	append out "<li>[api_format_see $see]\n"
    }
    append out "</ul>\n"
     
    return $out
}
    
ad_proc -private api_format_author_list { authors } {

    Generates an HTML-formatted list of authors (including <code>&lt;dt&gt;</code> and
    <code>&lt;dd&gt;</code> tags).

    @param authors the list of author strings.
    @return the formatted list, or an empty string if there are no authors.

} {
    if { [llength $authors] == 0 } {
	return ""
    }
    append out "<dt><b>Author[ad_decode [llength $authors] 1 "" "s"]:</b>\n"
    foreach author $authors {
	append out "<dd>[api_format_author $author]</dd>\n"
    }
    return $out
}


ad_proc -private api_format_changelog_change { change } {
    Formats the change log line: turns email addresses in parenthesis into links.
} { 
    regsub {\(([^ \n\r\t]+@[^ \n\r\t]+\.[^ \n\r\t]+)\)} $change {(<a href="mailto:\1">\1</a>)} change
    return $change
}

ad_proc -private api_format_changelog_list { changelog } {
    Format the change log info
} {
    append out "<dt><b>Changelog:</b>\n"
    foreach change $changelog {
	append out "<dd>[api_format_changelog_change $change]</dd>\n"
    }
    return $out
}


ad_proc -private api_format_common_elements { doc_elements_var } {
    upvar $doc_elements_var doc_elements

    set out ""

    if { [info exists doc_elements(author)] } {
	append out [api_format_author_list $doc_elements(author)]
    }
    if { [info exists doc_elements(creation-date)] } {
	append out "<dt><b>Created:</b>\n<dd>[lindex $doc_elements(creation-date) 0]</dd>\n"
    }
    if { [info exists doc_elements(change-log)] } {
	append out [api_format_changelog_list $doc_elements(change-log)]
    }
    if { [info exists doc_elements(cvs-id)] } {
	append out "<dt><b>CVS ID:</b>\n<dd><code>[ns_quotehtml [lindex $doc_elements(cvs-id) 0]]</code></dd>\n"
    }
    if { [info exists doc_elements(see)] } {
	append out [api_format_see_list $doc_elements(see)]
    }

    return $out
}



ad_proc -public api_script_documentation {
    { -format text/html }
    path
} {

    Generates formatted documentation for a content page. Sources the file
    to obtain the comment or contract at the beginning.

    @param format the type of documentation to generate. Currently, only
        <code>text/html</code> is supported.
    @param path the path of the Tcl file to examine, relative to the
        OpenACS root directory.
    @return the formatted documentation string.
    @error if the file does not exist.

} {
    append out "<h3>[file tail $path]</h3>\n"

    # If it's not a Tcl file, we can't do a heck of a lot yet. Eventually
    # we'll be able to handle ADPs, at least.
    if {[file extension $path] eq ".xql"} {
	append out "<blockquote>DB Query file</blockquote>\n"
	return $out
    } elseif { [file extension $path] ne ".tcl" } {
	append out "<blockquote><i>Delivered as [ns_guesstype $path]</i></blockquote>\n"
	return $out
    }

    if { [catch { array set doc_elements [api_read_script_documentation $path] } error] } {
	append out "<blockquote><i>Unable to read $path: [ns_quotehtml $error]</i></blockquote>\n"
	return $out
    }

    array set params [list]

    if { [info exists doc_elements(param)] } {
	foreach param $doc_elements(param) {
	    if { [regexp {^([^ \t]+)[ \t](.+)$} $param "" name value] } {
		set params($name) $value
	    }
	}
    }
	
    append out "<blockquote>"
    if { [info exists doc_elements(main)] } {
	append out [lindex $doc_elements(main) 0]
    } else {
	append out "<i>Does not contain a contract.</i>"
    }
    append out "<dl>\n"
    # XXX: This does not work at the moment. -bmq
#     if { [array size doc_elements] > 0 } {
#         array set as_flags $doc_elements(as_flags)
# 	array set as_filters $doc_elements(as_filters)
#         array set as_default_value $doc_elements(as_default_value)

#         if { [llength $doc_elements(as_arg_names)] > 0 } {
# 	    append out "<dt><b>Query Parameters:</b><dd>\n"
# 	    foreach arg_name $doc_elements(as_arg_names) {
# 		append out "<b>$arg_name</b>"
# 		set notes [list]
# 		if { [info exists as_default_value($arg_name)] } {
# 		    lappend notes "defaults to <code>\"$as_default_value($arg_name)\"</code>"
# 		} 
#  		set notes [concat $notes $as_flags($arg_name)]
# 		foreach filter $as_filters($arg_name) {
# 		    set filter_proc [ad_page_contract_filter_proc $filter]
# 		    lappend notes "<a href=\"[api_proc_url $filter_proc]\">$filter</a>"
# 		}
# 		if { [llength $notes] > 0 } {
# 		    append out " ([join $notes ", "])"
# 		}
# 		if { [info exists params($arg_name)] } {
# 		    append out " - $params($arg_name)"
# 		}
# 		append out "<br>\n"
# 	    }
# 	    append out "</dd>\n"
# 	}
# 	if { [info exists doc_elements(type)] && $doc_elements(type) ne "" } {
# 	    append out "<dt><b>Returns Type:</b><dd><a href=\"type-view?type=$doc_elements(type)\">$doc_elements(type)</a>\n"
# 	}
# 	# XXX: Need to support "Returns Properties:"
#     }
    append out "<dt><b>Location:</b><dd>$path\n"
    append out [api_format_common_elements doc_elements]

    append out "</dl></blockquote>"

    return $out
}

ad_proc -private api_format_author { author_string } {
    if { [regexp {^[^ \n\r\t]+$} $author_string] && \
	    [string first "@" $author_string] >= 0 && \
	    [string first ":" $author_string] < 0 } {
	return "<a href=\"mailto:$author_string\">$author_string</a>"
    } elseif { [regexp {^([^\(\)]+)\s+\((.+)\)$} [string trim $author_string] {} name email] } {
	return "$name &lt;<a href=\"mailto:$email\">$email</a>&gt;"
    }
    return $author_string
}

ad_proc -private api_format_see { see } {
    regsub -all {proc *} $see {} see
    set see [string trim $see]
    if {[nsv_exists api_proc_doc $see]} {
        return "<a href=\"proc-view?proc=[ns_urlencode ${see}]\">$see</a>"
    }
    if {[string match "/doc/*.html" $see]
        || [util_url_valid_p $see]} { 
        return "<a href=\"${see}]\">$see</a>"
    }
    if {[file exists "[get_server_root]${see}"]} {
        return "<a href=\"content-page-view?source_p=1&path=[ns_urlencode $see]\">$see</a>"
    }
    return ${see}
}

ad_proc -public api_library_documentation {
    { -format text/html }
    path
} {

    Generates formatted documentation for a Tcl library file (just the header,
    describing what the library does).

    @param path the path to the file, relative to the OpenACS path root.

} {
    if { $format ne "text/html" } {
	return -code error "Only text/html documentation is currently supported"
    }

    set out "<h3>[file tail $path]</h3>"
    
    if { [nsv_exists api_library_doc $path] } {
	array set doc_elements [nsv_get api_library_doc $path]
	append out "<blockquote>\n"
	append out [lindex $doc_elements(main) 0]

	append out "<dl>\n"
	append out "<dt><b>Location:</b>\n<dd>$path\n"
	if { [info exists doc_elements(creation-date)] } {
	    append out "<dt><b>Created:</b>\n<dd>[lindex $doc_elements(creation-date) 0]\n"
	}
	if { [info exists doc_elements(author)] } {
	    append out "<dt><b>Author[ad_decode [llength $doc_elements(author)] 1 "" "s"]:</b>\n"
	    foreach author $doc_elements(author) {
		append out "<dd>[api_format_author $author]\n"
	    }
	}
	if { [info exists doc_elements(cvs-id)] } {
	    append out "<dt><b>CVS Identification:</b>\n<dd><code>[ns_quotehtml [lindex $doc_elements(cvs-id) 0]]</code>\n"
	}
	append out "</dl>\n"
	append out "</blockquote>\n"
    }

    return $out
}

ad_proc -public api_type_documentation {
    type
} {
    @return html fragment of the api docs.
} {
    array set doc_elements [nsv_get doc_type_doc $type]
    append out "<h3>$type</h3>\n"

    array set properties [nsv_get doc_type_properties $type]

    append out "<blockquote>[lindex $doc_elements(main) 0]

<dl>
<dt><b>Properties:</b>
<dd>
"

    array set property_doc [list]
    if { [info exists doc_elements(property)] } {
	foreach property $doc_elements(property) {
	    if { [regexp {^([^ \t]+)[ \t](.+)$} $property "" name value] } {
		set property_doc($name) $value
	    }
	}
    }

    foreach property [lsort [array names properties]] {
	set info $properties($property)
	set type [lindex $info 0]
	append out "<b>$property</b>"
	if { $type ne "onevalue" } {
	    append out " ($type)"
	}
	if { [info exists property_doc($property)] } {
	    append out " - $property_doc($property)"
	}
	if {$type eq "onerow"} {
	    append out "<br>\n"
	} else {
	    set columns [lindex $info 1]
	    append out "<ul type=disc>\n"
	    foreach column $columns {
		append out "<li><b>$column</b>"
		if { [info exists property_doc($property.$column)] } {
		    append out " - $property_doc($property.$column)"
		}
	    }
	    append out "</ul>\n"
	}
    }

    append out [api_format_common_elements doc_elements]

    append out "<dt><b>Location:</b><dd>$doc_elements(script)\n"

    append out "</dl></blockquote>\n"

    return $out
}

ad_proc -private api_set_public {
    version_id
    { public_p "" }
} {
    
    Gets or sets the user's public/private preferences for a given
    package.

    @param version_id the version of the package
    @param public_p if empty, return the user's preferred setting or the default (1) if no preference found. If not empty, set the user's preference to public_p
    @return public_p

} {
    set public_property_name "api,package,$version_id,public_p"
    if { $public_p eq "" } {
	set public_p [ad_get_client_property acs-api-browser $public_property_name]
	if { $public_p eq "" } {
	    set public_p 1
	}
    } else {
	ad_set_client_property acs-api-browser $public_property_name $public_p
    }
    return $public_p
}

ad_proc -public api_quote_file {
    filename 
} { 
    returns a quoted version of the given filename 
} { 
    if {![catch {set fp [open $filename r]} err]} { 
        set content [ad_quotehtml [read $fp]]
        close $fp
        return $content
    } 
    return {}
} 


ad_proc -public api_proc_documentation {
	{-format text/html}
	-script:boolean
	-source:boolean
	-xql:boolean
        -label
        {-first_line_tag <h3>}
	proc_name
} {

	Generates formatted documentation for a procedure.

	@param format the type of documentation to generate. Currently, only
		<code>text/html</code> and <code>text/plain</code> are supported.
	@param script include information about what script this proc lives in?
	@param xql include the source code for the related xql files?
	@param source include the source code for the script?
	@param proc_name the name of the procedure for which to generate documentation.
	@param label the label printed for the proc in the header line
	@param first_line_tag tag for the markup of the first line
	@return the formatted documentation string.
	@error if the procedure is not defined.	   
} {
	if { $format ne "text/html" && \
			$format ne "text/plain" } {
		return -code error "Only text/html and text/plain documentation are currently supported"
	}
	array set doc_elements [nsv_get api_proc_doc $proc_name]
	array set flags $doc_elements(flags)
	array set default_values $doc_elements(default_values)

        if {![info exists label]} {
	        set label $proc_name
        }
	if { $script_p } {
                set pretty_name [api_proc_pretty_name -label $label $proc_name]
	} else {
                set pretty_name [api_proc_pretty_name -link -label $label $proc_name]
	}
        if {[regexp {<([^ >]+)} $first_line_tag match tag]} {
	        set end_tag "</$tag>"
	} else {
	        set first_line_tag "<h3>"
	        set end_tag "</h3>"
	}
        append out $first_line_tag$pretty_name$end_tag
        
        if {[regexp {^(.*) (inst)?proc (.*)$} $proc_name match cl prefix method]} {
	  set xotcl 1
	  set scope ""
	  if {[regexp {^(.+) (.+)$} $cl match scope cl]} {
	    set cl "$scope do $cl"
	  }
	  if {$prefix eq ""} {
	    set pretty_proc_name "[::xotcl::api object_link $scope $cl] $method"
	  } else {
	    set pretty_proc_name \
		"<i>&lt;instance of\
		[::xotcl::api object_link $scope $cl]&gt;</i> $method"
	  }
	} else {
	  set xotcl 0
          set pretty_proc_name $proc_name
	}

	lappend command_line $pretty_proc_name
	foreach switch $doc_elements(switches) {
	  if {$xotcl} {
	    if { [lsearch $flags($switch) "boolean"] >= 0} {
	      set value "<i>on|off</i> "
	    } elseif { [lsearch $flags($switch) "switch"] >= 0} {
	      set value ""
	    } else {
	      set value "</i>$switch</i> "
	    }
	    if { [lsearch $flags($switch) "required"] >= 0} {
	      lappend command_line "-$switch $value"
	    } else {
	      lappend command_line "\[ -$switch $value\]"
	    }
	  } else {
	    if { [lsearch $flags($switch) "boolean"] >= 0} {
	                lappend command_line "\[ -$switch \]"
		} elseif { [lsearch $flags($switch) "required"] >= 0 } {
			lappend command_line "-$switch <i>$switch</i>"
		} else {
			lappend command_line "\[ -$switch <i>$switch</i> \]"
		}
	  }
	}
	
	set counter 0
	foreach positional $doc_elements(positionals) {
		if { [info exists default_values($positional)] } {
			lappend command_line "\[ <i>$positional</i> \]"
		} else {
			lappend command_line "<i>$positional</i>"
		}
	}
	if { $doc_elements(varargs_p) } {
		lappend command_line "\[ <i>args</i>... \]"
	}
	append out "[util_wrap_list $command_line]\n<blockquote>\n"
	
	if { $script_p } {
		append out "Defined in <a href=\"/api-doc/procs-file-view?path=[ns_urlencode $doc_elements(script)]\">$doc_elements(script)</a><p>"
	}
	
	if { $doc_elements(deprecated_p) } {
		append out "<b><i>Deprecated."
		if { $doc_elements(warn_p) } {
			append out " Invoking this procedure generates a warning."
		}
		append out "</i></b><p>\n"
	}

	append out "[lindex $doc_elements(main) 0]
	
<p>
<dl>
"

        if { [info exists doc_elements(param)] } {
            foreach param $doc_elements(param) {
                if { [regexp {^([^ \t\n]+)[ \t\n]+(.*)$} $param "" name value] } {
                    set params($name) $value
                }
            }
	}
	
	if { [llength $doc_elements(switches)] > 0 } {
		append out "<dt><b>Switches:</b></dt><dd><dl>\n"
		foreach switch $doc_elements(switches) {
			append out "<dt><b>-$switch</b>"
			if { [lsearch $flags($switch) "boolean"] >= 0 } {
				append out " (boolean)"
			} 
			
			if { [info exists default_values($switch)] && \
					$default_values($switch) ne "" } {
				append out " (defaults to <code>\"$default_values($switch)\"</code>)"
			} 
			
			if { [lsearch $flags($switch) "required"] >= 0 } {
				append out " (required)"
			} else {
				append out " (optional)"
			}
			append out "</dt>"
			if { [info exists params($switch)] } {
				append out "<dd>$params($switch)</dd>"
			}
		}
		append out "</dl></dd>\n"
	}
	
	if { [llength $doc_elements(positionals)] > 0 } {
		append out "<dt><b>Parameters:</b></dt><dd>\n"
		foreach positional $doc_elements(positionals) {
			append out "<b>$positional</b>"
			if { [info exists default_values($positional)] } {
				if { $default_values($positional) eq "" } {
					append out " (optional)"
				} else {
					append out " (defaults to <code>\"$default_values($positional)\"</code>)"
				}
			}
			if { [info exists params($positional)] } {
				append out " - $params($positional)"
			}
			append out "<br>\n"
		}
		append out "</dd>\n"
	}
	

        # @option is used in  template:: and cms:: (and maybe should be used in some other 
        # things like ad_form which have internal arg parsers.  although an option 
        # and a switch are the same thing, just one is parsed in the proc itself rather than 
        # by ad_proc.

	if { [info exists doc_elements(option)] } {
		append out "<b>Options:</b><dl>"
		foreach param $doc_elements(option) {
			if { [regexp {^([^ \t]+)[ \t](.+)$} $param "" name value] } {
                            append out "<dt><b>-$name</b></dt><dd>$value<br></dd>"
			}
		}
		append out "</dl>"
	}
	

	if { [info exists doc_elements(return)] } {
		append out "<dt><b>Returns:</b></dt><dd>[join $doc_elements(return) "<br>"]</dd>\n"
	}
	
	if { [info exists doc_elements(error)] } {
		append out "<dt><b>Error:</b></dt><dd>[join $doc_elements(error) "<br>"]</dd>\n"
	}
	
	append out [api_format_common_elements doc_elements]
	
	if { $source_p } {
		if {[parameter::get_from_package_key \
                         -package_key acs-api-browser \
                         -parameter FancySourceFormattingP \
                         -default 1]} {
			append out "<dt><b>Source code:</b></dt><dd>
<pre>[api_tcl_to_html $proc_name]<pre>
</dd><p>\n"
		} else {
		append out "<dt><b>Source code:</b></dt><dd>
<pre>[ns_quotehtml [api_get_body $proc_name]]<pre>
</dd><p>\n"
	        }
        }

	set xql_base_name [get_server_root]/
	append xql_base_name [file rootname $doc_elements(script)]
	if { $xql_p } {
                set there {}
                set missing {}
		if { [file exists ${xql_base_name}.xql] } {
			append there "<dt><b>Generic XQL file:</b></dt>
<blockquote>[api_quote_file ${xql_base_name}.xql]</blockquote>
<p>\n"
		} else {
                      lappend missing Generic
		}
		if { [file exists ${xql_base_name}-postgresql.xql] } {
			append there "<dt><b>Postgresql XQL file:</b></dt>
<blockquote>[api_quote_file ${xql_base_name}-postgresql.xql]</blockquote>
<p>\n"
		} else {
                      lappend missing PostgreSQL
		}
		if { [file exists ${xql_base_name}-oracle.xql] } {
			append there "<dt><b>Oracle XQL file:</b></dt>
<blockquote>[api_quote_file ${xql_base_name}-oracle.xql]</blockquote>
<p>\n"
		} else {
                    lappend missing Oracle
		}
                if {[llength $missing] > 0} { 
		    append out "<dt><b>XQL Not present:</b></dt><dd>[join $missing ", "]</dd>"
                }
                append out $there  
	}

	# No "see also" yet.
	
	append out "</dl></blockquote>"
	
	return $out
}

ad_proc api_proc_pretty_name { 
    -link:boolean
    -label
    proc 
} {
    Return a pretty version of a proc name
   @param label the label printed for the proc in the header line
   @param link provide a link to the documentation pages
} {
    if {![info exists label]} {
        set label $proc
    }
    if { $link_p } {
	append out "<a href=\"[api_proc_url $proc]\">$label</a>"
    } else {	
	append out "$label"
    }
    array set doc_elements [nsv_get api_proc_doc $proc]
    if { $doc_elements(public_p) } {
	append out " (public)"
    }
    if { $doc_elements(private_p) } {
	append out " (private)"
    }
    return $out
}

ad_proc -private ad_sort_by_score_proc {l1 l2} {
    basically a -1,0,1 result comparing the second element of the
    list inputs then the first. (second is int)
} {
    if {[lindex $l1 1] == [lindex $l2 1]} {
	return [string compare [lindex $l1 0] [lindex $l2 0]]
    } else {
	if {[lindex $l1 1] > [lindex $l2 1]} {
	    return -1
	} else {
	    return 1
	}
    }
}

ad_proc -private ad_sort_by_second_string_proc {l1 l2} {
    basically a -1,0,1 result comparing the second element of the
    list inputs then the first (both strings)
} {
    if {[lindex $l1 1] eq [lindex $l2 1]} {
	return [string compare [lindex $l1 0] [lindex $l2 0]]
    } else {
	return [string compare [lindex $l1 1] [lindex $l2 1]]
    }
}

ad_proc -private ad_sort_by_first_string_proc {l1 l2} {
    basically a -1,0,1 result comparing the second element of the
    list inputs then the first.  (both strings)
} {
    if {[lindex $l1 0] eq [lindex $l2 0]} {
	return [string compare [lindex $l1 1] [lindex $l2 1]]
    } else {
	return [string compare [lindex $l1 0] [lindex $l2 0]]
    }
}

ad_proc -private ad_keywords_score {keywords string_to_search} {
    returns number of keywords found in string to search.  
    No additional score for repeats
} {
    # turn keywords into space-separated things
    # replace one or more commads with a space
    regsub -all {,+} $keywords " " keywords
    
    set score 0
    foreach word $keywords {
	# turns out that "" is never found in a search, so we
	# don't really have to special case $word eq ""
	if {[string match -nocase "*$word*" $string_to_search]} {
	    incr score
	}
    }
    return $score
}

ad_proc -public api_apropos_functions { string } {
    Returns the functions in the system that contain string in their name 
    and have been defined using ad_proc.
} {
    set matches [list]
    foreach function [nsv_array names api_proc_doc] {
        if {[string match -nocase *$string* $function]} {
            array set doc_elements [nsv_get api_proc_doc $function]
            lappend matches [list "$function" "$doc_elements(positionals)"]
        }
    }
    return $matches
}

ad_proc -public api_describe_function { 
    { -format text/plain }
    proc 
} {
    Describes the functions in the system that contain string and that
    have been defined using ad_proc.  The description includes the
    documentation string, if any.
} {
    set matches [list]
    foreach function [nsv_array names api_proc_doc] {
        if {[string match -nocase $proc $function]} {
            array set doc_elements [nsv_get api_proc_doc $function]
            switch $format {
                text/plain {
                    lappend matches [ad_html_to_text -- [api_proc_documentation -script $function]]
                }
                default {
                    lappend matches [api_proc_documentation -script $function]
                }
            }                    
        }
    }
    switch $format {
        text/plain {
            set matches [join $matches "\n"]
        }
        default {
            set matches [join $matches "\n<p>\n"]
        }
    }
    return $matches
}

ad_proc -private api_is_xotcl_object {scope proc_name} {
  Checks, whether the specified argument is an xotcl object.
  Does not cause problems when xocl is not loaded.
  @return boolean value
} {
  set result 0
  if {[string match "::*" $proc_name]} { ;# only check for absolute names
    catch {set result [::xotcl::api inscope $scope ::xotcl::Object isobject $proc_name]}
  }
  return $result
}

ad_proc -public api_get_body {proc_name} {
  This function returns the body of a tcl proc or an xotcl method.
  @param proc_name the name spec of the proc
  @return body of the specified prox
} {

  if {[regexp {^(.*) (inst)?proc (.*)$} $proc_name match obj prefix method]} {
    if {[regexp {^(.*) (.*)$} $obj match thread obj]} {
      # the definition is located in a disconnected thread
      return [$thread do ::Serializer methodSerialize $obj $method $prefix]
    } else {
      # the definition is locally in the connection thread
      return [::Serializer methodSerialize $obj $method $prefix]
    }
  } elseif {[regexp {^([^ ]+)(Class|Object) (.*)$} $proc_name match thread kind obj]} {
    return [$thread do $obj serialize]
  } else {
    return [info body $proc_name]
  }
}


ad_proc -private api_tcl_to_html {proc_name} {

    Given a proc name, formats it as HTML, including highlighting syntax in
    various colors and creating hyperlinks to other proc definitions.<BR>
    The inspiration for this proc was the tcl2html script created by Jeff Hobbs.
<P>
    Known Issues:
<OL>
<LI> This proc will mistakenly highlight switch strings that look like commands as commands, etc.
<LI> There are many undocumented AOLserver commands including all of the commands added by modules.
<LI> When a proc inside a string has explicitly quoted arguments, they are not formatted.
<LI> regexp and regsub are hard to parse properly.  E.g. If we use the start option, and we quote its argument,
     and we have an ugly regexp, then this code might highlight it incorrectly.
</OL>

    @author Jamie Rasmussen (jrasmuss@mle.ie)

    @param proc_name procedure to format in HTML

} {

    if {[info command ::xotcl::api] ne ""} {
      set scope [::xotcl::api scope_from_proc_index $proc_name]
    } else {
      set scope ""
    }

    set proc_namespace ""
    regexp {^(::)?(.*)::[^:]+$} $proc_name match colons proc_namespace

    return [api_tclcode_to_html -scope $scope -proc_namespace $proc_namespace [api_get_body $proc_name]]
}

ad_proc -private api_tclcode_to_html {{-scope ""} {-proc_namespace ""} script} {

    Given a script, this proc formats it as HTML, including highlighting syntax in
    various colors and creating hyperlinks to other proc definitions.<BR>
    The inspiration for this proc was the tcl2html script created by Jeff Hobbs.

    @param script script to be formated in HTML

} {

    # Returns length of a variable name
    proc length_var {data} {
        if {[regexp -indices {^\$\{[^\}]+\}} $data found]} {
            return [lindex $found 1]           
        } elseif {[regexp -indices {^\$[A-Za-z0-9_]+(\([\$A-Za-z0-9_\-/]+\))?} $data found]} {
            return [lindex $found 1]
        }
        return 0
    }

    # Returns length of a command name
    proc length_proc {data} {
        if {[regexp -indices {^(::)?[A-Za-z][:A-Za-z0-9_@]+} $data found]} {
            return [lindex $found 1]
        }
        return 0
    }

    # Returns length of subexpression, from open to close quote inclusive
    proc length_string {data} {
        regexp -indices {[^\\]\"} $data match
        return [expr {[lindex $match 1]+1}]
    }

    # Returns length of subexpression, from open to close brace inclusive
    # Doesn't deal with unescaped braces in substrings
    proc length_braces {data} {
        set i 1
        for {set count 1} {1} {incr i} {
            if {[string index $data $i] eq "\\"} {
                incr i
            } elseif {[string index $data $i] eq "\{"} {
                incr count            
            } elseif {[string index $data $i] eq "\}"} {
                incr count -1
            }
            if {!$count} { break }
        }
        return [expr {$i+1}]
    }

    # Returns number of spaces until next subexpression
    proc length_spaces {data} {
        regexp -indices {\s+} $data match
        return [expr {[lindex $match 1]+1}]
    }

    # Returns length of a generic subexpression
    proc length_exp {data} {
        if {[string index $data 0] eq "\""} {
            return [length_string $data]
        } elseif {[string index $data 0] eq "\{"} {
            return [length_braces $data]
        } elseif {[string index $data 0] eq " "} {
            return [length_spaces $data]
        }
        if { [regexp -indices { } $data match] } {
            return [lindex $match 1]
        }
        return 0
    }

    # Calculate how much text we should ignore
    proc length_regexp {data} {
        set i 0
        set found_regexp 0
        set curchar [string index $data $i]
        while {$curchar != "\$" && $curchar != "\[" &&
               ($curchar ne "\{" || !$found_regexp)} {
            if {$curchar eq "\{"} {set found_regexp 1}
            if {[string match "-start" [string range $data $i [expr {$i+5}]]]} {
                incr i [length_exp [string range $data $i end]] ;# -start
                incr i [length_exp [string range $data $i end]] ;# spaces
                incr i [length_exp [string range $data $i end]] ;# expression - it could be a var
            }
            incr i [length_exp [string range $data $i end]]
            set curchar [string index $data $i]
        }
        return [expr {$i -1}]
    }

    array set HTML {
        comment   {<EM><FONT color=#006600>}
        /comment  {</FONT></EM>}
        procs     {<FONT color=#0000CC>}
        /procs    {</FONT>}
        str       {<FONT color=#990000>}
        /str      {</FONT>}
        var       {<FONT color=#660066>}
        /var      {</FONT>}
        object	  {<FONT color=#000066><b>}
        /object	  {</b></FONT>}
    }

    # Keywords will be colored as other procs, but not hyperlinked
    # to api-doc pages.  Perhaps we should hyperlink them to the TCL man pages?
    # else and elseif are be treated as special cases later

    set KEYWORDS [concat \
        {if while foreach for switch default} \
        {after break continue return error catch} \
        {upvar uplevel eval exec source variable namespace package load} \
        {set unset trace append global vwait split join} \
        {concat list lappend lset lindex linsert llength lrange lreplace lsearch lsort} \
        {info incr expr regexp regsub binary} \
        {string array open close read cd pwd glob seek pid} \
        {file fblocked fcopy fconfigure fileevent filename flush eof} \
        {clock encoding proc rename subst update} \
        {gets puts socket tell format scan} \
        ]

    if {[info command ::xotcl::api] ne ""} {
      set XOTCL_KEYWORDS [list self my next]
      # only command names are highlighted, otherwise we could add xotcl method
      # names by [lsort -unique [concat [list self my next] ..
      # [::xotcl::Object info methods] [::xotcl::Class info methods] ]]
    } else {
      set XOTCL_KEYWORDS {}
    }

    # Returns a list of the commands from all namespaces.
    proc list_all_procs {{parentns ::}} {
        set result [info commands ${parentns}::*]
        foreach ns [namespace children $parentns] {
            set result [concat $result [list_all_procs $ns]]
        }
        return $result
    }
    set COMMANDS [list_all_procs]

    set data [string map [list & "&amp;" < "&lt;" > "&gt;"] \n$script]

    set in_comment 0
    set in_quotes 0
    set proc_ok 1
    set l [string length $data]
    for {set i 0} {$i < $l} {incr i} {
        set char [string index $data $i]
        switch -- $char {

        "\\" {
            append html [string range $data $i [incr i]]
            # This might have been a backslash added to escape &, <, or >.
            if {[regexp {^(amp;|lt;|gt;)} [string range $data $i end] match esc]} {
                append html $esc
                incr i [string length $esc]
            }
        }

        "\$" {
            if {$in_comment || ([string index $data [expr {$i + 1}]] == " ")} {
                append html "\$"
            } else {
                set varl [length_var [string range $data $i end]]
                append html "$HTML(var)[string range $data $i [expr {$i + $varl}]]$HTML(/var)"
                incr i $varl
            }
        }

        "\"" {
            if {$in_comment} {
                append html "\""
            } elseif {$in_quotes} {
                append html \"$HTML(/str)
                set in_quotes 0
            } else {
                append html $HTML(str)\"
                set in_quotes 1
                set proc_ok 0
            }
        }

        "\#" {
            set prevchar [string index $data [expr {$i-1}]]
            if {$proc_ok && !$in_comment && [regexp {[\s;]} $prevchar]} {
                set in_comment 1
                set proc_ok 0
                append html $HTML(comment)
            }
            append html "#"
        }

        "\n" {
            set proc_ok 1
            if {$in_quotes} {
                set proc_ok 0
            }
            if {$in_comment} {
                append html $HTML(/comment)
            }
            append html "\n"
            set in_comment 0
        }

        "\{" -
        ";" {
            if {!$in_quotes} {
                set proc_ok 1
            }
            append html $char
        }

        "\}" {
            append html "\}"
            # Special case else and elseif
            if {[regexp {^\}(\s*)(else|elseif)(\s*\{)} [string range $data $i end] match pre els post]} {
                append html "${pre}$HTML(procs)${els}$HTML(/procs)${post}"
                set proc_ok 1
                incr i [expr [string length $pre] + \
                             [string length $els] + \
                             [string length $post]]
            }
        }

        "\[" {
            if {!$in_comment} {
                set proc_ok 1
            }
            append html "\["
        }

        " " {
            append html " "
        }
        
        default {
            if {$proc_ok} {
                set proc_ok 0
                set procl [length_proc [string range $data $i end]]
                set proc_name [string range $data $i [expr {$i + $procl}]]

	        if {[lsearch -exact $KEYWORDS $proc_name] != -1 ||
                    ([regexp {^::(.*)} $proc_name match had_colons] && 
		     [lsearch -exact $KEYWORDS $had_colons] != -1)} {
		  append html "$HTML(procs)${proc_name}$HTML(/procs)"
                } elseif {[lsearch -exact $XOTCL_KEYWORDS $proc_name] != -1 } {
		  append html "$HTML(procs)${proc_name}$HTML(/procs)"
                } elseif {[api_is_xotcl_object $scope $proc_name]} {
		  set url [::xotcl::api object_url \
			       -show_source 1 -show_methods 2 \
			       $scope $proc_name]
		  append html "<A style='text-decoration:none' href=\
			'$url'>$HTML(object)${proc_name}$HTML(/object)</A>"
                } elseif {[string match "ns*" $proc_name]} {
		  set url "/api-doc/tcl-proc-view?tcl_proc=$proc_name"
		  append html "<A style='text-decoration:none' href=\
 			'$url'>$HTML(procs)${proc_name}$HTML(/procs)</A>"
                } elseif {[string match "*__arg_parser" $proc_name]} {
		  append html "$HTML(procs)${proc_name}$HTML(/procs)"
                } elseif {[lsearch -exact $COMMANDS ::${proc_namespace}::${proc_name}] != -1}  {
		  set url [api_proc_url ${proc_namespace}::${proc_name}]
		  append html "<A style='text-decoration:none' href=\
			'$url'>$HTML(procs)${proc_name}$HTML(/procs)</A>"
                } elseif {[lsearch -exact $COMMANDS ::$proc_name] != -1}  {
		  set url [api_proc_url $proc_name]
		  append html "<A style='text-decoration:none' href=\
			'$url'>$HTML(procs)${proc_name}$HTML(/procs)</A>"
                } else {
		  append html ${proc_name}
		  set proc_ok 1
                }
                incr i $procl

                # Hack for nasty regexp stuff
                if {"regexp" eq $proc_name || "regsub" eq $proc_name} {
                    set regexpl [length_regexp [string range $data $i end]]
                    append html [string range $data [expr {$i+1}] [expr {$i + $regexpl}]]
                    incr i $regexpl
                }
            } else {
                append html $char
                set proc_ok 0
            }
        }
        }
    }

    # We added a linefeed at the beginning to simplify processing
    return [string range $html 1 end]
}



####################
#
# Linking to api-documentation
#
####################

#
# procs for linking to libraries, pages, etc, should go here too.
#

ad_proc api_proc_url { proc } {
    Returns the URL of the page that documents the given proc.

    @author Lars Pind (lars@pinds.com)
    @creation-date 14 July 2000
} {
    return "/api-doc/proc-view?proc=[ns_urlencode $proc]"
}

ad_proc api_proc_link { proc } {
    Returns a full HTML link to the documentation for the proc.

    @author Lars Pind (lars@pinds.com)
    @creation-date 14 July 2000
} {
    return "<a href=\"[api_proc_url $proc]\">$proc</a>"
}

ad_proc -private api_xql_links_list { path } {
    
    Returns list of xql files related to tcl script file
    @param path path and filename from [acs_root_dir]
    
    
} {
    
    set linkList [list]
    set filename "[acs_root_dir]/$path"
    set path_dirname [file dirname $path]
    set file_dirname [file dirname $filename]
    set file_rootname [file rootname [file tail $filename]]
    regsub {(-oracle|-postgresql)$} $file_rootname {} file_rootname
    set files \
        [lsort -decreasing \
             [glob -nocomplain \
                  -directory $file_dirname \
                  "${file_rootname}{,-}{,oracle,postgresql}.{adp,tcl,xql}" ]]
    
    foreach file $files {
        lappend linkList [list \
                              filename $file \
                              link "content-page-view?source_p=1&path=[ns_urlencode "$path_dirname/[file tail $file]"]" \
                              ]
                          
    }

    return $linkList
    
}
