ad_library {

    @author Neophytos Demetriou

}

ad_proc acs_sc_binding_exists_p {
    contract
    impl
} {
    @author Neophytos Demetriou
} {

    return [db_exec_plsql binding_exists_p {select acs_sc_binding__exists_p(:contract,:impl)}]

}

ad_proc acs_sc_generate_name {
    contract
    impl
    operation

} {
    @author Neophytos Demetriou
} {
    return AcsSc.${contract}.${operation}.${impl}
}


ad_proc acs_sc_get_alias {
    contract
    operation
    impl
} {
    @author Neophytos Demetriou
} {

    set exists_p [util_memoize "acs_sc_binding_exists_p $contract $impl"]

    if ![set exists_p] {return ""}

    db_0or1row get_alias {
	select impl_alias, impl_pl
	from acs_sc_impl_alias
	where impl_contract_name = :contract
	and impl_operation_name = :operation
	and impl_name = :impl
    }

    return [list $impl_alias $impl_pl]

}




ad_proc acs_sc_proc {
    contract
    operation
    impl
} {
    @author Neophytos Demetriou
} {

    set arguments [list]
    set docblock [list]


    set proc_name [acs_sc_generate_name $contract $impl $operation]

    ns_log Notice "ACS_SC_PROC: proc_name = $proc_name"
    foreach {impl_alias impl_pl} [acs_sc_get_alias $contract $operation $impl] break 

    if ![info exists impl_alias] {
	error "Cannot find alias for $proc_name"
    }

    db_0or1row get_operation_definition {
	select 
	    operation_desc,
	    operation_iscachable_p,
	    operation_nargs,
	    operation_inputtype_id,
	    operation_outputtype_id
	from acs_sc_operation
	where contract_name = :contract
	and operation_name = :operation
    }

    lappend docblock "$operation_desc"

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
	lappend docblock "@param $element_name $element_msg_type_name"
	if { $element_msg_type_isset_p } {
	    lappend docblock "\[\]"
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
	lappend docblock "@return <b>$element_name</b> - $element_msg_type_name"
	if { $element_msg_type_isset_p } {
	    lappend docblock "\[\]"
	}
    }


    set full_statement [acs_sc_get_statement $impl_alias $impl_pl $arguments]

    if { $operation_iscachable_p } {
	set full_statement "util_memoize \"$full_statement\""
    }

#FIX ME: CALL BY NAME USING UPVAR
    set body "return \[$full_statement\]"

    set docblock [join $docblock "\n\r"]
    set arguments [join $arguments]
    ns_log Notice "sc_proc: $proc_name, $arguments"
    ad_proc $proc_name $arguments $docblock $body

}



ad_proc acs_sc_get_statement {
    impl_alias
    impl_pl
    arguments
} {
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
	    error "Unknown impl_pl: $impl_pl"
	}
    }

    return $full_statement
}




ad_proc acs_sc_call {
    contract
    operation
    {arguments ""}
    {impl ""}
} {
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
	ns_log warning "ACS-SC: Function Not Found: $proc_name"
	return
    }
}













