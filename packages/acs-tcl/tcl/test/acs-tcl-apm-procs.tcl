ad_library {
    Tcl helper procedures for the acs-automated-testing tests of
    the acs-tcl package.

    @author Veronica De La Cruz (veronica@viaro.net)
    @creation-date  11 August 2006
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        apm_parameter_register
    } \
    test_apm_parameter__register {
        
        Test the apm_parameter_register procedure

        @author Veronica De La Cruz (veronica@viaro.net)

} {
    aa_run_with_teardown -rollback -test_code {

        set package_list [db_list get_packages "select package_key from apm_package_types"]
        aa_log "List of packages: \{$package_list\}"
        set list_index [randomRange [expr {[llength $package_list] - 1}]]
        set package_key [lrange $package_list $list_index $list_index]

        set parameter_name [ad_generate_random_string]
        set description [ad_generate_random_string]

        set values { {number} {string} }
        set index [randomRange 1]

        #
        # Choose randomly string or number parameter.  Also choose
        # randomly its default value in the string case.
        #
        set datatype [lrange $values $index $index]
        if {$datatype eq "number"} {
            set default_value 0
        } else {
            set default_value [ad_generate_random_string]
        }

        aa_log "Parameter to be added: name $parameter_name\n descr $description\n datatype $datatype\n default_value $default_value"

        set parameter_id [apm_parameter_register $parameter_name $description $package_key $default_value $datatype]

        aa_true "Parameter register succeeded" {$parameter_id ne ""}
    }
}

aa_register_case \
    -cats {api smoke} \
    -procs {apm_package_instance_new} \
    test_apm_package_instance__new {
        
        Test the apm_package_instance_new procedure
        @author Veronica De La Cruz (veronica@viaro.net)
} {

    aa_run_with_teardown -rollback -test_code {

        set package_list [db_list get_packages "select package_key from apm_package_types"]
        aa_log "List of packages: \{$package_list\}"

        set list_index [randomRange [expr {[llength $package_list] - 1}]]
        set package_key [lrange $package_list $list_index $list_index]
        set instance_name "$package_key-[ad_generate_random_string]"

        aa_log "Package to be instantiated: $package_key"
        aa_log "Instance name to be added: $instance_name"
        set error_occurred [catch {
            set package_id [apm_package_instance_new -package_key $package_key -instance_name $instance_name ]
        } err_men]
        aa_log "Error Message $error_occurred: $err_men "
        aa_true "Setting the new instance succeeded" {[info exists package_id] && $package_id ne ""}
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
