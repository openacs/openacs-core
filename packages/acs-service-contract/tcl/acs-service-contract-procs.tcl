ad_library {
    Support library for acs service contracts.  
    
    @author Neophytos Demetriou
    @creation-date 2001-09-01
    @cvs-id $Id$
}

namespace eval acs_sc {}

#####
#
# Invoke
#
#####

ad_proc -public acs_sc::invoke {
    {-contract:required}
    {-operation:required}
    {-impl:required}
    {-call_args {}}
} {
    A wrapper for the acs_sc_call procedure, with explicitly named
    parameters so it's easier to figure out how to use it.
    
    @param contract_name The name of the contract you wish to use.
    @param operation_name The name of the operation in the contract you wish to call.
    @param impl_name The name of the implementation you wish to use.
    @param args The arguments you want to pass to the proc.
    
    @author Lars Pind (lars@collaboraid.biz)
    @see acs_sc_call
} {
    return [acs_sc_call $contract $operation $call_args $impl]
}


#####
#
# All the rest that used to be there
#
#####

ad_proc -public acs_sc_binding_exists_p {
    contract
    impl
} {
    Returns a boolean depending on whether or not the binding between 
    the contract and implementation exists.

    @param contract the contract name 
    @param impl the implementation name 

    @return 0 or 1
    
    @author Neophytos Demetriou
} {

    return [db_string binding_exists_p {select acs_sc_binding__exists_p(:contract,:impl)}]

}

ad_proc -private acs_sc_generate_name {
    contract
    impl
    operation
} {
    generate the internal proc name.

    @author Neophytos Demetriou
} {
    return AcsSc.${contract}.${operation}.${impl}
}


ad_proc -private acs_sc_get_alias {
    contract
    operation
    impl
} {
    Returns the implementation alias (the 
    proc defined to handle a given operation 
    for a given implementation).                                      
    
    @author Neophytos Demetriou
} {
     # LARS
     set exists_p [acs_sc_binding_exists_p $contract $impl]
     
     #set exists_p [util_memoize "acs_sc_binding_exists_p $contract $impl"]

    if ![set exists_p] {return ""}

    db_0or1row get_alias {
	select impl_alias, impl_pl
	from acs_sc_impl_aliases
	where impl_contract_name = :contract
	and impl_operation_name = :operation
	and impl_name = :impl
    }

    return [list $impl_alias $impl_pl]

}




ad_proc -private acs_sc_proc {
    contract
    operation
    impl
} {
    Builds the proc used by acs_sc_call, generally only called 
    in acs-service-contract-init.tcl at startup.

    @return 0 on failure, 1 on success.
    @author Neophytos Demetriou
} {

    set arguments [list]
    set docblock {}

    set proc_name [acs_sc_generate_name $contract $impl $operation]

    acs_sc_log SCDebug "ACS_SC_PROC: proc_name = $proc_name"
    foreach {impl_alias impl_pl} [acs_sc_get_alias $contract $operation $impl] break 

    if ![info exists impl_alias] {
	error "ACS-SC: Cannot find alias for $proc_name"
    }

    if {![db_0or1row get_operation_definition {
	select 
	    operation_desc,
	    operation_iscachable_p,
	    operation_nargs,
	    operation_inputtype_id,
	    operation_outputtype_id
	from acs_sc_operations
	where contract_name = :contract
	and operation_name = :operation
    }]} { 
        ns_log warning "ACS-SC: operation definition not found for contract $contract operation $operation"
        return 0
    }

    append docblock "\n<b>acs-service-contract operation.  Call via acs_sc_call.</b>\n\n$operation_desc\n\n"

    db_foreach operation_inputtype_element {
	select 
	    element_name, 
	    acs_sc_msg_type__get_name(element_msg_type_id) as element_msg_type_name,
	    element_msg_type_isset_p,
	    element_pos
	from acs_sc_msg_type_elements
	where msg_type_id = :operation_inputtype_id
	order by element_pos asc
    } {
	lappend arguments "$element_name"
	append docblock "\n@param $element_name $element_msg_type_name"
	if { $element_msg_type_isset_p } {
	    append docblock " \[\]"
	}
    }

    db_foreach operation_outputtype_element {
	select 
	    element_name, 
	    acs_sc_msg_type__get_name(element_msg_type_id) as element_msg_type_name,
	    element_msg_type_isset_p,
	    element_pos
	from acs_sc_msg_type_elements
	where msg_type_id = :operation_outputtype_id
	order by element_pos asc
    } {
	append docblock "\n@return <b>$element_name</b> - $element_msg_type_name"
	if { $element_msg_type_isset_p } {
	    append docblock " \[\]"
	}
    }

    append docblock "\n@see $impl_alias\n@see acs_sc_call"

    set full_statement [acs_sc_get_statement $impl_alias $impl_pl $arguments]

    if { $operation_iscachable_p } {
	set full_statement "util_memoize \"$full_statement\""
    }

#FIX ME: CALL BY NAME USING UPVAR
    set body "return \[$full_statement\]"

    set arguments [join $arguments]
    acs_sc_log SCDebug "ACS-SC: ad_proc $proc_name $arguments\n$docblock\n$body\n"
    ad_proc -private $proc_name $arguments $docblock $body
    
    return 1
}



ad_proc -private acs_sc_get_statement {
    impl_alias
    impl_pl
    arguments
} {
    Builds the statement to call from the provided metadata.

    @param impl_alias tcl or plpgsql proc to call
    @param impl_pl programmimg language of the proc to call (TCL or PLPGSQL)
    @param arguments list of argument names

    @author Neophytos Demetriou
} {


    switch $impl_pl {
	TCL {
	    set full_statement [list $impl_alias]
	    for {set __i 0} {$__i < [llength $arguments]} {incr __i} {
		lappend full_statement "\$[lindex $arguments $__i]"
	    }
	    set full_statement [join $full_statement]
	}
	PLPGSQL {
	    set args_list [list]
	    for {set __i 0} {$__i < [llength $arguments]} {incr __i} {
		lappend args_list "\$[lindex $arguments $__i]"
	    }
	    set args_final [join $args_list ,]
	    set full_statement "db_exec_plsql full_statement \"select ${impl_alias}(${args_final})\""
	}
	default {
	    error "ACS-SC: Unknown impl_pl: $impl_pl"
	}
    }

    return $full_statement
}




ad_proc -public acs_sc_call {
    contract
    operation
    {arguments ""}
    {impl ""}
} {
    @param contract the contract name 
    @param operation the method to invoke
    @param arguments list of arguments to pass to the method
    @param impl the implementation name.

    @author Neophytos Demetriou
} {
    set proc_name [acs_sc_generate_name $contract $impl $operation]

    if { [llength [info procs $proc_name]] == 1 } {
	return [apply $proc_name $arguments]
    } else {
	# QUESTION: 
	# SHOULD WE PRODUCE AN ERROR HERE? 
	# MAYBE NOT, THE SEMANTICS MIGHT REQUIRE TO CALL 
	# THE FUNCTION ONLY IF THE IMPLEMENTATION IS SUPPORTED.
	ns_log warning "ACS-SC: Function Not Found: $proc_name [info procs $proc_name]"
	return
    }
}


##
## Logging
##

# Private logging proc
proc acs_sc_log {level msg} {
    # If you want to debug the SC, uncomment the Debug log below
    if {![string equal "SCDebug" $level]} {
        ns_log $level "$msg"
    } else { 
        # ns_log Debug "$msg"
    }
}