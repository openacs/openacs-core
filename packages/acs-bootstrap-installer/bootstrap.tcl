# /packages/acs-tcl/bootstrap/bootstrap.tcl
#
# Code to bootstrap OpenACS, invoked by /tcl/0-acs-init.tcl.
#
# @creation-date 12 May 2000
# @author Jon Salz [jsalz@arsdigita.com]
# @cvs-id $Id$

if {![info exists ::acs::rootdir]} {
    # just a temporary measure before the release of OpenACS 5.8.1
    ns_log warning "update openacs-4/tcl/0-acs-init.tcl"
    set ::acs::rootdir [file dirname [string trimright $::acs::tcllib "/"]]
}

# Remember the length of the error log file (so we can easily seek back to this
# point later). This is used in /www/admin/monitoring/startup-log.tcl to show
# the segment of the error log corresponding to server initialization (between
# "AOLserver/xxx starting" and "AOLserver/xxx running").
catch { nsv_set acs_properties initial_error_log_length [file size [ns_info log]] }

# Initialize proc_doc NSV arrays.
nsv_set proc_source_file . ""

# Initialize ad_after_server_initialization.
nsv_set ad_after_server_initialization . ""

ns_log Notice "bootstrap begin encoding [encoding system]"

###
#
# Bootstrapping code.
#
###

# A helper procedure called if a fatal error occurs.
proc bootstrap_fatal_error { message { throw_error_p 1 } } {
    # First of all, redefine the "rp_invoke_filter" and "rp_invoke_procs"
    # routines to do nothing, to circumvent the request processor.
    proc rp_invoke_filter { conn arg why } { return "filter_ok" }
    proc rp_invoke_procs { conn arg why } {}
    set proc_name {Bootstrap}

    # Save the error message.
    nsv_set bootstrap_fatal_error . "$message<blockquote><pre>[ns_quotehtml $::errorInfo]</pre></blockquote>"
    # Log the error message.
    ns_log Error "$proc_name: Server startup failed: $message\n$::errorInfo"

    # Define a filter procedure which displays the appropriate error message.
    proc bootstrap_write_error { args } {
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
    # Used for ns_logs:
    set proc_name {Bootstrap}

    # Load the special bootstrap Tcl library.

    set files [lsort [glob -nocomplain "$::acs::rootdir/packages/acs-bootstrap-installer/tcl/*-procs.tcl"]]
    if { [llength $files] == 0 } {
	error "Unable to locate $::acs::rootdir/packages/acs-bootstrap-installer/tcl/*-procs.tcl."
    }

    foreach file [lsort $files] {
	ns_log Notice "$proc_name: sourcing $file"
	source $file
    }

    db_bootstrap_set_db_type database_problem

    #####
    #
    # Perform some checks to make sure that (a) a recent version of the Oracle or PG driver
    # is installed and (b) the OpenACS data model is properly loaded.
    #
    #####

    # DRB: perform RDBMS-specific sanity checks if the user has survived the database
    # gauntlet thus far.

    if { ![info exists database_problem] } {
        set db_fn "$::acs::rootdir/packages/acs-bootstrap-installer/db-init-checks-[nsv_get ad_database_type .].tcl"
        if { ![file isfile $db_fn] } {
            set database_problem "\"$db_fn\" does not exist."
        } else {
            source $db_fn
        }
        db_bootstrap_checks database_problem error_p
    }

    ns_log Notice "$proc_name: Loading acs-tcl"
    apm_bootstrap_load_libraries -procs acs-tcl

    if { [info exists database_problem] } {
	# Yikes - database problems.
	ns_log Error "$proc_name: $database_problem"

        # Check if the admin enabled the site-failure message, display
        # it if enabled.
        if { [file exists "$::acs::rootdir/www/global/site-failure.html"] } {
            ns_log Notice "$proc_name: database problem found; enabling www/global/site-failure.html. Rename this html page if you want to run the installer instead."
            source "$::acs::rootdir/packages/acs-bootstrap-installer/site-failure-message.tcl"
            return
        }

        # Remember what the problem is, and run the installer.
	nsv_set acs_properties database_problem $database_problem
	ns_log Notice "$proc_name: database problem found; Sourcing the installer."
	source "$::acs::rootdir/packages/acs-bootstrap-installer/installer.tcl"
	source "$::acs::rootdir/packages/acs-bootstrap-installer/installer-init.tcl"
	return
    }

    # Here we need to at least load up queries for the acs-tcl and
    # acs-bootstrap-installer packages (ben)

    apm_bootstrap_load_queries acs-tcl
    apm_bootstrap_load_queries acs-bootstrap-installer

    # Is OpenACS installation complete? If not, source the installer and bail out.
    if { ![ad_verify_install] } {
	ns_log warning "$proc_name: Installation is not complete - sourcing the installer."
	source "$::acs::rootdir/packages/acs-bootstrap-installer/installer.tcl"
	source "$::acs::rootdir/packages/acs-bootstrap-installer/installer-init.tcl"
	return
    }
    
    #
    # The installation is apparently ok, we can use the database. It
    # should not be necessary to use the [ad_acs_kernel_id] redefine
    # trick, but to use a plain variable in the ::acs namespace.
    #
    set ::acs::kernel_id [ad_acs_kernel_id_mem]
    ns_log notice "bootstrap: setting ::acs::kernel_id to $::acs::kernel_id"

    #
    # Load all parameters for enabled package instances.
    # ad_parameter_cache_all  
    
    # Load the Tcl package init files.
    apm_bootstrap_load_libraries -init acs-tcl

    # LARS: Load packages/acs-automated-testing/tcl/aa-test-procs.tcl
    ns_log Notice "Loading acs-automated-testing specially so other packages can define tests..."
    apm_bootstrap_load_libraries -procs acs-automated-testing

    # Build the list of subsite packages
    apm_build_subsite_packages_list

    # Build the nsv dependency and descendent structures
    apm_build_package_relationships

    # Load libraries, queries etc. for remaining packages
    apm_load_packages

    # The acs-tcl package is a special case. Its Tcl libraries need to be loaded
    # before all the other packages. However, its tests need to be loaded after all
    # packages have had their Tcl libraries loaded.
    apm_load_packages -load_libraries_p 0 -load_queries_p 0 -packages acs-tcl

    if { ![nsv_exists rp_properties request_count] } {
	# security-init.tcl has not been invoked, so it's safe to say that the
	# core has not been properly initialized and the server will probably
	# fail catastrophically.
	bootstrap_fatal_error "The request processor routines have not been loaded."
    }

    ns_log Notice "bootstrap finished encoding [encoding system]"
    ns_log Notice "$proc_name: Done loading OpenACS."
}]

if { $errno && $errno != 2 } {
    # An error occurred while bootstrapping. Handle it by registering a filter
    # to display the error message, rather than leaving the site administrator
    # to guess what broke.

    # If the $::errorCode is "bootstrap_fatal_error", then the error was explicitly
    # thrown by a call to bootstrap_fatal_error. If not, bootstrap_fatal_error was
    # never called, so we need to call it now.
    if {$::errorCode ne "bootstrap_fatal_error"  } {
	bootstrap_fatal_error "Error during bootstrapping" 0
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
