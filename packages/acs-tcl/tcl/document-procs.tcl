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



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
