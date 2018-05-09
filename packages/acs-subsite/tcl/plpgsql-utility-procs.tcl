ad_library {

    Procs to help generate pl/pgsql dynamically

    @author swoodcock@scholastic.co.uk
    @creation-date Sun Jul 22 13:51:26 BST 2001
    @cvs-id $Id$
    
}

namespace eval plpgsql_utility {

    ad_proc -public generate_attribute_parameter_call_from_attributes { 
	{ -prepend "" }
	function_name
	attr_list 
    } {
	Wrapper for generate_attribute_parameter_call that formats
	default attribute list to the right format.

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000

    } {
	set the_list [list]
	foreach row $attr_list {
	    lappend the_list [list [lindex $row 1] [lindex $row 3]]
	}
	return [generate_attribute_parameter_call -prepend $prepend $function_name $the_list]
    }

    ad_proc -private get_function_args {function_name} {
        uncached version returns list of lists args
        called from generate_attribute_parameter_call
    } { 
        return [db_list_of_lists get_function_args {}]
    }

    ad_proc -public generate_attribute_parameter_call {
	{ -prepend "" }
	function_name
	pairs
    } {
	Generates the arg list for a call to a pl/pgsql function

	@author Steve Woodcock (swoodcock@scholastic.co.uk)
	@creation-date 07/2001

    } {
	# Get the list of real args to the function
	set real_args [util_memoize [list plpgsql_utility::get_function_args $function_name]]

	foreach row $pairs {
	    set attr [string trim [lindex $row 0]]
	    set user_supplied([string toupper $attr]) $attr
	}

	# For each real arg, append default or supplied arg value
	set pieces [list]
	foreach row $real_args {
	    lassign $row arg_name arg_default

	    if { [info exists user_supplied($arg_name)] } {
		lappend pieces "${prepend}$user_supplied($arg_name)"
	    } else {
		if { $arg_default eq "" || $arg_default eq "null"} {
		    lappend pieces "NULL"
		} else {
		    lappend pieces "'[db_quote $arg_default]'"
		}
	    }
	}

	return [join $pieces ","]
    }

    ad_proc -public table_column_type {
	table
	column
    } {
	Returns the datatype for column in table

	@author Steve Woodcock (swoodcock@scholastic.co.uk)
	@creation-date 07/2001

    } {
	return [db_string fetch_type {}]
    }

    ad_proc -public generate_attribute_parameters { 
	{ -indent "4" }
	attr_list 
    } {
	Generates the arg list to a pl/sql function or procedure

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000

    } {
	set pieces [list]
	set arg_num 0
	foreach triple $attr_list {
	    incr arg_num
	    set attr [string toupper [string trim [lindex $triple 1]]]
	    lappend pieces [list "p_${attr}" "alias for \$${arg_num}"]
	}
	return [plsql_utility::format_pieces -indent $indent -line_term ";" $pieces]

    }


    ad_proc -public generate_function_signature { 
	attr_list 
    } {
	Generates the signature for a pl/sql function or procedure

	@author Steve Woodcock (swoodcock@scholastic.co.uk)
	@creation-date 07/2001

    } {
	set pieces [list]
	foreach triple $attr_list {
	    set table [string toupper [string trim [lindex $triple 0]]]
	    set attr [string toupper [string trim [lindex $triple 1]]]
	    set datatype [table_column_type $table $attr]
	    lappend pieces $datatype
	}
	return [join $pieces ","]

    }

    ad_proc -public dollar { 
    } {
	Return a literal dollar for use in .xql files.
    } {
	return "$"
    }


    ad_proc -public define_function_args { 
	attr_list 
    } {
	Returns the attribute list as a string suitable for a call to define_function_args.

	@author Steve Woodcock (swoodcock@scholastic.co.uk)
	@creation-date 07/2001

    } {
	set pieces [list]
	foreach triple $attr_list {
	    set attr  [string trim [lindex $triple 1]]
	    set dft   [string trim [lindex $triple 2]]
	    if { $dft eq "" || $dft eq "NULL" } {
		set default ""
	    } else {
		if { [string index $dft 0] eq "'" } {
		    set dft [string range $dft 1 [string length $dft]-2]
		}
		set default ";${dft}"
	    }
	    lappend pieces "${attr}${default}"
	}
	return [join $pieces ","]

    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
