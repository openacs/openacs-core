# /packages/acs-tcl/bootstrap.tcl
#
# Code to bootstrap ACS, invoked by /tcl/0-acs-init.tcl.
#
# @creation-date 12 May 2000
# @author Jon Salz [jsalz@arsdigita.com]
# @cvs-id $Id$


# Remember the length of the error log file (so we can easily seek back to this
# point later). This is used in /www/admin/monitoring/startup-log.tcl to show
# the segment of the error log corresponding to server initialization (between
# "AOLserver/xxx starting" and "AOLserver/xxx running").
catch { nsv_set acs_properties initial_error_log_length [file size [ns_info log]] }

# Initialize proc_doc NSV arrays.
nsv_set proc_source_file . ""

# Initialize loader NSV arrays. See apm-procs.tcl for a description of
# these arrays.
nsv_array set apm_library_mtime [list]
nsv_array set apm_version_procs_loaded_p [list]
nsv_array set apm_reload_watch [list]
nsv_array set apm_package_info [list]
nsv_set apm_properties reload_level 0

# Initialize ad_after_server_initialization.
nsv_set ad_after_server_initialization . ""


###
#
# Bootstrapping code.
#
###

# Define a helper routine we can use to source files in a clear environment
# (no locals). We need this since apm_source is not yet defined.
proc bootstrap_source { __file } {
    if { [catch { source $__file }] } {
	global errorInfo
	ns_log "Error" "Error sourcing core library $__file: $errorInfo"
    }
}

# A helper procedure called if a fatal error occurs.
proc bootstrap_fatal_error { message { throw_error_p 1 } } {
    # First of all, redefine the "rp_invoke_filter" and "rp_invoke_procs"
    # routines to do nothing, to circumvent the request processor.
    proc rp_invoke_filter { conn arg why } { return "filter_ok" }
    proc rp_invoke_procs { conn arg why } {}

    global errorInfo
    # Save the error message.
    nsv_set bootstrap_fatal_error . "$message<blockquote><pre>[ns_quotehtml $errorInfo]</pre></blockquote>"
    # Log the error message.
    ns_log "Error" "Server startup failed: $message\n$errorInfo"

    # Define a filter procedure which displays the appropriate error message.
    proc bootstrap_write_error { conn arg why } {
	ns_returnerror 503 "Server startup failed: [nsv_get bootstrap_fatal_error .]"
	return "filter_return"
    }

    # Register the filter on GET/POST/HEAD * to return this message.
    ns_register_filter preauth GET * bootstrap_write_error
    ns_register_filter preauth POST * bootstrap_write_error
    ns_register_filter preauth HEAD * bootstrap_write_error

    if { $throw_error_p } {
	return -code error -errorcode bootstrap_fatal_error "Bootstrap fatal error"
    }
}

