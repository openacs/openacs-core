ad_library {

    Routines used for installing packages.

    @creation-date September 11 2000
    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$
}


ad_proc apm_scan_packages { 
    {-callback apm_dummy_callback}
    {-new:boolean}
    {path ""}
} {
    Scans a directory for unregistered package specification files.
    @param new.  Specify this parameter if you don't want packages that are already present
    to be picked up by the scan.  The initial installer needs to specify this.
    @return A list of unregistered .info files that can be parsed for further information.
} {

    if { [empty_string_p $path] } {
	set path "[apm_workspace_install_dir]"
    }

    ### Scan for all unregistered .info files.
    
    ns_log "Notice" "Scanning for new unregistered packages..."
    set new_spec_files [list]
    # Loop through all directories in the /packages directory, searching each for a
    # .info file.
    foreach dir [lsort [glob -nocomplain "$path/*"]] {
	set package_key [file tail $dir]
	if { ![file isdirectory $dir] } {
	    continue
	}
	if { [apm_ignore_file_p $dir] } {
	    apm_callback_and_log $callback "Skipping the directory \"$package_key\"."
	    continue
	}

	# At this point, we should have a directory that is equivalent to a package_key.
	if { [apm_package_installed_p $package_key] } {
	    if {$new_p} {
		continue
	    }
	}
	
	# Locate the .info file for this package.
	if { [catch { set info_file [apm_package_info_file_path -path $path $package_key] } error] } {
	    apm_callback_and_log -severity Warning $callback "Unable to locate specification file for package $package_key: $error"
	    continue
	}
	# We found the .info file.
	lappend new_spec_files $info_file
    }
        
    if { [llength $new_spec_files] == 0 } {
	ns_log "Notice" "No new packages found."
    }   
    return $new_spec_files
}
 

ad_proc -public apm_dependency_provided_p {
    {
	-dependency_list [list]
    }
    dependency_uri dependency_version
} {
    Returns 1 if the current system provides the dependency inquired about.
    Returns -1 if the version number is too low.
    Returns 0 otherwise.
    @param dependency_list Specify this if you want to a check a list of dependencies of form 
	{dependency_name dependency_version} in addition to querying the database for what the 
	system currently provides.
    @param dependency_uri The dependency that is being checked.
    @param dependency_version The version of the dependency being checked.
} {
    set old_version_p 0
    set found_p 0
    ns_log Debug "Scanning for $dependency_uri version $dependency_version"
    db_foreach apm_dependency_check {
	select apm_package_version.version_name_greater(service_version, :dependency_version) as version_p
	from apm_package_dependencies d, apm_package_types a, apm_package_versions v
	where d.dependency_type = 'provides'
	and d.version_id = v.version_id
	and d.service_uri = :dependency_uri
	and v.installed_p = 't'
	and a.package_key = v.package_key
    } {
	if { $version_p >= 0 } {
	    ns_log Debug "Dependency satisfied by previously installed package"
	    set found_p 1
	} elseif { $version_p == -1 } {
	    set old_version_p 1
	}
    }

    # Can't return while inside a db_foreach.
    if {$found_p} {
	return 1
    }

    if { ![empty_string_p $dependency_list] } {
	# They provided a list of provisions.
	foreach prov $dependency_list {
	    if {![string compare $dependency_uri [lindex $prov 0]] } {
		if { $dependency_version <= [lindex $prov 1] } {
		    ns_log Debug "Dependency satisfied in list of provisions."
		    return 1
		} else {
		    if [catch {
			if { $dependency_version > [lindex $prov 1] } {
			    set old_version_p 1
			}
		    } errmsg] {
			ns_log Error "Error processing dependencies: $errmsg"
		    }
		}
	    }
	}
    }
	
    if { $old_version_p} {
	return -1
    } else {
	return 0
    }
}

ad_proc -private pkg_info_new { package_key spec_file_path provides requires {dependency_p ""} {comment ""}} {
    
    Returns a datastructure that maintains information about a package.
    @param package_key The key of the package.
    @param spec_file_path The path to the package specification file
    @param provides A list of dependencies provided by the package.
    @param requires A list of requirements provided by the package..
    @param dependency_p Can the package be installed without violating dependency checking.
    @param comment Some text about the package.  Useful to explain why it fails dependency check.
    @return a list whose first element is a package key and whose second element is a path 
    to the associated .info file.
} {
    return [list $package_key $spec_file_path $provides $requires $dependency_p $comment]
}

ad_proc -private pkg_info_key {pkg_info} {

    @return The package-key  stored in the package info map.

} {
    return [lindex $pkg_info 0]
}

ad_proc -private pkg_info_spec {pkg_info} {

    @return The .info file stored in the package info map.

} {
    return [lindex $pkg_info 1]
}


ad_proc -private pkg_info_provides {pkg_info} {

    @return The dependencies provided by the package.

} {
    return [lindex $pkg_info 2]
}

