ad_page_contract {
    Install from local file system
}


#####
#
# Display progress bar
#
#####


ad_progress_bar_begin \
    -title "Installing packages..." \
    -message_1 "Installing packages, please wait ..." \
    -message_2 "We will continue automatically when installation is complete."


#####
#
# Start installation process
#
#####


set pkg_install_list [ad_get_client_property apm pkg_install_list]
ns_log Debug "local-install-3.tcl: pkg_install_list=$pkg_install_list"

if { [llength $pkg_install_list] == 0 } {
    ns_log Notice "local-install-3.tcl: Nothing to install. Is this a double-click?"
}

# We unset the client property so we won't install these packages twice
ad_set_client_property apm pkg_install_list {}

set success_p 1

if { ![empty_string_p $pkg_install_list] } {
    set sql_files [list]

    foreach pkg_info $pkg_install_list {
        ns_log Notice "Installing $pkg_info"

        set package_key [pkg_info_key $pkg_info]
        set spec_file [pkg_info_spec $pkg_info]
        array set version [apm_read_package_info_file $spec_file]
        set final_version_name $version(name)

        if { [apm_package_version_installed_p $version(package.key) $version(name)] } {
            # Already installed.

            # Enable this version, in case it's not already enabled
            if { ![apm_package_enabled_p $version(package.key)] } {
                ns_log Notice "Package $version(package.key) $version(name) is already installed but not enabled, enabling"
                apm_version_enable -callback apm_dummy_callback [apm_highest_version $version(package.key)]
            } else {
                ns_log Notice "Package $version(package.key) $version(name) is already installed and enabled, skipping"
            }
            
            continue
        }

        # Determine if we are upgrading or installing.
        if { [apm_package_upgrade_p $package_key $final_version_name] == 1} {
            ns_log Debug "Upgrading package [string totitle $version(package-name)] to $final_version_name."
            set upgrade_p 1
            set initial_version_name [apm_highest_version $package_key]
        } else {
            set upgrade_p 0
            set initial_version_name ""
        }

        # Find out which script is appropriate to be run.
        set data_model_in_package 0
        set table_rows ""
        set data_model_files [concat \
                                  [apm_data_model_scripts_find \
                                       -upgrade_from_version_name $initial_version_name \
                                       -upgrade_to_version_name $final_version_name \
                                       $package_key] \
                                  [apm_ctl_files_find $package_key]]
        
        # Install the packages.
        set version_id [apm_package_install \
                            -enable \
                            -package_path "[acs_root_dir]/packages" \
                            -load_data_model \
                            -data_model_files $data_model_files \
                            $spec_file]
        
        if { $version_id == 0 } {
            # Installation of the package failed and we shouldn't continue with installation
            # as there might be packages depending on the failed package. Ideally we should
            # probably check for such dependencies and continue if there are none.
            set success_p 0
        }
    }
}

#####
#
# Done
#
#####

ad_progress_bar_end -url [export_vars -base local-install-4 { success_p }]


