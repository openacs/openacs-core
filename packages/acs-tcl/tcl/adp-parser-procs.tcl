ad_library {

    Routines for a pure-Tcl parser supporting an ADP-like syntax.
    Tags are registered with <code>doc_register_adptag</code>.
    To use the parser, either

    <ul>
    <li>Use <code>doc_adp_execute -file</code> to execute an ADP
      file, or
    <li>Compile an ADP using <code>doc_adp_compile</code>, and use
      <code>doc_adp_execute</code> to executed the compiled ADP.
    </ul>

    Differences from the standard ADP parser include:

    <ul>
    <li>In handlers for balanced tags (<code>&lt;some-tag&gt; ... &lt;/some-tag&gt;</code>),
      the second argument is not an ADP string, but rather with a handle
      to ADP code which should be executed with <code>doc_adp_execute</code>
      in order for the handler to recursively evaluate code.
    <li>ADPs are never evaluated in the same stack frame as when <code>doc_adp_execute</code>
      is invoked; each recursively executed ADP code receives its own stack frame as well.
      This can probably be worked around, if necessary, with a little <code>uplevel</code> magic.
    </ul>

    @author Jon Salz (jsalz@mit.edu)
    @creation-date 26 June 2000
    @cvs-id $Id$

}

# NSV: doc_adptags($tag) is a list representation of an array containing:
#
#   - balanced_p: do we expect a close tag for $tag?
#   - literal_p: was literal provided to doc_register_adptag?
#   - handler: the name of the handler proc. See document-procs.tcl for some good
#       examples.