ad_proc -private pkg_info_requires {pkg_info} {

    @return The dependencies required by the package info map.

} {
    return [lindex $pkg_info 3]
}

ad_proc -private pkg_info_dependency_p {pkg_info} {

    @return Does it pass the dependency checker?  "" Means it has not been run yet.

} {
    return [lindex $pkg_info 4]
}

ad_proc -private pkg_info_comment {pkg_info} {

    @return Any comment specified about this package.

} {
    return [lindex $pkg_info 5]
}

# DRB: This routine does more than check dependencies, it also parses spec files,
# something that really should be done separately, at least for bootstrap installation.
# I'm leaving it alone for now, though, and kludging it further by passing in a
# boolean to determine whether to process all spec files or just those needed for
# initial bootstrap installation.  I've also modified it to screen out packages that
# don't support the currently running RDBMS - a bit of a hack to do it here but it
# needed doing somewhere...

ad_proc -private apm_dependency_check {
    {-callback apm_dummy_callback}
    {-initial_install:boolean}
    spec_files
} {
    Check dependencies of all the packages provided.
    @param spec_files A list of spec files to be processed.
    @param initial_install Only process spec files with the initial install attribute.
    @return A list whose first element indicates whether dependencies were satisfied (1 if so, 0 otherwise).\
    The second element is the package info list with the packages ordered according to dependencies.\
    Packages that can be installed come first.  Any packages that failed the dependency check come last. 
} {
    #### Iterate over the list of info files.
    ## Every time we satisfy another package, remove it from install_pend, and loop again.
    ## If we don't satisfy at least one more package, halt.
    ## install_in - Packages that can be installed in a satisfactory order.
    ## install_pend - Stores packages that might have their dependencies satisfied 
    ##		      by packages in the install set.

    set updated_p 1
    set install_in [list]
    foreach spec_file $spec_files {
	if { [catch {
	    array set package [apm_read_package_info_file $spec_file]
	    if { ([string equal $package(initial-install-p) "t"] || !$initial_install_p) && \
                 [db_package_supports_rdbms_p $package(database_support)] } {
	        lappend install_pend [pkg_info_new $package(package.key) $spec_file $package(provides) $package(requires) ""]
            }
	} errmsg]} {
	    # Failed to parse the specificaton file.
	    apm_callback_and_log $callback "$spec_file could not be parsed correctly.  It is not being installed. 
	    The error: $errmsg"
	}
    }

    while { $updated_p && [exists_and_not_null install_pend]} {
	set install_in_provides [list]
	set new_install_pend [list]
	set updated_p 0
	# Generate the list of dependencies currently provided by the install set.
	foreach pkg_info $install_in {
	    foreach prov [pkg_info_provides $pkg_info] {
		lappend install_in_provides $prov
	    }
	}	
	# Now determine if we can add another package to the install set.
	foreach pkg_info $install_pend {
	    set satisfied_p 1
	    foreach req [pkg_info_requires $pkg_info] {
		if {[apm_dependency_provided_p -dependency_list $install_in_provides \
			 [lindex $req 0] [lindex $req 1]] != 1} {
		    # Unsatisfied dependency.
		    set satisfied_p 0
		    # Check to see if we've recorded it already
		    set errmsg "Requires [lindex $req 0] of version >= [lindex $req 1]."
		    if { ![info exists install_error([pkg_info_key $pkg_info])] || \
			     [lsearch -exact $install_error([pkg_info_key $pkg_info]) $errmsg] == -1} {
			lappend install_error([pkg_info_key $pkg_info]) $errmsg
		    }
		    lappend new_install_pend $pkg_info
		    break
		}
	    }
	    if { $satisfied_p } {
		# At least one more package was added to the list that can be installed, so repeat.
		lappend install_in [pkg_info_new [pkg_info_key $pkg_info] [pkg_info_spec $pkg_info] \
					 [pkg_info_provides $pkg_info] [pkg_info_requires $pkg_info] \
					 "t" "Package satisfies dependencies."]
		set updated_p 1
	    }
	}
	set install_pend $new_install_pend
    }

    set install_order(order) $install_in
    # Update all of the packages that cannot be installed.
    if { [exists_and_not_null install_pend] } {
	foreach pkg_info $install_pend {
	    lappend install_in [pkg_info_new [pkg_info_key $pkg_info] [pkg_info_spec $pkg_info] \
				    [pkg_info_provides $pkg_info] [pkg_info_requires $pkg_info] \
				    "f" $install_error([pkg_info_key $pkg_info])]
	}
	return [list 0 $install_in]
    }
    return [list 1 $install_in]
}


