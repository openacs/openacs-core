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
    {-owner:required}
} {
    Add new service contract implementation.
    
    @return the ID of the new implementation
} {
    return [db_exec_plsql impl_new {}]
}

ad_proc -public acs_sc::impl::delete {
    {-contract_name:required}
    {-impl_name:required}
} {
    Delete a service contract implementation 
} {

    if { ![exists_and_not_null contract_name] || ![exists_and_not_null impl_name] } {
        error "You must supply contract_name and impl_name"
    }

    db_exec_plsql delete_impl {} 
}

ad_proc -public acs_sc::impl::new_from_spec {
    {-spec:required}
} {
    Add new service contract implementation from an array-list style implementation.
    
    @return the ID of the new implementation
} {
    # Spec contains: contract_name, name, owner, aliases
    array set impl $spec
    
    db_transaction {
        set impl_id [new \
                -contract_name $impl(contract_name) \
                -name $impl(name) \
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
} {
    return [db_string select_impl_id {}]
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

    
