ad_library {

    Routines used by the package manager.

    @creation-date 13 Apr 2000
    @author Bryan Quinn (bquinn@arsdigita.com)
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id $Id$
}

#####
# Globals used by the package manager:
#
#     apm_current_package_key
#         Identifies which package is currently being loaded.
#
#
#
# NSV arrays used by the package_manager: (note that all paths are relative
# to [acs_path_root] unless otherwise indicated)
#
#     apm_version_properties($info_file_path)
#
#         Contains a list [list $mtime $properties_array], where $properties_array
#         is a cached copy of the version properties array last returned by
#         [apm_read_package_info_file $info_file_path], and $mtime is the
#         modification time of the $info_file_path when it was last examined.
#
#         This is a cache for apm_read_package_info_file.
#
#     apm_library_mtime($path)
#
#         The modification time of $file (a *-procs.tcl, *-init.tcl or .xql file)
#         when it was last loaded.
#
#     apm_version_procs_loaded_p($version_id)
#     apm_version_init_loaded_p($version_id)
#
#         1 if the *-procs.tcl and *-init.tcl files (respectively) have been
#         loaded for package version $version_id.
#
#     apm_vc_status($path)
#
#         A cached result from apm_fetch_cached_vc_status (of the form
#         [list $mtime $path]) containing the last-known CVS status of
#         $path.
#
#     apm_properties(reload_level)
#
#         The current "reload level" for the server.
#
#     apm_reload($reload_level)
#
#         A list of files which need to be loaded to bring the current interpreter
#         up to reload level $reload_level from level $reload_level - 1.
#
#     apm_reload_watch($path)
#
#         Indicates that $path is a -procs.tcl file which should be examined
#         every time apm_reload_any_changed_libraries is invoked, to see whether
#         it has changed since last loaded. The path starts at acs_root_dir.
#
# RELOADING VOODOO
#
#     To allow for automatically reloading of Tcl libraries, we introduce the
#     concept of a server-wide "reload level" (starting at zero) stored in
#     the apm_properties(reload_level) NSV array entry. Whenever we determine
#     we want to have all interpreters source a particular -procs.tcl file,
#     we:
#
#         1) Increment apm_properties(reload_level), as a signal to each
#            interpreter that it needs to source some new -procs.tcl files
#            to bring itself up to date.
#         2) Set apm_reload($reload_level), where $reload_level is the new
#            value of apm_properties(reload_level) set in step #1, to the
#            list of files which actually need to be sourced.
#
#     Each interpreter maintains its private, interpreter-specific reload level
#     as a proc named apm_reload_level_in_this_interpreter. Every time the
#     request processor sees a request, it invokes
#     apm_reload_any_changed_libraries, which compares the server-wide
#     reload level to the interpreter-private one. If it notes a difference,
#     it reloads the set of files necessary to bring itself up-to-date (i.e.,
#     files noted in the applicable entries of apm_reload).
#
#     Example:
#
#         - The server is started. apm_properties(reload_level) is 0.
#         - I modify /packages/acs-tcl/utilities-procs.tcl.
#         - Through the package manager GUI, I invoke
#           apm_mark_version_for_reload. It notices that utilities-procs.tcl
#           has changed. It increments apm_properties(reload_level) to 1,
#           and sets apm_reload(1) to [list "packages/acs-tcl/utilities-procs.tcl"].
#         - A request is handled in some other interpreter, whose reload
#           level (as returned by apm_reload_level_in_this_interpreter)
#           is 0. apm_reload_any_changed_libraries notes that
#           [apm_reload_level_in_this_interpreter] != [nsv_get apm_properties reload_level],
#           so it sources the files listed in apm_reload(1) (i.e., utilities-procs.tcl)
#           and redefines apm_reload_level_in_this_interpreter to return 1.
#
#####


### Callback functions are used to control the logging that occurs during
### the execution of any apm_package that uses the -callback argument.

ad_proc -public apm_dummy_callback { string } {

    A dummy callback routine which does nothing.

} {
    # Do nothing!
}