ad_proc -private apm_package_install { 
    {-callback apm_dummy_callback}
    {-copy_files:boolean}
    {-load_data_model:boolean}
    {-data_model_files 0}
    {-install_path ""}
    spec_file_path } {

    Registers a new package and/or version in the database, returning the version_id.
    If $callback is provided, periodically invokes this procedure with a single argument
    containing a human-readable (English) status message.
    @param spec_file_path The path to an XML .info file relative to
    @return The version_id if successfully installed, 0 otherwise.
} {
    set version_id 0
    array set version [apm_read_package_info_file $spec_file_path]
    set package_key $version(package.key)

    if { $copy_files_p } {
	if { [empty_string_p $install_path] } {
	    set install_path [apm_workspace_install_dir]/$package_key
	}
	ns_log Notice "Copying $install_path to [acs_package_root_dir $package_key]"
	exec "cp" "-r" -- "$install_path/$package_key" [acs_root_dir]/packages/
    }

    # Install Queries (OpenACS Query Dispatcher - ben)
    apm_package_install_queries $package_key $version(files)

    if { $load_data_model_p } {
	    apm_package_install_data_model -callback $callback -data_model_files $data_model_files $spec_file_path
    }

    with_catch errmsg {
	set package_uri $version(package.url)
	set package_type $version(package.type)
	set package_name $version(package-name)
	set pretty_plural $version(pretty-plural)
	set initial_install_p $version(initial-install-p)
	set singleton_p $version(singleton-p)
	set version_name $version(name)
	set version_uri $version(url)
	set summary $version(summary)
	set description_format $version(description.format)
	set description $version(description)
	set release_date $version(release-date)
	set vendor $version(vendor)
	set vendor_uri $version(vendor.url)
	set split_path [split $spec_file_path /]
	set relative_path [join [lreplace $split_path 0 [lsearch -exact $package_key $split_path]] /] 
	# Register the package if it is not already registered.
	if { ![apm_package_registered_p $package_key] } {
	    apm_package_register $package_key $package_name $pretty_plural $package_uri $package_type $initial_install_p $singleton_p $relative_path
	}
	    
	# If an older version already exists in apm_package_versions, update it;
	# otherwise, insert a new version.
	if { [db_0or1row version_exists_p {
	    select version_id 
	    from apm_package_versions 
	    where package_key = :package_key
	    and version_id = apm_package.highest_version(:package_key)
	} ]} {
	    set version_id [apm_package_install_version -callback $callback $package_key $version_name \
		    $version_uri $summary $description $description_format $vendor $vendor_uri $release_date]
	    apm_version_upgrade $version_id
	    apm_package_upgrade_parameters -callback $callback $version(parameters) $package_key
	} else {
	    set version_id [apm_package_install_version -callback $callback $package_key $version_name \
				$version_uri $summary $description $description_format $vendor $vendor_uri $release_date]

	    ns_log Notice "INSTALL-HACK-LOG-BEN: version_id is $version_id"

	    if { !$version_id } {
		# There was an error.
		apm_callback_and_log $callback "The package version could not be created."
	    }
	    # Install the paramters for the version.
	    apm_package_install_parameters -callback $callback $version(parameters) $package_key
	}
	# Update all other package information.
	apm_package_install_dependencies -callback $callback $version(provides) $version(requires) $version_id
	apm_package_install_owners -callback $callback $version(owners) $version_id
	apm_package_install_files -callback $callback $version(files) $version_id
	apm_callback_and_log $callback "<p>Installed $version(package-name), version $version(name).<p>"
    } {
	apm_callback_and_log $callback "<p>Failed to install $version(package-name), version $version(name).  The following error was generated:
<pre><blockquote>
[ad_quotehtml $errmsg]
</blockquote></pre>"
	return 0
    }
    if {![string compare $package_type "apm_service"] && ![string compare $singleton_p "t"]} {
	# This is a singleton package.  Instantiate it automatically.
	if {[catch {
	    db_exec_plsql package_instantiate_mount {
	        declare
  	            instance_id   apm_packages.package_id%TYPE;
	        begin
	            instance_id := apm_package.new(
	                          instance_name => :package_name,
			  	  package_key => :package_key,
				  context_id => acs.magic_object_id('default_context')
				  );
	        end;
	    }
	} errmsg]} {
	    apm_callback_and_log $callback "[string totitle $package_key] not instantiated.<p> Error:
	    <pre><blockquote>[ad_quotehtml $errmsg]</blockquote></pre>"
	} else {
	    apm_callback_and_log $callback "[string totitle $package_key] instantiated as $package_key.<p>"
	}
    }
    return $version_id
}

ad_proc -private apm_package_install_version {
    {
	-callback apm_dummy_callback
	-version_id ""
    }
    package_key version_name version_uri summary description description_format vendor vendor_uri {release_date ""} 
} {
    Installs a version of a package into the ACS.
    @return The assigned version id.
} {
    if { [empty_string_p $version_id] } {
	set version_id [db_null]
    }
    if { [empty_string_p $release_date] } {
	set release_date [db_null]
    }

    return [db_exec_plsql version_insert {
		begin
		:1 := apm_package_version.new(
			version_id => :version_id,
			package_key => :package_key,
			version_name => :version_name,
			version_uri => :version_uri,
			summary => :summary,
			description_format => :description_format,
			description => :description,
			release_date => :release_date,
			vendor => :vendor,
			vendor_uri => :vendor_uri,
			installed_p => 't',
			data_model_loaded_p => 't'
	              );
		end;
	    }]
}


