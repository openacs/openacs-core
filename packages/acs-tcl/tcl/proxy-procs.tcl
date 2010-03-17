# packages/acs-tcl/tcl/proxy-procs.tcl                                                                                                   

ad_library {

    Proxy procs

    @author <yourname> (<your email>)
    @creation-date 2007-09-17
    @cvs-id $Id$
}

# First check that ns_proxy is configured
if {![catch {set handler [ns_proxy get exec_proxy]}]} {
    ns_proxy release $handler
    
    namespace eval proxy {}
    
    ad_proc -public proxy::exec {
	{-call}
    } {
	Execute the statement in a proxy instead of normal exec
	
	@param call Call which is passed to the "exec" command
    } {
	set handle [ns_proxy get exec_proxy]
	with_finally -code {
	    set return_string [ns_proxy eval $handle "exec $call"]
	} -finally {
	    ns_proxy release $handle
	}
	return $return_string
    }

    # Now rename exec
    rename exec real_exec
    ad_proc exec {args} {This is the wrapped version of exec} {proxy::exec -call $args}
}
