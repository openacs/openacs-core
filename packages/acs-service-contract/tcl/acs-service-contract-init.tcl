
db_foreach impl_operation {
    select 
        impl_contract_name, 
        impl_operation_name,
        impl_name
    from acs_sc_impl_aliases
} {

    acs_sc_log SCDebug "ACS_SC_PROC: checking binding exists for contract $impl_contract_name impl $impl_name"

    set binding_exists_p [db_string binding_exists_p {*SQL*}]

    if $binding_exists_p {
	acs_sc_proc $impl_contract_name $impl_operation_name $impl_name
    } else { 
        acs_sc_log SCDebug "ACS_SC_PROC: binding not found for contract $impl_contract_name impl $impl_name"
    }
}