ad_proc -private apm_package_deinstall {
    {
	-callback apm_dummy_callback
    } package_key
} {

    Deinstalls a package from the filesystem.
    @param package_key The package  to be deinstaleled.

} {
    if {![apm_package_registered_p $package_key]} {
	apm_callback_and_log $callback "This package is not installed.  Done."
	return 0
    }

    # Obtain the portion of the email address before the at sign. We'll use this in the name of
    # the backup directory for the package.
    regsub {@.+} [cc_email_from_party [ad_get_user_id]] "" my_email_name

    set backup_dir "[apm_workspace_dir]/$package_key-removed-$my_email_name-[ns_fmttime [ns_time] "%Y%m%d-%H:%M:%S"]"
    
    apm_callback_and_log $callback "
    <li>Moving <tt>packages/$package_key</tt> to $backup_dir... "

    if { [catch { file rename "[acs_root_dir]/packages/$package_key" $backup_dir } error] } {
	apm_callback_and_log $callback "<font color=red>[ns_quotehtml $error]</font>"
    } else {
	apm_callback_and_log $callback "moved."
    }

    db_dml apm_uninstall_record {
	update apm_package_versions
	set    installed_p = 'f', enabled_p = 'f'
	where package_key = :package_key
    }

    apm_callback_and_log $callback "<li>Package marked as deinstalled.
    "
    return 1
}

ad_proc -private apm_package_delete {
    { 
	-callback apm_dummy_callback

    }
    {-remove_files:boolean}
    package_key
} {
    
    Deinstalls and deletes a package from the ACS and the filesystem.

} {
    apm_callback_and_log $callback "<li>Deleting $package_key..."
    db_exec_plsql apm_package_delete {
	begin
	    apm_package_type.drop_type(
	        package_key => :package_key,
	        cascade_p => 't'
            );
	end;
    }
    # Remove the files from the filesystem
    if {$remove_files_p == 1} {
	if { [catch { 
	    file delete -force [acs_package_root_dir $package_key] 
	} error] } {
	    apm_callback_and_log $callback "<li>Unable to delete [acs_package_root_dir $package_key]:<font color=red>$error</font>"
	}
    }
    apm_callback_and_log $callback "<p>Done."
}

ad_proc -private apm_package_version_delete {
    {
	-callback apm_dummy_callback
    }
    version_id
} {
    Deletes a version from the database.
} {
    db_exec_plsql apm_version_delete {
	begin
	 apm_package_version.delete(version_id => :version_id);	 
	end;
    }
}

ad_proc -public apm_package_version_count {package_key} {
    
    @return The number of versions of the indicated package.
} {
    return [db_string apm_package_version_count {
	select count(*) from apm_package_versions
	where package_key = :package_key
    } -default 0]
}

ad_proc -private apm_package_install_data_model {
    {-callback apm_dummy_callback}
    {-upgrade_from_version_name ""}
    {-data_model_files "0"}
    {-path ""}
    spec_file
} {
    Given a spec file, reads in the data model files to load from it.
} {
    array set version [apm_read_package_info_file $spec_file]
    set package_key $version(package.key)
    set upgrade_to_version_name $version(name)

    if { [empty_string_p $path] } {
	set path "[acs_package_root_dir $package_key]"
    }
    set ul_p 0

    if {($data_model_files == 0)} {
	set data_model_files [apm_data_model_scripts_find \
		-upgrade_from_version_name $upgrade_from_version_name \
		-upgrade_to_version_name $upgrade_to_version_name \
		$package_key $version(files)]
    }

    if { ![empty_string_p $data_model_files] } {
	apm_callback_and_log $callback "<p><li>Installing data model for $version(package-name) $version(name)...\n"
    }
    
    foreach item $data_model_files {
	set file_path [lindex $item 0]
	set file_type [lindex $item 1]
	ns_log Debug "APM: Now processing $file_path of type $file_type"
	if {![string compare $file_type "data_model_create"] || \
		![string compare $file_type "data_model_upgrade"] } {
	    if { !$ul_p } {
		apm_callback_and_log $callback "<ul>\n"
		set ul_p 1
	    }
	    apm_callback_and_log $callback "<li>Loading data model $path/$file_path...
<blockquote><pre>
"
	    db_source_sql_file -callback $callback $path/$file_path
	    apm_callback_and_log $callback "</pre></blockquote>\n"
	} elseif { ![string compare $file_type "sqlj_code"] } {
	    if { !$ul_p } {
		apm_callback_and_log $callback "<ul>\n"
		set ul_p 1
	    }
	    apm_callback_and_log $callback "<li>Loading SQLJ code $path/$file_path...
<blockquote><pre>
"
	    db_source_sqlj_file -callback $callback "$path/$file_path"
	    apm_callback_and_log $callback "</pre></blockquote>\n"
	}
    }
    if {$ul_p} {
	apm_callback_and_log $callback "</ul><p>"
    }
}

