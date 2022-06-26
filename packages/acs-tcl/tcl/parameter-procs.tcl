ad_library {

    parameter procs

    @author yon (yon@openforce.net)
    @creation-date May 12, 2002
    @cvs-id $Id$

}

namespace eval parameter {}

ad_proc -public parameter::set_default {
    -package_key:required
    -parameter:required
    -value:required
} {
    Set the default for the package parameter to the provided value.
    The new default will be used for new installs of the package
    but does not change existing package instances values.

    @param package_key what package to set the parameter for
    @param parameter which parameter's value to set
    @param value what value to set said parameter to
} {
    db_dml set {}
}

ad_proc -public parameter::set_global_value {
    {-package_key:required}
    {-parameter:required}
    {-value:required}
} {
    Set a global package parameter.

    Do not confuse this with the proc "set_from_package_key", which was previously
    used to emulate global parameters declared for singleton packages.

    @param package_key identifies the package to which the global param belongs
    @param parameter which parameter's value to set
    @param value what value to set said parameter to
} {

    #db_exec_plsql set_parameter_value {}

    ::acs::dc call apm set_value \
        -package_key $package_key \
        -parameter $parameter \
        -attr_value $value

    acs::clusterwide callback subsite::global_parameter_changed \
        -package_key $package_key \
        -parameter $parameter \
        -value $value

    return [ad_parameter_cache -set $value $package_key $parameter]
}

ad_proc -public parameter::get_global_value {
    -localize:boolean
    -boolean:boolean
    {-package_key:required}
    {-parameter:required}
    {-default ""}
} {
    Get the value of a global package parameter.

    @param localize should we attempt to localize the parameter
    @param boolean ensure boolean parameters are normalized to 0 or 1
    @param package_key identifies the package to which the global param belongs
    @param parameter which parameter's value to get
    @param default what to return if we don't find a value. Defaults to returning the empty string.

    @return The string trimmed (leading and trailing spaces removed) parameter value
    @see parameter::get
} {

    # Is there a parameter by this name in the parameter file?  If so, it takes precedence.
    # Note that this makes *far* more sense for global parameters than for package instance
    # parameters.

    # 1. use the parameter file
    set value [ad_parameter_from_file $parameter $package_key]

    # 2. check the parameter cache
    if {$value eq ""} {
        set value [ad_parameter_cache -global $package_key $parameter]
    }
    # 3. use the default value
    if {$value eq ""} {
        set value $default
    }

    if { $localize_p } {
        # Replace message keys in hash marks with localized texts
        set value [lang::util::localize $value]
    }

    # Trimming the value as people may have accidentally put in trailing spaces
    set value [string trim $value]

    # Special parsing for boolean parameters, true and false can be written
    # in many different ways
    if { $boolean_p } {
        set value [template::util::is_true $value]
    }

    return $value
}

ad_proc -public parameter::set_value {
    {-package_id ""}
    {-parameter:required}
    {-value:required}
} {
    Set the value of a package instance parameter.

    @param package_id what package to set the parameter in. Defaults to
    [ad_conn package_id]
    @param parameter which parameter's value to set
    @param value what value to set said parameter to
} {
    if {$package_id eq ""} {
        set package_id [ad_requested_object_id]
    }

    #
    # We have two different definitions of set_parameter_value/3 with
    # differently typed arguments.  Polyphorism is not supported
    # yet. We should define set_value/4, or mirror the names we have
    # here (set_value vs. set_global_value). For the time being, we
    # keep the xql files for "db_exec_plsql" around, maybe some other
    # use cases hint a different approach.
    #
    db_exec_plsql set_parameter_value {}

    #::acs::dc call apm set_value \
    #    -package_id $package_id \
    #    -parameter_name $parameter \
    #    -attr_value $value

    acs::clusterwide callback subsite::parameter_changed \
        -package_id $package_id \
        -parameter $parameter \
        -value $value

    return [ad_parameter_cache -delete -set $value $package_id $parameter]
}

