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
    if { $impl_id eq "" } {
        return {}
    }

    set parameters {}

    with_catch errmsg {
        set parameters [acs_sc::invoke \
                            -error \
                            -impl_id $impl_id \
                            -operation GetParameters]
    } {
        global errorInfo
        ns_log Error "Error getting parameters for impl_id $impl_id: $errmsg\n$errorInfo"
    }
    return $parameters
}

ad_proc -public auth::driver::get_parameter_values {
    {-authority_id:required}
    {-impl_id:required}
} {
    Gets a list of parameter values ready to be passed to a service contract implementation.
    If a parameter doesn't have a value, the value will be the empty string.

    @author Simon Carstensen (simon@collaboraid.biz)
    @creation-date 2003-08-27
} {
    array set param [list]

    db_foreach select_values {
        select key, value
        from   auth_driver_params
        where  impl_id = :impl_id
        and    authority_id = :authority_id
    } {
        set param($key) $value
    }

    # We need to ensure that the driver gets all the parameters it is asking for, and nothing but the ones it is asking for
    set params [list]
    foreach { name desc } [get_parameters -impl_id $impl_id] {
        if { [info exists param($name)] } {
            lappend params $name $param($name)
        } else {
            lappend params $name {}
        }
    }

    return $params
}

ad_proc -public auth::driver::set_parameter_value {
    {-authority_id:required}
    {-impl_id:required}
    {-parameter:required}
    {-value:required}
} {
    Updates the parameter value in the database.

    @author Simon Carstensen (simon@collaboraid.biz)
    @creation-date 2003-08-27
} {
    set exists_p [db_string param_exists_p {}]
 
    if { $exists_p } {
        db_dml update_parameter {} -clobs [list $value]
    } else {
        db_dml insert_parameter {} -clobs [list $value]
    }
}

ad_proc -public auth::driver::GetParameters { 
    {-impl_id:required}
} {
    Returns a list of names of parameters for the driver

    @author Simon Carstensen (simon@collaboraid.biz)
    @creation-date 2003-08-27
} {
    return [acs_sc::invoke \
                -error \
                -impl_id $impl_id \
                -operation GetParameters]
}