ad_proc -private apm_package_upgrade_parameters { 
    {-callback apm_dummy_callback} parameters package_key
} {

    Upgrades the parameters to the current version.

} {
    set current_parameter_names [list]
    # Update each parameter that exists.
    foreach parameter $parameters {
	set parameter_name [lindex $parameter 0]
	# Keep a running tally of all parameters that are in the current version.
	lappend current_parameter_names $parameter_name
	set description [lindex $parameter 1]
	set section_name [lindex $parameter 2]
	set datatype [lindex $parameter 3]
	set min_n_values [lindex $parameter 4]
	set max_n_values [lindex $parameter 5]
	set default_value [lindex $parameter 6]
	if {[db_0or1row parameter_id_get {
	    select parameter_id from apm_parameters
	    where parameter_name = :parameter_name
	    and package_key = :package_key
	}]} {
	    ns_log Debug "APM: Updating parameter, $parameter_name:$parameter_id"
	    apm_parameter_update $parameter_id $package_key $parameter_name $description \
		    $default_value $datatype $section_name $min_n_values $max_n_values
	} else {
	    ns_log Debug "APM: Registering parameter, $parameter_name."
	    apm_parameter_register $parameter_name $description $package_key $default_value \
		    $datatype $section_name $min_n_values $max_n_values
	}	
    }
    ns_log Debug "APM: Removing parameters."
    # Find parameters that are not in the current version and remove them.    
    db_foreach all_parameters_for_package_key {
	select parameter_id, parameter_name
	from apm_parameters
	where package_key =:package_key
    } {
	ns_log Debug "APM Checking parameter $parameter_name..."
	if {[lsearch -exact $current_parameter_names $parameter_name] == -1} { 
	    apm_parameter_unregister $parameter_id
	}
    }
    ns_log Debug "APM: Parameter Upgrade Complete."
}

ad_proc -private apm_package_install_parameters { {-callback apm_dummy_callback} parameters package_key } {

    Installs a set of parameters into the package denoted by package_key.

} {
    foreach parameter $parameters {
	set parameter_name [lindex $parameter 0]
	set description [lindex $parameter 1]
	set section_name [lindex $parameter 2]
	set datatype [lindex $parameter 3]
	set min_n_values [lindex $parameter 4]
	set max_n_values [lindex $parameter 5]
	set default_value [lindex $parameter 6]
	apm_parameter_register $parameter_name $description $package_key $default_value $datatype \
	    $section_name $min_n_values $max_n_values
    }
}

ad_proc -private apm_package_install_dependencies { {-callback apm_dummy_callback} provides requires version_id} {

    Install all package dependencies.

} {
    ns_log Debug "APM: Installing dependencies."
    # Delete any dependencies register for this version.
    db_foreach all_dependencies_for_version {
	select dependency_id from apm_package_dependencies
	where version_id = :version_id
    } {
	apm_dependency_remove $dependency_id
    }



    foreach item $provides {
	set interface_uri [lindex $item 0]
	set interface_version [lindex $item 1]
	ns_log Debug "Registering dependency $interface_uri, $interface_version for $version_id"
	apm_interface_add $version_id $interface_uri $interface_version
    }

    foreach item $requires {
	set dependency_uri [lindex $item 0]
	set dependency_version [lindex $item 1]
	ns_log Debug "Registering dependency $dependency_uri, $dependency_version for $version_id"
	apm_dependency_add $version_id $dependency_uri $dependency_version
    }
}

ad_proc -private apm_package_install_owners_prepare {owner_names owner_uris } {

    Prepare the owners data structure for installation.

} {
    set owners [list]
    for {set i 0} {$i < [llength $owner_names] } {incr i} {
	if { ![empty_string_p [lindex $owner_names $i]] } {
	    lappend owners [list [lindex $owner_names $i] [lindex $owner_uris $i]]
	}
    }
    return $owners
}

ad_proc -private apm_package_install_owners { {-callback apm_dummy_callback} owners version_id} {
    
    Install all of the owners of the package version.
    
} {
    db_dml apm_delete_owners {
	delete from apm_package_owners where version_id = :version_id
    }
    set counter 0
    foreach item $owners {
	set owner_name [lindex $item 0]
	set owner_uri [lindex $item 1]
	db_dml owner_insert {
	    insert into apm_package_owners(version_id, owner_uri, owner_name, sort_key)
	    values(:version_id, :owner_uri, :owner_name, :counter)
	}
	incr counter
    }
}

