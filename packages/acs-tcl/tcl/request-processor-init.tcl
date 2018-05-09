ad_library {

    Initialization stuff for the request processing pipeline.

    @creation-date 30 May 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id $Id$
}

#
# Make sure, the following global kernel_is is always set, also on upgrading acs-reloads
#
set ::acs::kernel_id [ad_acs_kernel_id]

if {[nsv_exists rp_properties request_count] != 0} {
    #
    # This is a re-init. There is no need, to rerun the code
    # below. Setting e.g. filters multiple times might have unwanted
    # behavor in the server
    #
    ns_log notice "request-processor re-init"
    return
}

# These procedures are dynamically defined at startup to alleviate
# lock contention. Thanks to davis@xarg.net.

if { [parameter::get -package_id $::acs::kernel_id -parameter PerformanceModeP -default 0] } {
  ad_proc -private rp_performance_mode {} {
    Returns 1 if the request processor is in performance mode, 0 otherwise.
  } {
    return 1
  }
} else {
  ad_proc -private rp_performance_mode {} {
    Returns 1 if the request processor is in performance mode, 0 otherwise.
  } {
    return 0
  }
}

if { [parameter::get -package_id $::acs::kernel_id -parameter DebugP -default 0] ||
     [parameter::get -package_id $::acs::kernel_id -parameter LogDebugP -default 0]
 } { 

    ad_proc -private rp_debug { { -debug f } { -ns_log_level notice } string } {

	Logs a debugging message, including a high-resolution (millisecond)
	timestamp. 
	
    } {
	if { [parameter::get -package_id $::acs::kernel_id -parameter DebugP -default 0] } { 
	    set clicks [clock clicks -milliseconds]
	    ds_add rp [list debug $string $clicks $clicks]
	}
	if { [parameter::get -package_id $::acs::kernel_id -parameter LogDebugP -default 0]
	     || [string is true -strict $debug]
	 } {
	    if { [info exists ::ad_conn(start_clicks)] } {
		set timing " ([expr {[clock clicks -milliseconds] - $::ad_conn(start_clicks)}] ms)"
	    } else {
		set timing ""
	    }
	    ns_log $ns_log_level "RP$timing: $string"
	}
    }
} else {
    ad_proc -private rp_debug { { -debug f } { -ns_log_level notice } string } {
	dummy placeholder
    } {
	return
    }
}

if {[nsv_exists rp_properties request_count] == 0} {
    #
    # Run this only once at startup, and not on re-inits
    #
    nsv_set rp_properties request_count 0

    foreach httpMethod {GET HEAD POST} {
        ns_register_filter preauth $httpMethod /resources/* rp_resources_filter
        ns_register_filter preauth $httpMethod * rp_filter
        ns_register_proc $httpMethod / rp_handler
    }
}

set unreg_cmd [expr {$::acs::useNaviServer ? "ns_unregister_op" : "ns_unregister_proc"}]

# Unregister any GET/HEAD/POST handlers for /*.tcl (since they
# interfere with the abstract URL system of OpenACS). AOLserver/
# NaviServer automatically register these when EnableTclPages is
# configured as true.

$unreg_cmd GET /*.tcl
$unreg_cmd HEAD /*.tcl
$unreg_cmd POST /*.tcl

set listings [ns_config "ns/server/[ns_info server]" "directorylisting" "none"]
if { $listings eq "fancy" || $listings eq "simple" } {
  nsv_set rp_directory_listing_p . 1
} else {
  nsv_set rp_directory_listing_p . 0
}

# this initialization must be in a package alphabetically before
# acs-templating, so this adp handler can be overwritten there.
foreach { type handler } {
    tcl rp_handle_tcl_request
    vuh rp_handle_tcl_request
} {
    rp_register_extension_handler $type $handler
}

ad_after_server_initialization filters_register {
    if {[nsv_exists rp_filters .]} {
        set filters [nsv_get rp_filters .]
    } else {
        set filters [list]
    }
    # This lsort is what makes the priority stuff work. It guarantees
    # that filters are registered in order of priority. AOLServer will
    # then run the filters in the order they were registered.
    set filters [lsort -integer -index 0 $filters]
    ns_log notice "FILTERS [join $filters \n]"
    nsv_set rp_filters . $filters

    set filter_index 0
    foreach filter_info $filters {
	lassign $filter_info priority kind method path \
		proc arg debug critical description script

	# Figure out how to invoke the filter, based on the number of arguments.
	if { [llength [info procs $proc]] == 0 } {
	    # [info procs $proc] returns nothing when the procedure has been
	    # registered by C code (e.g., ns_returnredirect). Assume that neither
	    # "conn" nor "why" is present in this case.
	    set arg_count 1
	} else {
	    set arg_count [llength [info args $proc]]
	}

	if { $debug == "t" } {
	    set debug_p 1
	} else {
	    set debug_p 0
	}

        ns_log Notice "ns_register_filter $kind $method $path rp_invoke_filter \
		[list $filter_index $debug_p $arg_count $proc $arg]"
        ns_register_filter $kind $method $path rp_invoke_filter \
		[list $filter_index $debug_p $arg_count $proc $arg]

	incr filter_index
    }
}

ad_after_server_initialization procs_register {
    if {[nsv_exists rp_registered_procs .]} {
        set procs [nsv_get rp_registered_procs .]
    } else {
        set procs [list]
    }

    set proc_index 0
    foreach proc_info $procs {
	lassign $proc_info method path proc arg debug noinherit description script

	if { $noinherit == "t" } {
	    set noinherit_switch "-noinherit"
	} else {
	    set noinherit_switch ""
	}

	# Figure out how to invoke the filter, based on the number of arguments.
	if { [llength [info procs $proc]] == 0 } {
	    # [info procs $proc] returns nothing when the procedure has been
	    # registered by C code (e.g., ns_returnredirect). Assume that neither
	    # "conn" nor "why" is present in this case.
	    set arg_count 1
	} else {
	    set arg_count [llength [info args $proc]]
	}

	if { $debug == "t" } {
	    set debug_p 1
	} else {
	    set debug_p 0
	}

	ns_log Notice "ns_register_proc $noinherit_switch [list $method $path rp_invoke_proc [list $proc_index $debug_p $arg_count $proc $arg]]"
	ns_register_proc {*}$noinherit_switch \
	    $method $path rp_invoke_proc [list $proc_index $debug_p $arg_count $proc $arg]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