set errno [catch {
    #####
    #
    # Perform some checks to make sure that (a) a recent version of the Oracle driver
    # is installed and (b) the ACS data model is properly loaded.
    #
    #####

    # In order to make sure there are database handles available, just grab one and
    # release it immediately. Don't bother starting up if not.
    if { [catch { set db [ns_db gethandle -timeout 15]}] || ![string compare $db ""] } {
	set oracle_problem "The database driver does not appear to be correctly installed and configured (a database handle could not be allocated on startup)."
    } elseif { [catch { ns_ora 1row $db "select sysdate from dual" }] } {
	set oracle_problem "A really, really old version of the Oracle driver (a version which doesn't support the ns_ora procedure) is installed. You'll need version 2.3 or later."
    } elseif { [catch { ns_ora exec_plsql_bind $db { begin :1 := 37*73; end; } 1 "" }] } {
	set oracle_problem "An old version of the Oracle driver (a version which doesn't support ns_ora exec_plsql_bind) is installed. You'll need version 2.3 or later."
    } else {
	ns_db releasehandle $db
    }

    # Load all the -procs file in the acs-kernel package, in lexicographical order.
    # This is the first time each of these files is being loaded (see
    # the documentation for the apm_first_time_loading_p proc).
    global apm_first_time_loading_p
    set apm_first_time_loading_p 1

    set files [glob -nocomplain "$root_directory/packages/acs-tcl/tcl/*-procs.tcl"]
    if { [llength $files] == 0 } {
	error "Unable to locate $root_directory/packages/acs-tcl/tcl/*-procs.tcl."
    }

    foreach file [lsort $files] {
	# Clip $root_directory/packages from the beginning of the file name.
	set relative_path [string range $file \
		[expr { [string length "$root_directory/packages"] + 1 }] end]

	ns_log "Notice" "Loading packages/$relative_path..."
	bootstrap_source $file
	nsv_set apm_library_mtime packages/$relative_path [file mtime $file]

	# Call db_release_unused_handles, only if the library defining it
	# (10-database-procs.tcl) has been sourced yet.
	if { [llength [info procs db_release_unused_handles]] != 0 } {
	    db_release_unused_handles
	}
    }

    unset apm_first_time_loading_p

    if { [info exists oracle_problem] } {
	# Yikes - no Oracle driver. Remember what the problem is, and run the
	# installer.
	ns_log "Error" $oracle_problem
	nsv_set acs_properties oracle_problem $oracle_problem
	ns_log "Notice" "Oracle driver found; Sourcing the installer."
	source "$root_directory/packages/acs-tcl/tcl/installer.tcl"
	source "$root_directory/packages/acs-tcl/tcl/installer-init.tcl"
	return
    }

    # Is ACS installation complete? If not, source the installer and bail.
    if { ![ad_verify_install] } {
	ns_log "Notice" "Installation is not complete - sourcing the installer."
	source "$root_directory/packages/acs-tcl/tcl/installer.tcl"
	source "$root_directory/packages/acs-tcl/tcl/installer-init.tcl"
	return
    }

    # Cache all parameters for enabled package instances.  
    ad_parameter_cache_all  
    
    # Load the Tcl package init files.
    set files [glob -nocomplain [file join $root_directory packages acs-tcl tcl *-init.tcl]]

    foreach file [lsort $files] {
	# Clip $root_directory/packages from the beginning of the file name.
	set relative_path [string range $file \
		[expr { [string length "$root_directory/packages"] + 1 }] end]

	ns_log "Notice" "Loading packages/$relative_path..."
	bootstrap_source $file
	nsv_set apm_library_mtime packages/$relative_path [file mtime $file]
    }    

    # Delete the bootstrap_source procedure, since it's no longer needed.
    rename bootstrap_source ""

    foreach package_key [db_list package_keys_select {
	select package_key from apm_enabled_package_versions
    }] {
	nsv_set apm_enabled_package $package_key 1
    }
    
    # Load *-procs.tcl and *-init.tcl files for enabled packages.
    ns_log Notice "Loading Tcl library files..."
    apm_load_libraries -procs
    ns_log Notice "Loading Tcl Initialization files..."
    apm_load_libraries -init
    
    if { ![nsv_exists rp_properties request_count] } {
	# security-init.tcl has not been invoked, so it's safe to say that the
	# core has not been properly initialized and the server will probably
	# fail catastrophically.
	bootstrap_fatal_error "The request processor routines have not been loaded."
    }

    ns_log "Notice" "Done loading ACS."
}]

if { $errno && $errno != 2 } {
    # An error occured while bootstrapping. Handle it by registering a filter
    # to display the error message, rather than leaving the site administrator
    # to guess what broke.

    # If the $errorCode is "bootstrap_fatal_error", then the error was explicitly
    # thrown by a call to bootstrap_fatal_error. If not, bootstrap_fatal_error was
    # never called, so we need to call it now.
    global errorCode
    if { [string compare $errorCode "bootstrap_fatal_error"] } {
	bootstrap_fatal_error "Error during bootstrapping" 0
    }
}