ad_proc -private apm_package_install_files { {-callback apm_dummy_callback} files version_id } {

    Install all files related to the package.

} {
    db_dml files_delete {
	delete from apm_package_files where version_id = :version_id
    }
    
    db_transaction {
        foreach item $files {
	
	    set path [lindex $item 0]
	    set file_type [lindex $item 1]
            set db_type [lindex $item 2]
	    apm_file_add $version_id $path $file_type $db_type
        }
    }
}

ad_proc -private apm_package_install_queries {
    {-callback apm_dummy_callback}
    package_key
    files
} {
    Given a spec file, reads in the data model files to load from it.

    @param package_key The package key from the .info file.
    @param files List of files for this package from the package's .info file
    @author Don Baccus (dhogaza@pacifier.com)

    This replaces the brute-force version originally provided by
    Ben, which manually searched the package directories rather than
    use the package information file.

} {
    set path "[acs_package_root_dir $package_key]"


    ns_log Notice "APM/QD = loading up package query files for $package_key"
    set ul_p 0

    foreach query_file [apm_query_files_find $package_key $files] {
	ns_log Debug "APM/QD: Now processing query file $query_file"
        if { !$ul_p } {
            apm_callback_and_log $callback "<ul>\n"
            set ul_p 1
        }
        apm_callback_and_log $callback "<li>Loading query file $path/$query_file..."
	db_qd_load_query_file $path/$query_file
    }
    if { $ul_p } {
        apm_callback_and_log $callback "</ul>\n"
    }
}

ad_proc -private apm_package_install_spec { version_id } {

    Writes the XML-formatted specification for a package to disk,
    marking it in the database as the only installed version of the package.
    Creates the package directory if it doesn't already exist. Overwrites
    any existing specification file; or if none exists yet, creates
    $package_key/$package_key.info and adds this new file to apm_version_files
    in the database.

} {
    set spec [apm_generate_package_spec $version_id]
    apm_version_info $version_id
    db_1row package_version_info_select {
	select package_key, version_id
	from apm_package_version_info 
	where version_id = :version_id
    }

    ns_log Debug "APM: Checking existence of package directory."
    set root [acs_package_root_dir $package_key]
    if { ![file exists $root] } {
	file mkdir $root
# doesn't work under windows.  its not very useful anyway.
#	file attributes $root -permissions [ad_parameter "InfoFilePermissionsMode" "apm" 0755]
    }

    db_transaction {
	ns_log Debug "APM: Determining path of .info file."
	set info_file_name "$package_key.info"
	# Make sure we have a .info file set up in the data model.
	if { [db_0or1row package_spec_path_select {
            select path
            from apm_package_files
            where version_id = :version_id
            and file_type = 'package_spec'
	    and path = :info_file_name
        }] } {
	    # The .info file was already there. The path to is is now in $path.
	} else {
	    # Nothing there! We need to add a .info file.
	    set path "$package_key.info"
	    apm_file_add $version_id $path package_spec ""
	}
	ns_log Debug "APM: Writing APM .info file to the database."
	db_dml apm_spec_file_register {
	    update apm_package_types
		set spec_file_path = :path
	        where package_key = :package_key
	}
	ns_log Debug "APM: Writing .info file."
	set path "$root/$package_key.info"
	set file [open $path "w"]
	puts -nonewline $file $spec
	close $file

	# Mark $version_id as the only installed version of the package.
	db_dml version_mark_installed {
            update apm_package_versions
            set    installed_p = decode(version_id, :version_id, 't', 'f')
            where  package_key = :package_key
        }
    }
    ns_log Debug "APM: Done updating .info file."
}



proc_doc -public apm_version_enable { {-callback apm_dummy_callback} version_id } {

    Enables a version of a package (disabling any other version of the package).
    @param version_id The id of the version to be enabled.
} {
    db_exec_plsql apm_package_version_enable {
	begin
	  apm_package_version.enable(
            version_id => :version_id
	  );
	end;
    }
    apm_callback_and_log $callback  "<p>Package enabled."
}

proc_doc -public apm_version_disable { {-callback apm_dummy_callback} version_id } {

    Disables a version of a package.

    @param version_id The id of the version to be disabled.
} {
    db_exec_plsql apm_package_version_disable {
	begin
	  apm_package_version.disable(
            version_id => :version_id
	  );
	end;
    }
    apm_callback_and_log $callback  "<p>Package disabled."
}


