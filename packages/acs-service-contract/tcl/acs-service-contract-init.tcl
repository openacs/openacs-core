
db_foreach impl_operation {
    select 
        impl_contract_name, 
        impl_operation_name,
        impl_name
    from acs_sc_impl_aliases
} {

    set binding_exists_p [db_string binding_exists_p {select acs_sc_binding__exists_p(:impl_contract_name,:impl_name)}]

    if $binding_exists_p {
	acs_sc_proc $impl_contract_name $impl_operation_name $impl_name
    }
}
