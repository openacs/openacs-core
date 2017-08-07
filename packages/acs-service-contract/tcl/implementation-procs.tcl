ad_library {
    Support library for acs service contracts. Implements the acs_sc::impl namespace.
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-01-14
    @cvs-id $Id$
}

namespace eval acs_sc::impl {}
namespace eval acs_sc::impl::alias {}
namespace eval acs_sc::impl::binding {}


#####
#
# Implementations
#
#####

ad_proc -public acs_sc::impl::new {
    {-contract_name:required}
    {-name:required}
    {-pretty_name ""}
    {-owner:required}
} {
    Add new service contract implementation.

    @param name         The internal name of the implementation. Referred to when invoking the implementation.
                        Alphanumeric characters and underscores only.

    @param pretty_name  The name of the implementation when display to users. Defaults to 'name'.
    
    @return the ID of the new implementation
} {
    if { $pretty_name eq "" } {
        set pretty_name $name
    }
    return [db_exec_plsql impl_new {}]
}

ad_proc -public acs_sc::impl::delete {
    {-contract_name:required}
    {-impl_name:required}
} {
    Delete a service contract implementation 
} {

    if { $contract_name eq "" || $impl_name eq "" } {
        error "You must supply contract_name and impl_name"
    }

    db_exec_plsql delete_impl {} 
}

ad_proc -public acs_sc::impl::new_from_spec {
    {-spec:required}
} {
    Add new service contract implementation from an array-list style implementation, 
    and binds it to the specified contract.
    
    <p>

    The specification takes the following form:

    <blockquote><pre>
    set spec {
        contract_name "Action_SideEffect"
        owner "bug-tracker"
        name "CaptureResolutionCode"
        pretty_name "Capture Resolution Code"
        aliases {
            GetObjectType bug_tracker::bug::object_type
            GetPrettyName bug_tracker::bug::capture_resolution_code::pretty_name
            DoSideEffect  bug_tracker::bug::capture_resolution_code::do_side_effect
        }
    }
    acs_sc::impl::new_from_spec -spec $spec
    </pre></blockquote>

    And here's the explanation:

    <p>

    The spec is an array-list with the following entries: 
    
    <ul>
      <li>contract_name: The name of the service contract you're implementing.
      <li>owner: Owner of the implementation, use the package-key.
      <li>name: Name of your implementation.
      <li>name: Pretty name of your implementation. You'd typically use this when displaying the service contract implementation through a UI.
      <li>aliases: Specification of the Tcl procedures for each of the service contract's operations.
    </ul>

    The aliases section is itself an array-list. The keys are the operation names 
    from the service contract. The values are the names of Tcl procedures in your package, 
    which implement these operations.

    @param spec The specification for the new service contract implementation.
    
    @return the impl_id of the newly registered implementation
} {
    # Spec contains: contract_name, name, pretty_name, owner, aliases
    array set impl $spec
    
    if { ![info exists impl(pretty_name)] } {
        set impl(pretty_name) ""
    }

    db_transaction {
        set impl_id [new \
                -contract_name $impl(contract_name) \
                -name $impl(name) \
                -pretty_name $impl(pretty_name) \
                -owner $impl(owner)]

        acs_sc::impl::alias::parse_aliases_spec \
                -contract_name $impl(contract_name) \
                -impl_name $impl(name) \
                -spec $impl(aliases)

        acs_sc::impl::binding::new \
                -contract_name $impl(contract_name) \
                -impl_name $impl(name)
    }

    # Initialize the procs so we can start calling them right away
    acs_sc::impl::binding::init_procs -impl_id $impl_id

    return $impl_id
}

ad_proc -public acs_sc::impl::get_id {
    {-owner:required}
    {-name:required}
    -contract
} {
    Retrieves the ID for a service contract.  If the contract is specified
    then the ID is retrieved for the specified contract, otherwise all
    service contract IDs will be retrieved that match the specified owner
    and implementation name.

    @param owner Owner of the service contract.
    @param name Implementation name.
    @param contract Implementation contract name.
    @return Returns the ID for a specified service contract, or all IDs for
    for service contracts that match the owner and implementation name of
    a service contract,
    if the contract is not specified.
} {
    if {([info exists contract] && $contract ne "")} {
        return [db_string select_impl_id_with_contract {}]
    } else {
        return [db_string select_impl_id {}]
    }
}

ad_proc -public acs_sc::impl::get {
    {-impl_id:required}
    {-array:required}
} {
    Get information about a service contract implementation.
    
    @param array Name of an array into which you want the info. 
                 Available columns are: impl_name, impl_owner_name, impl_contract_name.

    @author Lars Pind (lars@collaboraid.biz)
} {
    upvar 1 $array row
    db_1row select_impl {} -column_array row
}

