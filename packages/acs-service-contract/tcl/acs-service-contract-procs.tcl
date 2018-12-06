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
    {-contract ""}
    {-operation:required}
    {-impl ""}
    {-impl_id ""}
    {-call_args {}}
    {-error:boolean}
} {
    A replacement of the former acs_sc_call procedure.
    One must supply either contract and impl, or just impl_id.
    If you supply impl_id and contract, we throw an error if the impl_id's contract doesn't match
    the contract you passed in. If you supply both impl_id and impl, we throw an error.

    Additional documentation and commentary at http://openacs.org/forums/message-view?message_id=108614.
    
    @param contract The name of the contract you wish to use.
    @param operation The name of the operation in the contract you wish to call.
    @param impl The name of the implementation you wish to use.
    @param impl_id The ID of the implementation you wish to use.
    @param call_args The arguments you want to pass to the proc.
    @param error If specified, will throw an error if the operation isn't implemented.

    
    @author Lars Pind (lars@collaboraid.biz)
    @see acs_sc_call
} {
    if { $impl_id ne "" } {
        if { $impl ne "" } {
            error "Cannot supply both impl and impl_id"
        }
        acs_sc::impl::get -impl_id $impl_id -array impl_info
        set impl $impl_info(impl_name)
        if { $contract ne "" && $contract ne $impl_info(impl_contract_name) } {
            error "The contract of implementation with id $impl_id does not match contract passed in. Expected contract to be '$contract', but contract of impl_id was '$impl_info(impl_contract_name)'"
        }
        set contract $impl_info(impl_contract_name)
    }
    if { $impl eq "" || $contract eq "" } {
        error "You must supply either impl_id, or contract and impl to acs_sc::invoke"
    }

    set proc_name [acs_sc_generate_name $contract $impl $operation]

    if { [info commands $proc_name] ne "" } {
	return [ad_apply $proc_name $call_args]
    } 

    if { $error_p } {
	error "Operation $operation is not implemented in '$impl' implementation of contract '$contract'"
    } else {
	ns_log warning "ACS-SC: Function Not Found: $proc_name [info commands $proc_name]"
    }
    return
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

    return [db_string binding_exists_p {}]

}

ad_proc -private acs_sc_generate_name {
    contract
    impl
    operation
} {
    generate the internal proc name.

    @author Neophytos Demetriou
} {
    return "AcsSc.[util_text_to_url -no_resolve -replacement "_" -text $contract].[util_text_to_url -no_resolve -replacement "_" -text $operation].[util_text_to_url -no_resolve -replacement "_" -text $impl]"
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

    #set exists_p [util_memoize [list acs_sc_binding_exists_p $contract $impl]]

    if {![set exists_p]} {return ""}
    
    db_0or1row get_alias {
        select impl_alias, impl_pl
          from acs_sc_impl_aliases
         where impl_contract_name  = :contract
           and impl_operation_name = :operation
           and impl_name           = :impl
    }

    return [list $impl_alias $impl_pl]

}

ad_proc -private acs_sc_proc {
    contract
    operation
    impl
    {impl_alias {}}
    {impl_pl {}}
} {
    Builds the proc used by acs_sc::invoke, generally only called 
    in acs-service-contract-init.tcl at startup.

    @return 0 on failure, 1 on success.
    @author Neophytos Demetriou
} {
    set arguments [list]
    set docblock {}

    set proc_name [acs_sc_generate_name $contract $impl $operation]

    acs_sc_log SCDebug "ACS_SC_PROC: proc_name = $proc_name"
    
    if { $impl_alias eq "" } {
        lassign [acs_sc_get_alias $contract $operation $impl] impl_alias impl_pl 
    }

    if { $impl_alias eq "" } {
	error "ACS-SC: Cannot find alias for $proc_name"
    }

    if {![db_0or1row get_operation_definition {
	select 
	    operation_desc,
            coalesce(operation_iscachable_p,'f') as operation_iscachable_p,
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

    append docblock "\n<b>acs-service-contract operation.  Call via acs_sc::invoke.</b>\n\n$operation_desc\n\n"

    set msg_type_id $operation_inputtype_id
    db_foreach operation_msgtype_element {} {
	lappend arguments "$element_name"
	append docblock "\n@param $element_name $element_msg_type_name"
	if { $element_msg_type_isset_p } {
	    append docblock " \[\]"
	}
    }

    set msg_type_id $operation_outputtype_id    
    db_foreach operation_msgtype_element {} {
	append docblock "\n@return <b>$element_name</b> - $element_msg_type_name"
	if { $element_msg_type_isset_p } {
	    append docblock " \[\]"
	}
    }

    append docblock "\n@see $impl_alias\n@see acs_sc::invoke"

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

ad_proc acs_sc_update_alias_wrappers {} {

    Loop over actual bindings, finding every impl alias for each contract operation
    and call "acs_sc_proc" for all of these.

    @see acs_sc_proc
    
} {
    db_foreach impl_operation {
        select ia.impl_contract_name, 
               ia.impl_operation_name,
               ia.impl_name,
               ia.impl_alias,
               ia.impl_pl
        from   acs_sc_bindings b, acs_sc_impl_aliases ia
        where  ia.impl_id = b.impl_id
    } {
        #
        # Create the AcsSc.Contract.Operation.Impl wrapper proc for this implementation
        #
        if {[catch {
            #
            # Check, if the wrapper exists already
            #
            set proc_name [acs_sc_generate_name $impl_contract_name $impl_name $impl_operation_name]
            if {[info commands ::$proc_name] eq ""} {
                #
                # Create it new.
                #
                acs_sc_proc $impl_contract_name $impl_operation_name $impl_name $impl_alias $impl_pl
            }
        } errorMsg]} {
            ns_log error "Service contract initialization failed, call was:\n\
	           acs_sc_proc $impl_contract_name $impl_operation_name $impl_name $impl_alias $impl_pl" 
        }
    }
}

ad_proc -private acs_sc_get_statement {
    impl_alias
    impl_pl
    arguments
} {
    Builds the statement to call from the provided metadata.

    @param impl_alias Tcl or plpgsql proc to call
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

ad_proc -private -deprecated acs_sc_call {
    {-error:boolean}
    contract
    operation
    {arguments ""}
    {impl ""}
} {
    Additional documentation and commentary at http://openacs.org/forums/message-view?message_id=108614.

    @param contract the contract name 
    @param operation the method to invoke
    @param arguments list of arguments to pass to the method
    @param impl the implementation name.
    @param error If specified, will throw an error if the operation isn't implemented.

    @author Neophytos Demetriou

    @see acs_sc::invoke
} {
    acs_sc::invoke -contract $contract -operation $operation -impl $impl -call_args $arguments -error=$error_p
} 



##
## Logging
##

# Private logging proc
proc acs_sc_log {level msg} {
    # If you want to debug the SC, uncomment the Debug log below
    if { "SCDebug" ne $level } {
        ns_log $level "$msg"
    } else { 
        # ns_log Debug "$msg"
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