ad_proc -public apm_ns_write_callback { string } {
 
    A simple callback which prints out the log message to the server stream.
   
} {
    ns_write $string
}

ad_proc -public apm_doc_body_callback { string } {
    This callback uses the document api to append more text to the stream.
} {
    doc_body_append $string
}

ad_proc apm_callback_and_log { { -severity Debug } callback message } {

    Executes the $callback callback routine with $message as an argument,
    and calls ns_log with the given $severity.

} {
    $callback $message
    ns_log $severity $message
}   


ad_proc -public apm_version_loaded_p { version_id } {

    Returns 1 if a version of a package has been loaded and initialized, or 0 otherwise.

} {
    return [nsv_exists apm_version_init_loaded_p $version_id]
}

ad_proc -private apm_mark_version_for_reload { version_id { file_info_var "" } } {

    Examines all tcl_procs files in package version $version_id; if any have
    changed since they were loaded, marks (in the apm_reload array) that
    they must be reloaded by each Tcl interpreter (using the
    apm_reload_any_changed_libraries procedure).
    
    <p>Saves a list of files that have changed (and thus marked to be reloaded) in
    the variable named <code>$file_info_var</code>, if provided. Each element
    of this list is of the form:

    <blockquote><pre>[list $file_id $path]</pre></blockquote>

} {
    if { ![empty_string_p $file_info_var] } {
	upvar $file_info_var file_info
    }

    db_1row package_key_select "select package_key from apm_package_version_info where version_id = :version_id"

    set changed_files [list]
    set file_info [list]

    db_foreach file_info {
        select file_id, path
        from   apm_package_files
        where  version_id = :version_id
        and    file_type in ('tcl_procs', 'query_file')
        and    (db_type is null or db_type = '[db_type]')
        order by path
    } {
	set full_path "[acs_package_root_dir $package_key]/$path"
	set relative_path "packages/$package_key/$path"

	# If the file exists, and either has never been loaded or has an mtime
	# which differs the mtime it had when last loaded, mark to be loaded.
	if { [file isfile $full_path] } {
	    set mtime [file mtime $full_path]

	    if { ![nsv_exists apm_library_mtime $relative_path] || \
		    [nsv_get apm_library_mtime $relative_path] != $mtime } {
		lappend changed_files $relative_path
		lappend file_info [list $file_id $path $relative_path]
		nsv_set apm_library_mtime $relative_path $mtime
	    }
	}
    }

    if { [llength $changed_files] > 0 } {
	set reload [nsv_incr apm_properties reload_level]
	nsv_set apm_reload $reload $changed_files
    }
}

ad_proc -private apm_version_load_status { version_id } {

    If a version needs to be reloaded (i.e., a <code>-procs.tcl</code> has changed
    or been added since the version was loaded), returns "needs_reload".
    If the version has never been loaded, returns "never_loaded". If the
    version is up-to-date, returns "up_to_date".
    
} {
    # See if the version was ever loaded.
    if { ![apm_package_version_enabled_p $version_id] } {
	return "never_loaded"
    }

    db_1row package_key_select {
        select package_key
        from apm_package_version_info
        where version_id = :version_id
    }

    foreach file [apm_version_file_list -type "tcl_procs" -db_type [db_type] $version_id] {
	# If $file has never been loaded, i.e., it has been added to the version
	# since the version was initially loaded, return needs_reload.
	if { ![nsv_exists apm_library_mtime "packages/$package_key/$file"] } {
	    return "needs_reload"
	}

	set full_path "[acs_package_root_dir $package_key]/$file"
	# If $file had a different mtime when it was last loaded, return
	# needs_reload. (If the file should exist but doesn't, just skip it.)
	if { [file exists $full_path] && 
	[file mtime $full_path] != [nsv_get apm_library_mtime "packages/$package_key/$file"] } {
	    return "needs_reload"
	}
    }

    foreach file [apm_version_file_list -type "query_file" -db_type [db_type] $version_id] {
	# If $file has never been loaded, i.e., it has been added to the version
	# since the version was initially loaded, return needs_reload.
	if { ![nsv_exists apm_library_mtime "packages/$package_key/$file"] } {
	    return "needs_reload"
	}

	set full_path "[acs_package_root_dir $package_key]/$file"
	# If $file had a different mtime when it was last loaded, return
	# needs_reload. (If the file should exist but doesn't, just skip it.)
	if { [file exists $full_path] && 
	[file mtime $full_path] != [nsv_get apm_library_mtime "packages/$package_key/$file"] } {
	    return "needs_reload"
	}
    }

    return "up_to_date"
}