ad_proc -public acs_sc::impl::get_options {
    {-contract_name:required}
    {-exclude_names ""}
    {-empty_label "-"}
} {
    Get a list of service contract implementation options
    for an HTML multiple choice widget.

    @param contract_name The name of the service contract
           to return options for.

    @param exclude_names A list of implementation names to exclude
    @param empty_label If provided an option with id empty string and the provided label will be added.

    @return A list of lists with the inner lists having label in first element and id in second.

    @author Peter Marklund
} {
    set full_list [db_list_of_lists select_impl_options {
        select case when impl_pretty_name is not null then impl_pretty_name else impl_name end as impl_name,
               impl_id
        from acs_sc_impls
        where impl_contract_name = :contract_name
    }]

    set impl_list [list]

    if { $empty_label ne "" } {
        lappend impl_list [list $empty_label ""]
    }

    if { [llength $exclude_names] > 0 } {
        # There are exclude names
        foreach element $full_list {
            set impl_name [lindex $element 0]
            if {$impl_name ni $exclude_names} {
                # Name is not in exclude list so add option
                lappend impl_list $element
            }
        }
    } else {
        # No exclude names, use all options
        set impl_list [concat $impl_list $full_list]
    }

    return $impl_list
}

#####
#
# Aliases
#
#####

ad_proc -public acs_sc::impl::alias::new {
    {-contract_name:required}
    {-impl_name:required}
    {-operation:required}
    {-alias:required}
    {-language "TCL"}
} {
    Add new service contract implementation alias 
    (the procedure that implements the operation in a contract).

    @return the ID of the implementation
} {
    set impl_id [db_exec_plsql alias_new {}]
}

ad_proc -private acs_sc::impl::alias::parse_aliases_spec {
    {-contract_name:required}
    {-impl_name:required}
    {-spec:required}
} {
    Parse multiple aliases.
} {
    foreach { operation subspec } $spec {
        parse_spec \
                -contract_name $contract_name \
                -impl_name $impl_name \
                -operation $operation \
                -spec $subspec
    }
}

ad_proc -private acs_sc::impl::alias::parse_spec {
    {-contract_name:required}
    {-impl_name:required}
    {-operation:required}
    {-spec:required}
} {
    Parse the spec for a single alias. The spec can either be just the
    name of a Tcl procedure, or it can be an array list containing the
    two keys 'alias' and 'language'.
} {
    if { [llength $spec] == 1 } {

        # Single-element spec, which means it's the name of a Tcl procedure
        new \
                -contract_name $contract_name \
                -impl_name $impl_name \
                -operation $operation \
                -alias $spec
    } else {
        # It's a full spec, expect 'alias' and 'language'
        array set alias $spec

        new \
                -contract_name $contract_name \
                -impl_name $impl_name \
                -operation $operation \
                -alias $alias(alias) \
                -language $alias(language)
        
    }
}




#####
#
# Bindings
#
#####

ad_proc -public acs_sc::impl::binding::new {
    {-contract_name:required}
    {-impl_name:required}
} {
    Bind implementation to the contract. Bombs if not all operations
    have aliases.
} {
    db_exec_plsql binding_new {}
}

ad_proc -private acs_sc::impl::binding::init_procs {
    {-impl_id:required}
} {
    Initialize the procs so we can call the service contract.
    
    Note that this proc doesn't really work, because it doesn't
    initialize the aliases in all interpreters, only in one.
} {
    # LARS:
    # This is a hack to get around the problem with multiple interpreters:
    # We ask the APM to reload the acs-service-contract-init file, which will
    # redefine the service contract wrapper procs

    set file "/packages/acs-service-contract/tcl/acs-service-contract-init.tcl"
    apm_mark_files_for_reload -force_reload [list $file]

    return
    #----------------------------------------------------------------------
    # NOTE: End of actual proc above this line. Stale code below
    #----------------------------------------------------------------------



    
    # LARS:
    # This is the left-over stuff, which we could one day resurrect if we
    # decide to implement an apm_eval feature, which can eval chunks of code
    # in each interpreter. Then we could just say 
    # apm_eval "acs_sc::impl::binding::init_procs_internal -impl_id $impl_id"
    
    # Get the list of aliases
    db_foreach impl_operation {
        select impl_contract_name, 
               impl_operation_name,
               impl_name
        from   acs_sc_impl_aliases
        where  impl_id = :impl_id
    } -column_array row {
        lappend rows [array get row]
    }
    
    # Register them
    # Hm. We need to do this in all interpreters
    foreach row_list $rows {
        array set row $row_list
        acs_sc_proc $row(impl_contract_name) $row(impl_operation_name) $row(impl_name)
    }
}

    

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
