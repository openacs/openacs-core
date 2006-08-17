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
    aa_log "Registering a parameter"
    apm_parameter_register -parameter_id $parameter_id $parameter_name $description $package_key $default_value $datatype

    set package_id [apm_package_id_from_key $package_key]    
    aa_true "check apm_parameter_register" [string equal [parameter::get -package_id $package_id -parameter $parameter_name] $default_value]
}

aa_register_case -cats {api smoke} parameter_unregister_test {
    Test the unregister of a parameter
} {    
    set parameter_id [db_nextval "acs_object_id_seq"]
    set parameter_name [ad_generate_random_string]
    set description "Description for the new parameter"
    set package_key "acs-tcl"
    set default_value "10"
    set datatype "number"
    aa_log "Registering a parameter"
    apm_parameter_register -parameter_id $parameter_id $parameter_name $description $package_key $default_value $datatype
    apm_parameter_unregister $parameter_id
    set package_id [apm_package_id_from_key $package_key]    
    aa_true "check apm_parameter_unregister" [string equal [parameter::get -package_id $package_id -parameter $parameter_name] ""]
}
