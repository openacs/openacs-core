ad_library {
    Testing for parameter registration
    @author Adrian Catalan (ykro@galileo.edu)
    @creation-date 2006-08-10
}

aa_register_case -cats {api smoke} parameter_register_test {
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
    apm_parameter_unregister $parameter_id

    set scope "global"
    aa_log "Registering a global parameter"
    apm_parameter_register -parameter_id $parameter_id -scope $scope $parameter_name $description $package_key $default_value $datatype
    aa_true "check apm_parameter_register global parameter" [string equal [parameter::get_global_value -package_key $package_key -parameter $parameter_name] $default_value]
    aa_log "Unregistering an global parameter"
    apm_parameter_unregister $parameter_id
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
