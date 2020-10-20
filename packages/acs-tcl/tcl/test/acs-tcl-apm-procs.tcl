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

        set package_list [db_list get_packages {
            select package_key
              from apm_enabled_package_versions
        }]
        aa_log "List of packages: [list $package_list]"
        set list_index [util::random_range [expr {[llength $package_list] - 1}]]
        set package_key [lrange $package_list $list_index $list_index]
        set parameter_name  [ad_generate_random_string]
        set description     [ad_generate_random_string]

        set values { {number} {string} }
        set index [util::random_range 1]

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

        aa_log "$package_key parameter to be added: name $parameter_name
        descr $description
        datatype $datatype
        default_value $default_value"

        set parameter_id [apm_parameter_register \
            $parameter_name \
            $description \
            $package_key \
            $default_value \
            $datatype]

        aa_true "$package_key parameter register succeeded" \
            {$parameter_id ne ""}

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

        set package_list [db_list get_packages {
            select package_key
              from apm_enabled_package_versions
        }]
        aa_log "List of packages: [list $package_list]"

        foreach package_key $package_list {
            set package_id ""
            set instance_name "$package_key-[ad_generate_random_string]"

            aa_log "Package to be instantiated: $package_key"
            aa_log "Instance name to be added: $instance_name"
            set error_occurred [catch {
                set package_id [apm_package_instance_new \
                    -package_key $package_key \
                    -instance_name $instance_name ]
            } err_men]
            aa_log "Error Message $error_occurred: $err_men "
            aa_true "Setting the new instance succeeded" {$package_id ne ""}
        }
    }
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs apm_version_names_compare \
    apm_version_names_compare {

        Test the apm_version_names_compare proc

        @author Hanifa Hasan
} {
    set versions [list \
        {1.2d3 3.5b -1} \
        {3.5b 1.2d3 1} \
        {3.5b 3.5b 0} \
        {5.0.0d5 5.0.0b1 -1} \
        {5.0.0a5 5.0.0b1 -1} \
        {5.0.0d5 5.0.0a1 -1} \
    ]
    aa_log "-1: First version is earlier"
    aa_log "0: Both versions are equal"
    aa_log "1: Second version is earlier"
    foreach version $versions {
        set version_name1 [lindex $version 0]
        set version_name2 [lindex $version 1]
        set result        [lindex $version 2]
        aa_equals "Comparing $version_name1 and $version_name2" [apm_version_names_compare $version_name1 $version_name2] "$result"
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
