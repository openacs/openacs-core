ad_library {

    parameter procs

    @author yon (yon@openforce.net)
    @creation-date May 12, 2002
    @version $Id$

}

namespace eval parameter {

    ad_proc -public set_value {
        {-package_id ""}
        {-parameter:required}
        {-value:required}
    } {
        set a parameter

        @param package_id what package to set the parameter in. defaults to
                          [ad_conn package_id]
        @param parameter which parameter's value to set
        @param value what value to set said parameter to
    } {
        if {[empty_string_p $package_id]} {
            ::set package_id [ad_requested_object_id]
        }

        db_exec_plsql set_parameter_value {}

        return [ad_parameter_cache -set $value $package_id $parameter]
    }

    ad_proc -public get {
        {-package_id ""}
        {-parameter:required}
        {-default ""}
    } {
        get a parameter

        @param package_id what package to get the parameter from. defaults to
                          [ad_conn package_id]
        @param parameter which parameter's value to get
        @param default what to return if we don't find a value
    } {
        if {[empty_string_p $package_id]} {
            ::set package_id [ad_requested_object_id]
        }

        # 1. check to see if this parameter is being set in the server's
        # configuration file; this value has highest precedence
        ::set value [ad_parameter_from_file $parameter $package_id]

        # 2. check the parameter cache
        if {[empty_string_p $value]} {
            ::set value [ad_parameter_cache $package_id $parameter]
        }

        # 3. use the default value
        if {[empty_string_p $value]} {
            ::set value $default
        }

        return $value
    }

    ad_proc -public set_from_package_key {
        {-package_key:required}
        {-parameter:required}
        {-value:required}
    } {
        set_value \
            -package_id [apm_package_id_from_key $package_key] \
            -parameter $parameter \
            -value $value
    }

    ad_proc -public get_from_package_key {
        {-package_key:required}
        {-parameter:required}
        {-default ""}
    } {
        get a parameter

        @param package_key what package to get the parameter from. we will try
                           to get the package_id from the package_key. this
                           may cause an error if there are more than one
                           instance of this package
        @param parameter which parameter's value to get
        @param default what to return if we don't find a value
    } {
        with_catch errmsg {
            ::set value [get \
                -package_id [apm_package_id_from_key $package_key] \
                -parameter $parameter \
                -default $default \
            ]
        } {
            ::set value $default
        }

        return $value
    }

}