ad_proc -public apm_package_register {
    package_key pretty_name pretty_plural package_uri package_type initial_install_p singleton_p {spec_file_path ""} {spec_file_mtime ""}
} {
    Register the package in the system.
} {

    if { [empty_string_p $spec_file_path] } {
	set spec_file_path [db_null]
    } 

    if { [empty_string_p $spec_file_mtime] } {
	set spec_file_mtime [db_null]
    }

    if { ![string compare $package_type "apm_application"] } {
	db_exec_plsql application_register {
	    begin
	    apm.register_application (
		        package_key => :package_key,
			package_uri => :package_uri,
			pretty_name => :pretty_name,
			pretty_plural => :pretty_plural,
			initial_install_p => :initial_install_p,
			singleton_p => :singleton_p,
			spec_file_path => :spec_file_path,
			spec_file_mtime => :spec_file_mtime
          		);
	    end;					  
	}
    } elseif { ![string compare $package_type "apm_service"] } {
	db_exec_plsql service_register {
	    begin
	    apm.register_service (
			package_key => :package_key,
			package_uri => :package_uri,
			pretty_name => :pretty_name,
			pretty_plural => :pretty_plural,
			initial_install_p => :initial_install_p,
			singleton_p => :singleton_p,
			spec_file_path => :spec_file_path,
			spec_file_mtime => :spec_file_mtime
			);
	    end;					  
	}
    } else {
	error "Unrecognized package type: $package_type"
    }
}

ad_proc -public apm_version_update {
    {
	-callback apm_dummy_callback
    }
    version_id version_name version_uri summary description description_format vendor vendor_uri {release_date ""} 
} {

    Update a version in the system to new information.
} {
    if { [empty_string_p $release_date] } {
 	set release_date [db_null]
    }
    return [db_exec_plsql apm_version_update {
	begin
	:1 := apm_package_version.edit(
				 version_id => :version_id, 
				 version_name => :version_name, 
				 version_uri => :version_uri,
				 summary => :summary,
				 description_format => :description_format,
				 description => :description,
				 release_date => :release_date,
				 vendor => :vendor,
				 vendor_uri => :vendor_uri,
				 installed_p => 't',
				 data_model_loaded_p => 't'				 
				 );
	end;
    }]
}


ad_proc -private apm_packages_full_install {
    {
	-callback apm_dummy_callback
    } pkg_info_list 
} {

    Loads the data model, installs, enables, instantiates, and mounts all of the packages in pkg_list.
    Each package is mounted at /package-key.

} {

    foreach pkg_info $pkg_info_list {
	if { [catch {
	    set spec_file [pkg_info_spec $pkg_info]
	    set package_key [pkg_info_key $pkg_info]
	    apm_package_install_data_model -callback $callback $spec_file
	    set version_id [apm_version_enable -callback $callback \
				[apm_package_install -callback $callback $spec_file]]
	} errmsg] } {
	    apm_callback_and_log $callback "<p><font color=red>[string totitle $package_key] not installed.</font>
<p> Error:
<pre><blockquote>[ad_quotehtml $errmsg]</blockquote></pre>"
	} 
    }
}

ad_proc -private apm_package_instantiate_and_mount {
    {
	-callback apm_dummy_callback
    } package_key} {

    Automatically instantiate and mount a package of the indicated type.

} {
# Instantiate and mount the package.
    if { [catch { 
	db_exec_plsql package_instantiate_and_mount {
	    declare
	            main_site_id  site_nodes.node_id%TYPE;
  	            instance_id   apm_packages.package_id%TYPE;
	            node_id       site_nodes.node_id%TYPE;
	    begin
	            main_site_id := site_node.node_id('/');
	        
	            instance_id := apm_package.new(
			  	  package_key => :package_key,
				  context_id => main_site_id
				  );

		    node_id := site_node.new(
			     parent_id => main_site_id,
			     name => :package_key,
			     directory_p => 't',
			     pattern_p => 't',
			     object_id => instance_id
			  );
	    end;
	    }
    } errmsg]} {
	apm_callback_and_log $callback "[string totitle $package_key] not mounted.<p> Error:
<pre><blockquote>[ad_quotehtml $errmsg]</blockquote></pre>"
    } else {
	apm_callback_and_log $callback "[string totitle $package_key] mounted at /$package_key/.<p>"
    }
}

ad_proc -private apm_package_upgrade_p {package_key version_name} {

    @return 1 if a version of the indicated package_key of version lower than version_name \
	    is already installed in the system, 0 otherwise.

} {
    return [db_string apm_package_upgrade_p {
	select apm_package_version.version_name_greater(:version_name, version_name) upgrade_p
	from apm_package_versions
	where package_key = :package_key
	and version_id = apm_package.highest_version (:package_key)
    } -default 0]
}

ad_proc -private apm_version_upgrade {version_id} {

    Upgrade a package to a locally maintained later version.

} {
    db_exec_plsql apm_version_upgrade {
	begin
	    apm_package_version.upgrade(version_id => :version_id);
	end;

    }
} 

ad_proc -private apm_upgrade_for_version_p {path initial_version_name final_version_name} {

    @return 1 if the file indicated by path is valid .sql script to upgrade initial_version_name
    to final_version_name

} {
    ns_log Debug "upgrade_p $path, $initial_version_name $final_version_name"
    return [db_exec_plsql apm_upgrade_for_version_p {
	begin
	    :1 := apm_package_version.upgrade_p(
	              path => :path,
	              initial_version_name => :initial_version_name,
	              final_version_name => :final_version_name
	          );
	end;
    }]
}