ad_proc -public doc_register_adptag {
    -literal:boolean
    -balanced:boolean
    tag handler
} {

    Registers a handler for an ADP tag.

    @param literal should the handler for a balanced tag accept as its second argument the
        contents of the block (literally) rather than code to execute? Useful when the
        contents may contain registered tags which we do not want to be interpreted (e.g.,
        declaring templates with <code>&lt;template&gt;</code>.

} {
    nsv_set doc_adptags $tag [list balanced_p $balanced_p literal_p $literal_p handler $handler]
}

ad_proc -private doc_adp_quote_tcl_string { string } {

    Turns literal text into a string which can be used as a Tcl argument.
    Quotes special Tcl characters and newlines.

} {
    regsub -all {([\{\}\[\]\$\"\\])} $string {\\\1} string
    regsub -all {\n} $string {\\n} string
    return "\"$string\""
}

ad_proc -private doc_adp_append_code { line } {

    Helper procedure to append a line of code to the Tcl translation of an ADP.
    Adds the line of code to the caller's <code>$code</code> variable, indenting
    depending on the size of the caller's <code>$balanced_tag_stack</code>.

} {
    upvar code code
    upvar balanced_tag_stack balanced_tag_stack
    for { set i 0 } { $i < [llength $balanced_tag_stack] } { incr i } {
	append code "    "
    }
    append code "$line\n"
}

ad_proc -private doc_adp_flush_text_buffer {} {

    Helper procedure to generate a <code>doc_adp_puts</code> call for any
    text remaining in the text buffer.

} {
    upvar text_buffer text_buffer
    upvar code code
    upvar balanced_tag_stack balanced_tag_stack
    doc_adp_append_code "doc_adp_puts [doc_adp_quote_tcl_string $text_buffer]"
    set text_buffer ""
}

ad_proc -private doc_eval_in_separate_frame { __code } {

    Evaluates <code>__code</code> in a separate stack frame.

} {
    {*}$__code
}

ad_proc -public doc_adp_abort {} {

    Aborts evaluation of an ADP block.

} {
    error "doc_adp_abort" "" "doc_adp_abort"
}

ad_proc -public doc_adp_execute_file {
    -no_cache:boolean
    file_name

} {

    Compiles and executes an ADP file. Caches the results of compilation
    unless <code>-no_cache</code> is specified.

} {
    if { $no_cache_p } {
	# Not caching at all - just read and compile.

	set file [open $file_name "r"]
	set adp_code [read $file]
	close $file
	set tcl_code [doc_adp_compile $adp_code]
    } else {
	set reparse_p 0
	set mtime [file mtime $file_name]
	set size [file size $file_name]
	
	# See whether the file has been cached, i.e., the __doc_adp_cache_info,$file_name
	# proc has been declared. If it has, the proc will return a two-element list
	# consisting of the mtime/size of the file when it was cached, which we then compare
	# to the current mtime/size of the file. If they don't match, read in the file,
	# compile, and save the results in __doc_adp_cache,$file_name; if they do match,
	# then __doc_adp_cache,$file_name has already been defined.
	#
	# We use procs so that the Tcl code can be byte-code-compiled for extra performance
	# benefit.

	if { [catch { set info [__doc_adp_cache_info,$file_name] }] 
	     || [lindex $info 0] != $mtime
	     || [lindex $info 1] != $size } {
	    set reparse_p 1
	} else {
	    ns_log "Error" "CACHE HIT for $file_name"
	}
	if { $reparse_p } {
	    ns_log "Error" "parsing $file_name"
	    set file [open $file_name "r"]
	    set adp_code [read $file]
	    close $file
	    proc __doc_adp_cache,$file_name {} [doc_adp_compile $adp_code]
	    proc __doc_adp_cache_info,$file_name {} "return { $mtime $size }"
	}
	set tcl_code "__doc_adp_cache,$file_name"
    }
}

ad_proc -public doc_adp_execute {
    compiled_adp
} {

    Evaluates an ADP block returned by <code>doc_adp_compile</code>. May be
    invoked recursively by tag handlers.

} {
    global doc_adp_depth
    if { ![info exists doc_adp_depth] } {
	set doc_adp_depth 0
    }
    incr doc_adp_depth

    upvar #0 doc_adp,$doc_adp_depth adp_var

    set adp_var ""

    set errno [catch { doc_eval_in_separate_frame $compiled_adp } error]
    incr doc_adp_depth -1
    if { $errno == 0 || $::errorCode eq "doc_adp_abort" } {
	return $adp_var
    }

    return -code $errno -errorcode $::errorCode -errorinfo $::errorInfo $error
}

ad_proc -public doc_adp_puts { value } {

    Puts a string in the current ADP context.

} {
    global doc_adp_depth
    upvar #0 doc_adp,$doc_adp_depth adp_var
    append adp_var $value
}

ad_proc -public doc_adp_compile { adp } {

    Compiles a block of ADP code.

    @return a value which can be passed to doc_adp_execute to run the ADP.

} {
    # A buffer of literal text to output.
    set text_buffer ""

    # A stack of tags for which we expect to see end tags.
    set balanced_tag_stack [list]

    # The current offset in the $adp character string.
    set index 0

    # The code buffer we're going to return.
    set code ""

    set adp_length [string length $adp]

    while { 1 } {
	set lt_index [string first "<" $adp $index]
	if { $lt_index < 0 } {
	    append text_buffer [string range $adp $index end]
	    break
	}

	# Append to the text buffer any text before the "<".
	append text_buffer [string range $adp $index $lt_index-1]
	set index $lt_index

	if { [info exists tag] } {
	    unset tag
	}

	# Note that literal_tag may be set at this point, indicating that we shouldn't
	# process any tags right now (we should just be looking for the end tag named
	# </$literal_tag>.

	# Currently index points to a "<".
	incr index
	if { [string index $adp $index] eq "/" } {
	    set end_tag_p 1
	    incr index
	} elseif { ![info exists literal_tag] 
		   && [string index $adp $index] eq "%" 
	} {
	    doc_adp_flush_text_buffer

	    incr index
	    if { [string index $adp $index] eq "=" } {
		incr index
		set puts_p 1
	    } else {
		set puts_p 0
	    }
	    set tcl_code_begin $index

	    while { $index < [string length $adp] 
		    && ([string index $adp $index] ne "%" || [string index $adp $index+1] ne ">") 
		} {
		incr index
	    }
	    if { $index >= [string length $adp] } {
		return -code error "Unbalanced Tcl evaluation block"
	    }

	    set tcl_code [string range $adp $tcl_code_begin $index-1]
	    if { $puts_p } {
		doc_adp_append_code "doc_adp_puts \[subst [doc_adp_quote_tcl_string $tcl_code]\]"
	    } else {
		doc_adp_append_code $tcl_code
	    }

	    # Skip the %> at the end.
	    incr index 2

	    continue
	} elseif { ![info exists literal_tag] && [string index $adp $index] eq "$" } {
	    incr index
	    set tag "var"
	    set end_tag_p 0
	} else {
	    set end_tag_p 0
	}

	if { ![info exists tag] } {
	    # Find the next non-word character.
	    set tag_begin $index
	    while { [string index $adp $index] eq "-" 
		    || [string is wordchar -strict [string index $adp $index]] 
		} {
		incr index
	    }
	    set tag [string range $adp $tag_begin $index-1]
	}

	if { (![info exists literal_tag] || ($end_tag_p && $tag eq $literal_tag)) 
	     && [nsv_exists doc_adptags $tag] 
	 } {
	    doc_adp_flush_text_buffer

	    if { [info exists literal_tag] } {
		unset literal_tag
	    }
	    array set tag_info [nsv_get doc_adptags $tag]

	    # It's a registered tag. Parse the attribute list.

	    set attributes [ns_set create]

	    while { 1 } {
		# Skip whitespace.
		while { [string is space -strict [string index $adp $index]] } {
		    incr index
		}

		# If it's a >, we're done.
		if { [string index $adp $index] eq ">" } {
		    # Done with attribute list.
		    incr index
		    break
		}

		# Not a > - must be an attribute name.
		set attr_name_begin $index
		while { $index < $adp_length 
			&& [string index $adp $index] ne ">" 
			&& [string index $adp $index] ne "=" 
			&& ![string is space -strict [string index $adp $index]] 
		    } {
		    incr index
		}
		if { $attr_name_begin eq $index } {
		    return -code error "Weird attribute format to tag \"$tag\""
		}

		set attr_name [string range $adp $attr_name_begin $index-1]

		if { [string index $adp $index] eq "=" } {
		    incr index
		    while { [string is space -strict [string index $adp $index]] } {
			incr index
		    }
		    if { [string index $adp $index] eq "\"" } {
			# Quoted string.
			set value_begin [incr index]
			while { $index < $adp_length && [string index $adp $index] ne "\"" } {
			    incr index
			}
			set value_end $index
			incr index
		    } else {
			set value_begin $index
			while { $index < $adp_length 
				&& [string index $adp $index] ne ">" 
				&& [string index $adp $index] ne "=" 
				&& ![string is space -strict [string index $adp $index]] 
			    } {
			    incr index
			}
			set value_end $index
		    }
		    ns_set put $attributes $attr_name [string range $adp $value_begin $value_end-1]
		} else {
		    ns_set put $attributes $attr_name $attr_name
		}
	    }

	    if { $end_tag_p } {
		if { [llength $balanced_tag_stack] == 0 } {
		    return -code error "Unexpected end tag </$tag>"
		}
		if { $tag ne [lindex $balanced_tag_stack end] } {
		    return -code error "Expected end tag to be </[lindex $balanced_tag_stack end]>, not </$tag>"
		}
		set balanced_tag_stack [lrange $balanced_tag_stack 0 [llength $balanced_tag_stack]-2]
		doc_adp_append_code "\}"
	    } else {
		doc_adp_append_code "set __doc_attributes \[ns_set create\]"
		for { set i 0 } { $i < [ns_set size $attributes] } { incr i } {
		    doc_adp_append_code "ns_set put \$__doc_attributes [doc_adp_quote_tcl_string [ns_set key $attributes $i]] [doc_adp_quote_tcl_string [ns_set value $attributes $i]]"
		}
		
		if { $tag_info(balanced_p) } {
		    doc_adp_append_code "$tag_info(handler) \$__doc_attributes \{"
		    lappend balanced_tag_stack $tag
		    if { $tag_info(literal_p) } {
			# Remember that we're inside a literal tag.
			set literal_tag $tag
		    }
		} else {
		    doc_adp_append_code "$tag_info(handler) \$__doc_attributes"
		}
	    }
	} else {
	    append text_buffer [string range $adp $lt_index $index-1]
	}
    }

    if { [llength $balanced_tag_stack] > 0 } {
	return -code error "Expected end tag </[lindex $balanced_tag_stack end]> but got end of file"
    }

    doc_adp_flush_text_buffer

    return $code
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
