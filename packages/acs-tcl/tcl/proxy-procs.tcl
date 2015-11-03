# packages/acs-tcl/tcl/proxy-procs.tcl                                                                                             
ad_library {

    Proxy procs

    @author <yourname> (<your email>)
    @creation-date 2007-09-17
    @cvs-id $Id$
}

#
# First check if ns_proxy is available
#
if {![catch {ns_proxy configure ExecPool -maxruns 0}]} {
    
    namespace eval proxy {}
    
    ad_proc -public proxy::exec {
        {-call}
        {-cd}
    } {
        Execute the statement in a proxy instead of normal exec

        @param call Call which is passed to the "exec" command (required)
        @param cd  change to the given directory before executing the command
    } {
        set handle [ns_proxy get ExecPool]
        with_finally -code {
            if {[info exists cd]} {
                ns_proxy eval $handle [list cd $cd]
            }
            set return_string [ns_proxy eval $handle [list ::exec {*}$call]]
        } -finally {
            ns_proxy release $handle
        }
        return $return_string
    }

    # Now rename exec; protect cases, where file is loaded multiple times
    if {[info commands ::real_exec] eq ""} {rename exec real_exec}

    ad_proc exec {args} {This is the wrapped version of exec} {proxy::exec -call $args}
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