ad_proc -private apm_order_upgrade_scripts {upgrade_script_names} {
    
    Upgrade scripts are ordered so that they may be executed in a sequence
    that upgrades package.  For example, if you start at version 1.0, and need to go
    to version 2.0, a correct order would be 1.0-1.5, 1.5-1.6, 1.6-2.0.
    @return an ordered list of upgrade script names.

} {
    return [lsort -increasing -command apm_upgrade_script_compare $upgrade_script_names]
}

ad_proc -private apm_upgrade_script_compare {f1 f2} {

    @return 1 if f1 comes after f2, 0 if they are the same, -1 if f1 comes before f2.

} {
    # Strip off any path information.
    set f1 [lindex [split $f1 /] end]
    set f2 [lindex [split $f2 /] end]
    
    # Get the version number from, e.g. the 2.0 from upgrade-2.0-3.0.sql 
    if {[regexp {\-(.*)-.*.sql} $f1 match f1_version_from] && 
    [regexp {\-(.*)-.*.sql} $f2 match f2_version_from]} {
	# At this point we should have something like 2.0 and 3.1d which Tcl string
	# comparison can handle. 
	set f1_version_from [db_exec_plsql test_f1 {}]
	set f2_version_from [db_exec_plsql test_f2 {}]
	return [string compare $f1_version_from $f2_version_from]
    } else {
	error "Invalid upgrade script syntax.  Should be \"upgrade-major.minor-major.minor.sql\"."
    }
}

ad_proc -private apm_data_model_scripts_find {
    {-upgrade_from_version_name ""}
    {-upgrade_to_version_name ""}
    package_key file_list
} {
    @param version_id What version the files belong to.
    @param upgrade Set this switch if you want the scripts for upgrading.
    @file_list A list of files and file types of form [list [list "foo.sql" "data_model_upgrade"] ...] 
} {
    set types_to_retrieve [list "sqlj_code"]
    if {[empty_string_p $upgrade_from_version_name]} {
	lappend types_to_retrieve "data_model_create"
    } else {
	lappend types_to_retrieve "data_model_upgrade"
    }
    set data_model_list [list]
    set upgrade_file_list [list]
    foreach file $file_list {
	set path [lindex $file 0]
	set file_type [lindex $file 1]
        set file_db_type [lindex $file 2]
	apm_log APMDebug "APM: Checking \"$path\" of type \"$file_type\" and db_type \"$file_db_type\"."

        # DRB: we return datamodel files which match the given database type or for which no db_type
        # is defined.  The latter case is a kludge to simplify support of legacy ACS Oracle-only
        # modules which haven't had their datamodel files moved to sql/oracle.  Eventually we should
        # remove the kludge and insist that datamodel files live in the proper directory.

	if {[lsearch -exact $types_to_retrieve $file_type] != -1 && \
            ([db_compatible_rdbms_p $file_db_type])} {
	    if { ![string compare $file_type "data_model_upgrade"] } {
		if {[apm_upgrade_for_version_p $path $upgrade_from_version_name \
			$upgrade_to_version_name]} {
		    # Its a valid upgrade script.
		    ns_log Debug "APM: Adding $path to the list of upgrade files."
		    lappend upgrade_file_list [list $path $file_type $package_key]
		}
	    } else {
		apm_log APMDebug "APM: Adding $path to the list of data model files."
		lappend data_model_list [list $path $file_type $package_key ]
	    }
	}
    }
    set file_list [concat [apm_order_upgrade_scripts $upgrade_file_list] $data_model_list]
    apm_log APMDebug "APM: Data model scripts for $package_key: $file_list"
    return $file_list
}

ad_proc -private apm_query_files_find {
    package_key
    file_list
} {
    @file_list A list of files and file types of form [list [list "foo.sql" "data_model_upgrade"] ...] 
} {

    set query_file_list [list]

    foreach file $file_list {
	set path [lindex $file 0]
	set file_type [lindex $file 1]
        set file_db_type [lindex $file 2]
	ns_log Debug "APM/QD: Checking \"$path\" of type \"$file_type\" and db_type \"$file_db_type\"."

        # DRB: we return query files which match the given database type or for which no db_type
        # is defined, which we interpret to mean a file containing queries that work with all of our
        # supported databases.

	if {[lsearch -exact "query_file" $file_type] != -1 && \
            ([empty_string_p $file_db_type] || ![string compare [db_type] $file_db_type])} {
            ns_log Debug "APM: Adding $path to the list of query files."
            lappend query_file_list $path
	}
    }
    ns_log Notice "APM: Query files for $package_key: $query_file_list"
    return $query_file_list
}
