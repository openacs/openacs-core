ad_library {

    Procs to help generate pl/pgsql dynamically

    @author swoodcock@scholastic.co.uk
    @creation-date Sun Jul 22 13:51:26 BST 2001
    @cvs-id $Id$
    
}

namespace eval plpgsql_utility {

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
	set real_args [db_list_of_lists get_function_args "
	    select arg_name, arg_default
	      from acs_function_args
	     where function = upper(:function_name)
	     order by arg_seq
	"]

	foreach row $pairs {
	    set attr [string trim [lindex $row 0]]
	    set user_supplied([string toupper $attr]) $attr
	}

	# For each real arg, append default or supplied arg value
	set pieces [list]
	foreach row $real_args {
	    set arg_name [lindex $row 0]
	    set arg_default [lindex $row 1]
	    if { [info exists user_supplied($arg_name)] } {
		lappend pieces ":$user_supplied($arg_name)"
	    } else {
		if { $arg_default == "" } {
		    lappend pieces "NULL"
		} else {
		    lappend pieces "'[db_quote $arg_default]'"
		}
	    }
	}

	return [join $pieces ","]
    }

}
