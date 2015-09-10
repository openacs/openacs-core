ad_library {

    An API for managing documents.

    @creation-date 22 May 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id $Id$

}

ad_proc -private doc_parse_property_string { properties } { 

    Parses a properties declaration of the form that programmers specify.
    
    @param properties The property string as the programmer specified it.
    @error if there's any problems with the string.
    @return an internal array-as-a-list representation of the properties
    declaration.

} {
    set property_array_list [list]
    
    set lines [split $properties \n]
    foreach line_raw $lines {
	set line [string trim $line_raw]
	if { $line eq "" } {
	    continue
	}
	
	if { ![regexp {^([^:]+)(?::([^(]+)(?:\(([^)]+)\))?)?$} $line \
		   match name_raw type_raw columns] } {
	    return -code error \
		"Property doesn't have the right format, i.e. our regexp failed"
	}

	set name [string trim $name_raw]

	if { ![string is wordchar -strict $name] } {
	    return -code error "Property name $name contains characters that\
                     are not Unicode word characters, but we don't allow that."
	}

	if { [info exists type_raw] && $type_raw ne "" } { 
	    set type [string trim $type_raw]
	} else {
	    set type onevalue
	}

	# The following statement will set "type_repr" to our internal
	# representation of the type of this property.
	switch -- $type {
	    onevalue - onelist - multilist { 
		set type_repr $type
	    }
	    onerow -
	    multirow {
		if { ![info exists columns] } {
		    return -code error "Columns not defined for $type type\
			                property $name"
		}
		set column_split [split $columns ","]
		set column_list [list]
		foreach column_raw $column_split {
		    set column [string trim $column_raw]
		    if { $column eq "" } {
			return -code error "You have an empty column name in\
				the definition of the $property property in the\
				type $type"
		    }
		    lappend column_list $column
		}
		set type_repr [list $type $column_list]
	    }
	    default {
		return -code error \
		    "Unknown property type $type for property $name"
	    }
	}

	lappend property_array_list $name $type_repr
    }
    
    return $property_array_list
}



ad_proc -deprecated doc_init {} { Initializes the global environment for document handling. } {
    global doc_properties
    if { [info exists doc_properties] } {
	unset doc_properties
    }
    array set doc_properties {}
}

ad_proc -deprecated doc_set_property { name value } { Sets a document property. } {
    global doc_properties
    set doc_properties($name) $value
}

ad_proc -deprecated doc_property_exists_p { name } { Return 1 if a property exists, or 0 if not. } {
    global doc_properties
    return [info exists doc_properties($name)]
}

ad_proc -deprecated doc_get_property { name } { Returns a property (or an empty string if no such property exists). } {
    global doc_properties
    if { [info exists doc_properties($name)] } {
	return $doc_properties($name)
    }
    return ""
}

ad_proc -deprecated doc_body_append { str } { Appends $str to the body property. } {
    global doc_properties
    append doc_properties(body) $str
}

ad_proc -deprecated doc_set_mime_type { mime_type } { Sets the mime-type property. } {
    doc_set_property mime_type $mime_type
}

ad_proc -deprecated doc_exists_p {} { Returns 1 if there is a document in the global environment. } {
    global doc_properties
    if { [array size doc_properties] > 0 } {
	return 1
    }
    return 0
}

ad_proc -deprecated doc_body_flush {} { Flushes the body (if possible). } {
    # Currently a no-op.
}

ad_proc -deprecated doc_find_template { filename } { Finds a master.adp file which can be used as a master template, looking in the directory containing $filename and working our way down the directory tree. } {
    set path_root $::acs::rootdir

    set start [clock clicks -milliseconds]

    set dir [file dirname $filename]
    while { [string length $dir] > 1 && [string first $path_root $dir] == 0 } {
	# Only look in directories under the path root.
	if { [file isfile "$dir/master.adp"] } {
	    return "$dir/master.adp"
	}
	set dir [file dirname $dir]
    }

    if { [file exists "$path_root/templates/master.adp"] } {
	return "$path_root/templates/master.adp"
    }

    # Uhoh. Nada!
    return ""
}

ad_proc -deprecated doc_serve_template { __template_path } { Serves the document in the environment using a particular template. } {
    upvar #0 doc_properties __doc_properties
    foreach __name [array names __doc_properties] {
	set $__name $__doc_properties($__name)
    }

    set adp [ns_adp_parse -file $__template_path]
    set content_type [ns_set iget [ad_conn outputheaders] "content-type"]
    if { $content_type eq "" } {
	set content_type "text/html"
    }
    doc_return 200 $content_type $adp
}

ad_proc -deprecated doc_serve_document {} { Serves the document currently in the environment. } {
    if { ![doc_exists_p] } {
	error "No document has been built."
    }

    set mime_type [doc_get_property mime_type]
    if { $mime_type eq "" } {
	if { [doc_property_exists_p title] } {
	    set mime_type "text/html;content-pane"
	} else {
	    set mime_type "text/html"
	}
    }

    switch $mime_type {
	text/html;content-pane - text/x-html-content-pane {
	    # It's a content pane. Find the appropriate template.
	    set template_path [doc_find_template [ad_conn file]]
	    if { $template_path eq "" } {
		ns_returnerror 500 "Unable to find master template"
	        ns_log error \
		    "Unable to find master template for file '[ad_conn file]'"
	    } else {
	        doc_serve_template $template_path
	    }
	}
	default {
	    # Return a complete document.
	    ns_return 200 $mime_type [doc_get_property body]
	}
    }
}

ad_proc -deprecated doc_tag_ad_document { contents params } {} {
    for { set i 0 } { $i < [ns_set size $params] } { incr i } {
	doc_set_property [ns_set key $params $i] [ns_set value $params $i]
    }
    doc_set_property _adp 1
    return [template::adp_parse_string $contents]
}

ad_proc -deprecated doc_tag_ad_property { contents params } {} {
    set name [ns_set iget $params name]
    if { $name eq "" } {
	return "<em>No <tt>name</tt> property in <tt>AD-PROPERTY</tt> tag</em>"
    }
    doc_set_property $name $contents
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
