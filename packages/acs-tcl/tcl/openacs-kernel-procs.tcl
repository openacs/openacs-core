
ad_library {
    A library of additional OpenACS utilities

    @author ben@openforce
    @creation-date 2002-03-05
    @cvs-id $Id$
}

namespace eval oacs_util {}

ad_proc -public oacs_util::process_objects_csv {
    {-object_type:required}
    {-file:required}
    {-header_line 1}
    {-override_headers {}}
    {-constants ""}
} {
    This processes a CSV of objects, taking the csv and calling package_instantiate_object 
    for each one.

    @return a list of the created object_ids
} {
    # FIXME: We should catch the error here
    set csv_stream [open $file r]

    # Check if there are headers
    if {$override_headers ne ""} {
        set headers $override_headers
    } else {
        if {!$header_line} {
            return -code error "There is no header!"
        }

        # get the headers
        ns_getcsv $csv_stream headers
    }

    set list_of_object_ids [list]

    # Process the file
    db_transaction {
        while {1} {
            # Get a line
            set n_fields [ns_getcsv $csv_stream one_line]

            # end of things
            if {$n_fields == -1} {
                break
            }

            # Process the row
            set extra_vars [ns_set create]
            for {set i 0} {$i < $n_fields} {incr i} {
                set varname [string tolower [lindex $headers $i]]
                set varvalue [lindex $one_line $i]

                # Set the value
                ns_log debug "oacs_util::process_objects_csv: setting $varname to $varvalue"
                ns_set put $extra_vars $varname $varvalue
            }

            # Add in the constants
            if {$constants ne ""} {
                # This modifies extra_vars, without touching constants
                ns_set merge $constants $extra_vars
            }

            # Create object and go for it
            set object_id [package_instantiate_object -extra_vars $extra_vars $object_type]
            lappend list_of_object_ids $object_id

            # Clean Up
            ns_set free $extra_vars
        }
    }

    close $csv_stream

    # Return the list of objects
    return $list_of_object_ids
}

ad_proc -public oacs_util::csv_foreach {
    {-file:required}
    {-header_line 1}
    {-override_headers {}}
    {-array_name:required}
    code_block
} {
    reads a csv and executes code block for each row in the csv.

    @param file the csv file to read.
    @param header_line the line with the list of var names
    @param override_headers the list of variables in the csv
    @param array_name the name of the array to set with the values from the csv as each line is read.
} {
    # FIXME: We should catch the error here
    set csv_stream [open $file r]

    # Check if there are headers
    if {$override_headers ne ""} {
        set headers $override_headers
    } else {
        if {!$header_line} {
            return -code error "There is no header!"
        }

        # get the headers
        ns_getcsv $csv_stream headers
    }

    # provide access to errorCode

    # Upvar Magic!
    upvar 1 $array_name row_array

    while {1} {
        # Get a line
        set n_fields [ns_getcsv $csv_stream one_line]

        # end of things
        if {$n_fields == -1} {
            break
        }

        # Process the row
        for {set i 0} {$i < $n_fields} {incr i} {
            set varname [string tolower [lindex $headers $i]]
            set varvalue [lindex $one_line $i]
            set row_array($varname) $varvalue
        }

        # Now we are ready to process the code block
        set errno [catch { uplevel 1 $code_block } error]

	if {$errno > 0} {
	  close $csv_stream
	}

        # handle error, return, break, continue
	# (source: http://wiki.tcl.tk/unless last case)
	switch -exact -- $errno {
	    0   {}
	    1   {return -code error -errorinfo $::errorInfo \
		     -errorcode $::errorCode $error}
	    2   {return $error}
	    3   {break}
	    4   {}
	    default     {return -code $errno $error}
	}
    }
}

ad_proc -public oacs_util::vars_to_ns_set {
    {-ns_set:required}
    {-var_list:required}
} {
    Does an ns_set put on each variable named in var_list

    @param var_list list of variable names in the calling scope
    @param ns_set an ns_set id that already exists.
} {
    foreach var $var_list {
        upvar $var one_var
        ns_set put $ns_set $var $one_var
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
