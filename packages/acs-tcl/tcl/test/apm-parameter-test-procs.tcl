ad_library {
    Testing for parameter registration
    @author Adrian Catalan (ykro@galileo.edu)
    @creation-date 2006-08-10
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        apm_package_id_from_key
        apm_parameter_register
        apm_parameter_unregister
        parameter::get
        parameter::get_global_value

        db_1row
    } \
    parameter_register_test {
    Test the registration of a parameter
} {
    set parameter_id [db_nextval "acs_object_id_seq"]
    set parameter_name [ad_generate_random_string]
    set description "Description for the new parameter"
    set package_key "acs-tcl"
    set default_value "5"
    set datatype "number"
    set scope "instance"
    aa_log "Registering an instance parameter"
    apm_parameter_register -parameter_id $parameter_id -scope $scope $parameter_name $description $package_key $default_value $datatype

    set package_id [apm_package_id_from_key $package_key]
    aa_true "check apm_parameter_register instance parameter" [string equal [parameter::get -package_id $package_id -parameter $parameter_name] $default_value]
    aa_log "Unregistering an instance parameter"
    apm_parameter_unregister -parameter_id $parameter_id

    set scope "global"
    aa_log "Registering a global parameter"
    apm_parameter_register -parameter_id $parameter_id -scope $scope $parameter_name $description $package_key $default_value $datatype
    aa_true "check apm_parameter_register global parameter" [string equal [parameter::get_global_value -package_key $package_key -parameter $parameter_name] $default_value]
    aa_log "Unregistering a global parameter"
    apm_parameter_unregister -parameter_id $parameter_id
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_parameter_cache
        apm_package_id_from_key
        apm_parameter_register
        apm_parameter_unregister
        parameter::get
        parameter::get_from_package_key
        parameter::get_global_value
        parameter::set_default
        parameter::set_from_package_key
        parameter::set_global_value
        parameter::set_value
        db_list_of_lists
        util::random

        db_1row
        "::xowiki::Package proc is_xowiki_p"
    } \
    parameter__check_procs {
    Test the parameter::* procs

    @author Rocael Hernandez (roc@viaro.net)
} {

    aa_run_with_teardown -rollback -test_code {

            aa_log "Test global parameter functionality"
            set parameter_id [db_nextval "acs_object_id_seq"]
            apm_parameter_register -parameter_id $parameter_id -scope global x_test_x "" acs-tcl 0 number
            parameter::set_global_value -package_key acs-tcl -parameter x_test_x -value 3
            aa_equals "check global parameter value set/get" \
                [parameter::get_global_value -package_key acs-tcl -parameter x_test_x] \
                3
            apm_parameter_unregister -parameter_id $parameter_id

            db_foreach get_params {
                select ap.parameter_name, ap.package_key, ap.default_value, ap.parameter_id
                from apm_parameters ap, apm_package_types apt
                where
                ap.package_key = apt.package_key
                and ap.scope = 'instance'
                and apt.singleton_p = 't'
            } {
                aa_section "$package_key - $parameter_name"

                #
                # parameter::* API currently does not support changing
                # the value of parameters that are defined in the
                # server configuration file.
                #
                set file_value [ad_parameter_from_file $parameter_name $package_key]
                if {$file_value ne ""} {
                    continue
                }

                #
                # Instance parameters have a value only when a package
                # is mounted. This is not always true for a singleton
                # package.
                #
                set package_id [apm_package_id_from_key $package_key]
                if {$package_id == 0} {
                    continue
                }

                set value [util::random]

                set actual_value [db_string real_value {
                    select apm_parameter_values.attr_value
                    from   apm_parameter_values
                    where apm_parameter_values.package_id = :package_id
                    and apm_parameter_values.parameter_id = :parameter_id
                }]

                aa_log "$package_key $parameter_name $actual_value"
                aa_equals "check parameter::get" \
                    [parameter::get -package_id $package_id -parameter $parameter_name] \
                    $actual_value
                aa_equals "check parameter::get_from_package_key" \
                    [parameter::get_from_package_key -package_key $package_key -parameter $parameter_name] \
                    $actual_value

                parameter::set_default -package_key $package_key -parameter $parameter_name -value $value
                set value_db [db_string get_values {
                    select default_value from apm_parameters
                    where package_key = :package_key and parameter_name = :parameter_name
                }]
                aa_equals "check parameter::set_default" $value $value_db
                set value [expr {$value + 10}]

                parameter::set_from_package_key -package_key $package_key -parameter $parameter_name -value $value
                aa_equals "check parameter::set_from_package_key" \
                    [parameter::get -package_id $package_id -parameter $parameter_name] \
                    $value

                set value [expr {$value + 10}]
                parameter::set_value -package_id $package_id -parameter $parameter_name -value $value
                aa_equals "check parameter::set_value" \
                    [parameter::get -package_id $package_id -parameter $parameter_name] \
                    $value

                parameter::set_from_package_key \
                    -package_key $package_key \
                    -parameter $parameter_name \
                    -value $actual_value

                parameter::set_value \
                    -package_id $package_id \
                    -parameter $parameter_name \
                    -value $actual_value

                parameter::set_default \
                    -package_key $package_key \
                    -parameter $parameter_name \
                    -value $default_value
            }
        }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