ad_proc -private apm_load_libraries { 
    {-callback apm_dummy_callback}
    {-procs:boolean} 
    {-init:boolean}
} {

    Loads all -procs.tcl (if $procs_or_init is "procs") or -init.tcl (if $procs_or_init is
    "init") files into the current interpreter for installed, enabled packages. Only loads
    files which have not yet been loaded. This is intended to be called only during server
    initialization (since it loads libraries only into the running interpreter, as opposed
    to in *all* active interpreters).

} {
    
    # DRB: query extractor's dumb about repeated query
    # names so I changed these to be unique.  We should
    # really be sharing these at some level rather than
    # duping them anyway.
    set packages [db_list apm_enabled_packages_l {
	select distinct package_key
	from apm_package_versions
	where enabled_p='t'
    }]

    # Scan the package directory for files to source.    
    set files [list]    
    foreach package $packages {

	set base "[acs_root_dir]/packages/$package/"
	set base_len [string length $base]
	set dirs [list \
		$base \
		${base}tcl ]
	set paths [list]
      
	foreach dir $dirs {
	    if {$procs_p} {
		set paths [concat $paths [glob -nocomplain "$dir/*procs.tcl"]]
                set paths [concat $paths [glob -nocomplain "$dir/*procs-[db_type].tcl"]]
	    } 
	    if {$init_p} {
		set paths [concat $paths [glob -nocomplain "$dir/*init.tcl"]]
                set paths [concat $paths [glob -nocomplain "$dir/*init-[db_type].tcl"]]
	    }    
	}
	
	foreach path [lsort $paths] {
	    set rel_path [string range $path $base_len end]
	    lappend files [list $package $rel_path]
	}
    }
      
    # Release all outstanding database handles (since the file we're sourcing
    # might be using the ns_db database API as opposed to the new db_* API).
    db_release_unused_handles
    apm_files_load -callback $callback $files
}

# OpenACS query loading (ben@mit.edu)
# Load up the queries for all packages
#
# This follows the pattern of the load_libraries proc,
# but is only loading query information
ad_proc -private apm_load_queries {
    {-callback apm_dummy_callback}
} {
    set packages [db_list apm_enabled_packages_q {
	select distinct package_key
	from apm_package_versions
	where enabled_p='t'
    }]

    # Scan the package directory for files to source.    
    set files [list]    
    foreach package $packages {

        set files [ad_find_all_files [acs_root_dir]/packages/$package]
        if { [llength $files] == 0 } {
    	    error "Unable to locate [acs_root_dir]/packages/$package/*."
        }

        foreach file [lsort $files] {

            set file_db_type [apm_guess_db_type $package $file]
            set file_type [apm_guess_file_type $package $file]

            if {[string equal $file_type query_file] &&
                ([empty_string_p $file_db_type] || [string equal $file_db_type [db_type]])} {
	        db_qd_load_query_file $file
            } 
        }
    }
    ns_log Notice "APM/QD = DONE looping through files to load queries from"
}

ad_proc -private apm_subdirs { path } {

    Returns a list of subdirectories of path (including path itself)

} {
    set dirs [list]
    lappend dirs $path
    foreach subdir [glob -nocomplain -type d [file join $path *]] {
       set dirs [concat $dirs [apm_subdirs $subdir]]
    }
    return $dirs
}

