# packages/acs-tcl/tcl/proxy-procs.tcl                                                                                                   

ad_library {

    Proxy procs

    @author <yourname> (<your email>)
    @creation-date 2007-09-17
    @cvs-id $Id$
}

# First check that ns_proxy is configured
if {![catch {ns_proxy get exec_proxy}]} {
    namespace eval proxy {}
    ad_proc -public proxy::exec {
	{-call}
    } {
	Execute the statement in a proxy instead of normal exec
	
	@param call Call which is passed to the "exec" command
    } {
	set handle [ns_proxy get exec_proxy]
	set return_string [ns_proxy eval $handle "exec $call"]
	ns_proxy release $handle
	return $return_string
    }
}
