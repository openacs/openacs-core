ad_page_contract {
    Install from local file system
} {
}

set page_title "Install"

set context [list [list "." "Install Applications"] [list "local-install" "Install From Local File System"] $page_title]

set pkg_install_list [ad_get_client_property apm pkg_install_list]

set sql_file_list [list]


foreach pkg_info $pkg_install_list {

    set package_key [pkg_info_key $pkg_info]
    array set version [apm_read_package_info_file [pkg_info_spec $pkg_info]]
    set final_version_name $version(name)

    # Determine if we are upgrading or installing.
    if { [apm_package_upgrade_p $package_key $final_version_name] == 1} {
	ns_log Debug "Upgrading package [string totitle $version(package-name)] to $final_version_name."
	set upgrade_p 1
	set initial_version_name [db_string apm_package_upgrade_from {
	    select version_name from apm_package_versions
	    where package_key = :package_key
	    and version_id = apm_package__highest_version(:package_key)
	} -default ""]
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

    set sql_file_list [concat $sql_file_list $data_model_files]
}




set sql_files $sql_file_list

set error_p 0

set installed_count 0
foreach pkg_info $pkg_install_list {
    set spec_file [pkg_info_spec $pkg_info]
    if { [catch {
	array set version [apm_read_package_info_file $spec_file]
    } errmsg] } {
	ns_write "<li> Unable to install the [pkg_info_key $pkg_info] package because its specification
	file is invalid: <blockquote><pre>[ad_quotehtml $errmsg]</pre></blockquote>"
	continue
    }

    if {[apm_package_version_installed_p $version(package.key) $version(name)] } {
	# Already installed.
	continue
    }

    set package_key $version(package.key)
    set version_files $version(files)

    set data_model_files [list]
    # Find the correct data model files for this package.
    foreach file $sql_files {
	if {![string compare [lindex $file 2] $package_key]} {
	    # Pass on the file path and its type.
	    lappend data_model_files $file
	}
    }

    # Install the packages.
    set version_id [apm_package_install \
                        -enable \
                        -install_path "[acs_root_dir]/packages" \
                        -load_data_model \
                        -data_model_files $data_model_files \
                        $spec_file]
    
    if { $version_id == 0 } {
        # Installation of the package failed and we shouldn't continue with installation
        # as there might be packages depending on the failed package. Ideally we should
        # probably check for such dependencies and continue if there are none.
        set error_p 1
        break
    }
    
    incr installed_count
}