ad_proc -public parameter::get {
    -localize:boolean
    -boolean:boolean
    {-package_id ""}
    {-parameter:required}
    {-default ""}
} {
    Get the value of a package instance parameter.

    @param localize should we attempt to localize the parameter
    @param boolean ensure boolean parameters are normalized to 0 or 1
    @param package_id what package to get the parameter from. Defaults to
    [ad_conn package_id]
    @param parameter which parameter's value to get
    @param default what to return if we don't find a value. Defaults to returning the empty string.

    @return The string trimmed (leading and trailing spaces removed) parameter value
    @see parameter::get_global_value
} {

    if {$package_id eq ""} {
        set package_id [ad_requested_object_id]
    }
    set value ""

    # 1. check whether there is a parameter by this name specified for
    # the package in the parameter file.  The name
    # ad_parameter_from_file is a misnomer, since it checks
    # ns_config values
    #
    if {$package_id ne ""} {
        set package_key [apm_package_key_from_id $package_id]
        set value [ad_parameter_from_file $parameter $package_key]
    }

    # 2. check the parameter cache
    if {$value eq ""} {
        set value [ad_parameter_cache $package_id $parameter]
    }

    # 3. use the default value
    if {$value eq ""} {
        set value $default
    }

    if { $localize_p } {
        # Replace message keys in hash marks with localized texts
        set value [lang::util::localize $value]
    }
    #
    # Normalize boolean results if required, since "true" and "false"
    # can be written in many different ways.
    #
    if { $boolean_p } {
        set value [template::util::is_true $value]
    }

    return $value
}

ad_proc -public parameter::set_from_package_key {
    {-package_key:required}
    {-parameter:required}
    {-value:required}
} {
    sets an instance parameter for the package corresponding to package_key.

    Note that this makes the assumption that the package is a singleton
    and does not set the value for all packages corresponding to package_key.

    New packages should use global parameters instead.

} {
    parameter::set_value \
        -package_id [apm_package_id_from_key $package_key] \
        -parameter $parameter \
        -value $value
}

if {![db_table_exists apm_parameters]} {

    ad_proc -public parameter::get_from_package_key {
        -localize:boolean
        -boolean:boolean
        {-package_key:required}
        {-parameter:required}
        {-default ""}
    } {
        ns_log notice "parameter::get_from_package_key: called during initialization:" \
            "$package_key.$parameter -> '$default' (default)"
        return $default
    }

} else {

    ad_proc -public parameter::get_from_package_key {
        -localize:boolean
        -boolean:boolean
        {-package_key:required}
        {-parameter:required}
        {-default ""}
    } {
        Gets an instance parameter for the package corresponding to package_key.

        Note that this makes the assumption that the package is a singleton.

        New packages should use global parameters instead.

        @param package_key what package to get the parameter from. We will try
        to get the package_id from the package_key. This
        may cause an error if there are more than one
        instance of this package
        @param parameter which parameter's value to get
        @param default what to return if we don't find a value
    } {
        #
        # 1. Check to see if this parameter is being set in the server's
        #    configuration file; this value has highest precedence.
        #
        set value [ad_parameter_from_file $parameter $package_key]

        #
        # 2. Try to get the value from a global package parameter.
        #
        if {$value eq ""} {
            set value [parameter::get_global_value \
                           -localize=$localize_p \
                           -boolean=$boolean_p \
                           -package_key $package_key \
                           -parameter $parameter \
                           -default ""]
        }

        #
        # 3. Try to get the value from the package_id of this package_key
        #    and use the standard parameter::get function to get the
        #    value. Note that this lookup only makes sense for singleton
        #    packages.
        #
        if {$value eq ""} {
            if {[apm_package_singleton_p $package_key]} {
                set value [parameter::get \
                               -localize=$localize_p \
                               -boolean=$boolean_p \
                               -package_id [apm_package_id_from_key $package_key] \
                               -parameter $parameter \
                               -default $default \
                              ]
            } else {
                ns_log notice "tried to lookup parameter $parameter from non-singleton package $package_key"
                set value $default
            }
        }

        return $value
    }
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
