
set context_bar [ad_context_bar]

db_multirow valid_installed_binding valid_installed_binding {
    select 
        contract_id,
        impl_id,
        acs_sc_contract__get_name(contract_id) as contract_name,
        acs_sc_impl__get_name(impl_id) as impl_name
    from
        acs_sc_binding
}


db_multirow valid_uninstalled_binding valid_uninstalled_binding {
    select contract_id, contract_name, impl_name,impl_id 
    from valid_uninstalled_binding;
}


db_multirow invalid_uninstalled_binding invalid_uninstalled_binding {
    select contract_id, contract_name, impl_name,impl_id 
    from invalid_uninstalled_binding;
}


db_multirow orphan_implementation orphan_implementation {
    select impl_id, impl_name, impl_contract_name  
    from orphan_implementation
}