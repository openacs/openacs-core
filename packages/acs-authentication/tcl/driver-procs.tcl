ad_library {
    Procs for driver paramaters service contract implementations.

    @author Simon Carstensen (simon@collaobraid.biz)
    @creation-date 2003-08-27
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::driver {}



#####
#
# auth::driver
#
#####

ad_proc -public auth::driver::get_parameters { 
    {-impl_id:required}
} {
    Returns a list of names of parameters for the driver

    @author Simon Carstensen (simon@collaboraid.biz)
    @creation-date 2003-08-27
} {
    # Find the contract_name and impl_name 
    db_1row select_contract_impl_name {
        select impl_name as impl,
               impl_contract_name as contract
        from   acs_sc_impls
        where  impl_id = :impl_id
    }

    # Check that it's a contract that we know of, or that it has the GetParameters method
    set method_exists_p [db_string select_getparameters_method {
        select 1
        from   acs_sc_impl_aliases
        where  impl_id = :impl_id
        and    impl_operation_name = 'GetParameters'
    } -default "0"]

    if { $method_exists_p } {
        # call GetParameters on the impl and return that
        return [acs_sc::invoke \
                    -contract $contract \
                    -impl $impl \
                    -operation GetParameters]
    } else {
        # GetParameters method doesn't exist, throw an aa error
        aa_true "Does the GetParameter exist?" 0
    }
}

ad_proc -public auth::driver::get_parameter_values {
    {-impl_id:required}
    {-authority_id:required}
} {
    Gets a list of parameter values ready to be passed to a service contract implementation.
    If a parameter doesn't have a value, the value will be the empty string.

    @author Simon Carstensen (simon@collaboraid.biz)
    @creation-date 2003-08-27
} {
    return [db_list select_values {
        select value
        from   auth_driver_params
        where  impl_id = :impl_id
        and    authority_id = :authority_id
    }]
}

ad_proc -public auth::driver::set_parameter_value {
    {-impl_id:required}
    {-authority_id:required}
    {-parameter:required}
    {-value:required}
} {
    Updates the parameter value in the database.

    @author Simon Carstensen (simon@collaboraid.biz)
    @creation-date 2003-08-27
} {
    db_dml set_parameter {
        update auth_driver_params
        set    value = :value
        where  key = :parameter
        and    impl_id = :impl_id
        and    authority_id = :authority_id
    }
}
