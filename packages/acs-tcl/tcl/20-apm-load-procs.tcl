ad_library {

    Routines necessary to load package code.

    @creation-date 26 May 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id $Id$
}

proc_doc apm_source { __file } {
    Sources $__file in a clean environment, returning 1 if successful or 0 if not.
} {
    if { ![file exists $__file] } {
	ns_log "Error" "Unable to source $__file: file does not exist."
	return 0
    }

    # Actually do the source.
    if { [catch { source $__file }] } {
	global errorInfo
	ns_log "Error" "Error sourcing $__file:\n$errorInfo"
	return 0
    }

    return 1
}

proc_doc apm_first_time_loading_p {} { 
    Returns 1 if this is a -procs.tcl file's first time loading, or 0 otherwise. 
} {
    global apm_first_time_loading_p
    return [info exists apm_first_time_loading_p]
}

ad_proc ad_after_server_initialization { name args } {

    Registers code to run after server initialization is complete.

    @param name a human-readable name for the code block (for debugging purposes).
    @param args a code block or procedure to invoke.

} {
    nsv_lappend ad_after_server_initialization . [list name $name script [info script] args $args]
}
