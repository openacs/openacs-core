
ad_library {
    A library of additional OpenACS utilities

    @author ben@openforce
    @creation-date 2002-03-05
    @cvs-id $Id$
}

namespace eval oacs_util {

    ad_proc -public process_objects_csv {
        {-object_type:required}
        {-file:required}
        {-header_line 1}
        {-override_headers {}}
        {-constants ""}
    } {
        This processes a CVS of objects
    } {
        # FIXME: We should catch the error here
        set csv_stream [open $file r]

        # Check if there are headers
        if {![empty_string_p $override_headers]} {
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
                if {![empty_string_p $constants]} {
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
         
        # Return the list of objects
        return $list_of_object_ids
    }

    ad_proc -public csv_foreach {
        {-file:required}
        {-header_line 1}
        {-override_headers {}}
        {-array_name:required}
        code_block
    } {
        # FIXME: We should catch the error here
        set csv_stream [open $file r]

        # Check if there are headers
        if {![empty_string_p $override_headers]} {
            set headers $override_headers
        } else {
            if {!$header_line} {
                return -code error "There is no header!"
            }

            # get the headers
            ns_getcsv $csv_stream headers
        }

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
            
            # Error?
            if {$errno > 0} {
                return -code $error
            }
        }
    }

    ad_proc -public vars_to_ns_set {
	{-ns_set:required}
	{-var_list:required}
    } {
	foreach var $var_list {
	    upvar $var one_var
	    ns_set put $ns_set $var $one_var
	}
    }

}