ad_proc -private apm_pretty_name_for_file_type { type } {

    Returns the pretty name corresponding to a particular file type key
    (memoizing to save a database hit here and there).

} {
    return [util_memoize [list db_string pretty_name_select "
        select pretty_name
        from apm_package_file_types
        where file_type_key = :type
    " -default "Unknown" -bind [list type $type]]]
}

ad_proc -private apm_pretty_name_for_db_type { db_type } {

    Returns the pretty name corresponding to a particular file type key
    (memoizing to save a database hit here and there).

} {
    return [util_memoize [list db_string pretty_db_name_select "
        select pretty_db_name
        from apm_package_db_types
        where db_type_key = :db_type
    " -default "all" -bind [list db_type $db_type]]]
}

ad_proc -public apm_load_any_changed_libraries {} {
    
    In the running interpreter, reloads files marked for reload by
    apm_mark_version_for_reload. If any watches are set, examines watched
    files to see whether they need to be reloaded as well. This is intended
    to be called only by the request processor (since it should be invoked
    before any filters or registered procedures are applied).

} {
    # Determine the current reload level in this interpreter by calling
    # apm_reload_level_in_this_interpreter. If this fails, we define the reload level to be
    # zero.
    if { [catch { set reload_level [apm_reload_level_in_this_interpreter] } error] } {
	proc apm_reload_level_in_this_interpreter {} { return 0 }
	set reload_level 0
    }

    # Check watched files, adding them to files_to_reload if they have
    # changed.
    set files_to_reload [list]
    foreach file [nsv_array names apm_reload_watch] {
	set path "[acs_root_dir]/$file"
	ns_log Debug "APM: File being watched: $path"

	if { [file exists $path] && \
		(![nsv_exists apm_library_mtime $file] || \
		[file mtime $path] != [nsv_get apm_library_mtime $file]) } {
	    lappend files_to_reload $file
	}
    }

    # If there are any changed watched files, stick another entry on the
    # reload queue.
    if { [llength $files_to_reload] > 0 } {
	ns_log "Notice" "Watched file[ad_decode [llength $files_to_reload] 1 "" "s"] [join $files_to_reload ", "] [ad_decode [llength $files_to_reload] 1 "has" "have"] changed: reloading."
	set new_level [nsv_incr apm_properties reload_level]
	nsv_set apm_reload $new_level $files_to_reload
    }

    set changed_reload_level_p 0

    # Keep track of which files we've reloaded in this loop so we never
    # reload the same one twice.
    array set reloaded_files [list]
    while { $reload_level < [nsv_get apm_properties reload_level] } {
	incr reload_level
	set changed_reload_level_p 1
	# If there's no entry in apm_reload for that reload level, back out.
	if { ![nsv_exists apm_reload $reload_level] } {
	    incr reload_level -1
	    break
	}
	foreach file [nsv_get apm_reload $reload_level] {
	    # If we haven't yet reloaded the file in this loop, source it.
	    if { ![info exists reloaded_files($file)] } {
		if { [array size reloaded_files] == 0 } {
		    # Perform this ns_log only during the first iteration of this loop.
		    ns_log "Notice" "APM: Reloading *-procs.tcl files in this interpreter..."
		}
		ns_log "Notice" "APM: Reloading $file..."
		# File is usually of form packages/package_key
		set file_path "[acs_root_dir]/$file"
                switch [apm_guess_file_type "" $file] {
                    tcl_procs { apm_source [acs_root_dir]/$file }
                    query_file { db_qd_load_query_file [acs_root_dir]/$file }
                }

		nsv_set apm_library_mtime $file [file mtime $file_path]
		set reloaded_files($file) 1
	    }
	}
    }

    # We changed the reload level in this interpreter, so redefine the
    # apm_reload_level_in_this_interpreter proc.
    if { $changed_reload_level_p } {
	proc apm_reload_level_in_this_interpreter {} "return $reload_level"
    }

}

ad_proc -private apm_package_version_release_tag { package_key version_name } {

    Returns a CVS release tag for a particular package key and version name.

2} {
    regsub -all {\.} [string toupper "$package_key-$version_name"] "-" release_tag
    return $release_tag
}

ad_proc -public apm_package_parameters {package_key} {
    @return A list of all the package parameter names.
} {
    return [db_list get_names {
	select parameter_name from apm_parameters
	where package_key = :package_key
    }]
}

ad_proc -public apm_package_registered_p {
    package_key
} {
    Returns 1 if there is a registered package with the indicated package_key.  
    Returns 0 otherwise.
} {
    ### Query the database for the indicated package_key
    return [db_string apm_package_registered_p {
	select 1 from apm_package_types 
	where package_key = :package_key
    } -default 0]
}

ad_proc -public apm_package_installed_p {
    package_key
} {
    Returns 1 if there is an installed package version corresponding to the package_key,
    0 otherwise
} {
    return [db_string apm_package_installed_p {
	select 1 from apm_package_versions
	where package_key = :package_key
	and installed_p = 't'
    } -default 0]
}

ad_proc -public apm_version_installed_p {
    version_id
} {
    @return Returns 1 if the specified version_id is installed, 0 otherwise.
} {
    return [db_string apm_version_installed_p {
	select 1 from apm_package_versions
	where version_id = :version_id
	and installed_p = 't'
    } -default 0]
}

ad_proc -public apm_highest_version {package_key} {
    Return the highest version of the indicated package.
    @return the version_id of the highest installed version of a package.
} {
    return [db_exec_plsql apm_highest_version {
	begin
	:1 := apm_package.highest_version (
                    package_key => :package_key
		    );
	end;
    }]
}

ad_proc -public apm_num_instances {package_key} {

    @return The number of instances of the indicated package.
} {
    return [db_exec_plsql apm_num_instances {
	begin
	:1 := apm_package.num_instances(
		package_key => :package_key
		);
	end;
    }]

}

ad_proc -public apm_parameter_update {
    {
	-callback apm_dummy_callback
    }
    parameter_id package_key parameter_name description default_value datatype \
	{section_name ""} {min_n_values 1} {max_n_values 1} 
} {
    @return The parameter id that has been updated.
} {
    if {[empty_string_p $section_name]} {
	set section_name [db_null]
    }

    db_dml parameter_update {
       update apm_parameters 
	set parameter_name = :parameter_name,
            default_value  = :default_value,
            datatype       = :datatype, 
	    description	   = :description,
	    section_name   = :section_name,
            min_n_values   = :min_n_values,
            max_n_values   = :max_n_values
      where parameter_id = :parameter_id
    }
    
    return $parameter_id
}

ad_proc -public apm_parameter_register { 
    {
	-callback apm_dummy_callback
	-parameter_id ""
    } 
    parameter_name description package_key default_value datatype {section_name ""} {min_n_values 1} {max_n_values 1}
} {
    Register a parameter in the system.
    @return The parameter id of the new parameter.

} {
    if {[empty_string_p $parameter_id]} {
	set parameter_id [db_null]
    }

    if {[empty_string_p $section_name]} {
	set section_name [db_null]
    }

    ns_log Notice "Registering $parameter_name, $section_name, $default_value"

    set parameter_id [db_exec_plsql parameter_register {
	    begin
	    :1 := apm.register_parameter(
					 parameter_id => :parameter_id,
					 parameter_name => :parameter_name,
					 package_key => :package_key,
					 description => :description,
					 datatype => :datatype,
					 default_value => :default_value,
					 section_name => :section_name,
					 min_n_values => :min_n_values,
					 max_n_values => :max_n_values
	                                );
	    end;
	}]

    # Update the cache.
    db_foreach apm_parameter_cache_update {
	select v.package_id, p.parameter_name, nvl(p.default_value, v.attr_value) as attr_value
	from apm_parameters p, apm_parameter_values v
	where p.package_key = :package_key
	and p.parameter_id = v.parameter_id (+)
    } {
	ad_parameter_cache -set $attr_value $package_id $parameter_name
    }
    return $parameter_id
}

ad_proc -public apm_parameter_unregister { 
    {
	-callback apm_dummy_callback
    } 
    parameter_id
} {
    Unregisters a parameter from the system.
} {
    ns_log Debug "APM Unregistering parameter $parameter_id."
    db_foreach all_parameters_packages {
	select package_id, parameter_id, parameter_name 
	from apm_packages p, apm_parameters ap
	where p.package_key = ap.package_key
	and ap.parameter_id = :parameter_id

    } {
	ad_parameter_cache -delete $package_id $parameter_name
    } if_no_rows {
	return
    }
	
    db_exec_plsql parameter_unregister {
	begin
	delete from apm_parameter_values 
	where parameter_id = :parameter_id;
	delete from apm_parameters 
	where parameter_id = :parameter_id;
	acs_object.delete(:parameter_id);
	end;
    }   
}

ad_proc -public apm_dependency_add {
    {
	-callback apm_dummy_callback
	-dependency_id ""
    } version_id dependency_uri dependency_version
} {
    
    Add a dependency to a version.
    @return The id of the new dependency.
} {

    if {[empty_string_p $dependency_id]} {
	set dependency_id [db_null]
    }
    
    return [db_exec_plsql dependency_add {
	begin
	:1 := apm_package_version.add_dependency(
            dependency_id => :dependency_id,
	    version_id => :version_id,
	    dependency_uri => :dependency_uri,
	    dependency_version => :dependency_version
        );					 
	end;
    }]
}

ad_proc -public apm_dependency_remove {dependency_id} {
    
    Removes a dependency from the system.

} {
    db_exec_plsql dependency_remove {
	begin
	apm_package_version.remove_dependency(
             dependency_id => :dependency_id
	);
	end;					        
    }
}

ad_proc -public apm_interface_add {
    {
	-callback apm_dummy_callback
	-interface_id ""
    } version_id interface_uri interface_version
} {
    
    Add a interface to a version.
    @return The id of the new interface.
} {

    if {[empty_string_p $interface_id]} {
	set interface_id [db_null]
    }
    
    return [db_exec_plsql interface_add {
	begin
	:1 := apm_package_version.add_interface(
            interface_id => :interface_id,
	    version_id => :version_id,
	    interface_uri => :interface_uri,
	    interface_version => :interface_version
        );					 
	end;
    }]
}

ad_proc -public apm_interface_remove {interface_id} {
    
    Removes a interface from the system.

} {
    db_exec_plsql interface_remove {
	begin
	apm_package_version.remove_interface(
             interface_id => :interface_id
	);
	end;					        
    }
}

ad_proc -public apm_package_key_from_id {package_id} {
    @return The package key of the instance.
} {
    return [util_memoize "apm_package_key_from_id_mem $package_id"]
}

proc apm_package_key_from_id_mem {package_id} {
    return [db_string apm_package_key_from_id {
	select package_key from apm_packages where package_id = :package_id
    } -default ""]
}

ad_proc -public apm_package_id_from_key {package_key} {
    @return The package id of the instance of the package.
    0 if no instance exists, error if several instances exist.
} {
    return [util_memoize "apm_package_id_from_key_mem $package_key"]
}

proc apm_package_id_from_key_mem {package_key} {
    return [db_string apm_package_id_from_key {
	select package_id from apm_packages where package_key = :package_key
    } -default 0]
}

ad_proc -public apm_package_url_from_key {package_key} {
    @return The package url of the instance of the package.
    only valid for singleton packages.
} {
    return [util_memoize "apm_package_url_from_key_mem $package_key"]
}

ad_proc -public apm_package_url_from_key_mem {package_key} {
    set package_id [apm_package_id_from_key $package_key]
    return [db_string apm_package_url_from_key {
	select site_node.url(node_id) 
          from site_nodes 
         where object_id = :package_id
    } -default ""]
}

ad_proc -public apm_version_info {version_id} {

    Sets a set of common package information in the caller's environment.

} {

    uplevel 1 {
	db_1row apm_package_by_version_id {
	    select pretty_name, version_name, package_key, installed_p, distribution_uri, tagged_p
	    from apm_package_version_info where version_id = :version_id
	}
    } 
}

ad_proc -public apm_package_version_installed_p {package_key version_name} {

    @return 1 if the indiciated package version is installed, 0 otherwise.

} {
    return [db_string apm_package_version_installed_p {
	select decode(count(*), 0, 0, 1) from apm_package_versions
	where package_key = :package_key
	and version_name = :version_name
    } -default 0]
}

ad_proc -public apm_package_version_enabled_p {version_id} {

    @return 1 if the indiciated package version is installed, 0 otherwise.

} {
    return [db_string apm_package_version_installed_p {
	select decode(count(*), 0, 0, 1) from apm_package_versions
	where version_id = :version_id
	and enabled_p = 't'
    } -default 0]
}


ad_proc -private apm_post_instantiation_tcl_proc_from_key { package_key } {
    Generates the name of the TCL procedure we execute for
    post-instantiation. 

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 2001-03-05

    @return The name of a tcl procedure, if it exists, or empty string
    if no such tcl procedure was found.
} {
    set procedure_name [string tolower "[string trim $package_key]_post_instantiation"]
    # Change all "-" to "_" to mimic our tcl standards
    regsub -all {\-} $procedure_name "_" procedure_name
    if { [empty_string_p [info procs ::$procedure_name]] } {
	# No such procedure exists... 
	return ""
    }
    # Procedure exists
    return $procedure_name
}


ad_proc -public apm_package_create_instance {
    {
	-package_id 0
    }
    instance_name context_id package_key
} {

    Creates a new instance of a package.

} {
    if {$package_id == 0} {
	set package_id [db_null]
    } 

    set package_id [db_exec_plsql apm_package_instance_new {
	begin
      :1 := apm_package.new(
        package_id => :package_id,
        instance_name => :instance_name,
        package_key => :package_key,
        context_id => :context_id
      );
	end;
    }]
   
    apm_parameter_sync $package_key $package_id
    
    return $package_id
}


ad_proc -public apm_package_call_post_instantiation_proc {
    package_id
    package_key
} {

    Call the package-specific post instantiation proc, if any

} {

    # Check for a post-instantiation TCL procedure
    set procedure_name [apm_post_instantiation_tcl_proc_from_key $package_key]
    if { ![empty_string_p $procedure_name] } {
	with_catch errmsg {
	    $procedure_name $package_id
	} {
	    ns_log Error "APM: Post-instantiation procedure, $procedure_name, failed: $errmsg"
	}
    }
    
}

ad_proc -public apm_package_instance_new {
    {
	-package_id 0
    }
    instance_name context_id package_key
} {

    Creates a new instance of a package and call the post instantiation proc, if any.

    DRB: I split out the subpieces into two procs because the subsite post instantiation proc
    needs to be able to find the package's node in the site node map, which results in a 
    cart-before-the-horse scenario.  The code can't update the site node map until after the
    package is created yet the original code called the post instantiation proc before the
    site node code could update the table.

} {
    set package_id [apm_package_create_instance -package_id $package_id $instance_name $context_id $package_key]
    apm_package_call_post_instantiation_proc $package_id $package_key
}


ad_proc apm_parameter_sync {package_key package_id} {
    
    Syncs the parameters in the database with the memory cache.  This must be called
    after creating a new package instance.
    
} {

    # Get all the parameter names and values for this package_id.
    set names_and_values [db_list_of_lists apm_parameter_names_and_values {
	select parameter_name, attr_value
	from apm_parameters p, apm_parameter_values v, apm_packages a
	where p.parameter_id = v.parameter_id
	and a.package_id = v.package_id
	and a.package_id = :package_id
    }]
    
    # Put it in the cache.
    foreach name_value_pair $names_and_values {	
	ad_parameter_cache -set [lindex $name_value_pair 1] $package_id [lindex $name_value_pair 0]
    }
}
