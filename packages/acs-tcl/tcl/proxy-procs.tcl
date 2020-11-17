ad_library {

    Proxy procs

    @author Malte Sussdorff, Gustaf Neumann
    @creation-date 2007-09-17
}

#
# First check if ns_proxy is available
#
if {![catch {ns_proxy configure ExecPool -maxruns 0}]} {

    namespace eval proxy {}

    ad_proc -public proxy::exec {
        {-call:required}
        {-cd}
        {-ignorestderr:boolean}
    } {
        Execute the statement in a proxy instead of normal exec

        @param call Call which is passed to the "exec" command
        @param cd   Change to the given directory before executing the command
        @param ignorestderr Boolean value to indicate, whether the stderr output
               of the exec'ed command should be ignored.
    } {
        set start_time [clock clicks -milliseconds]
        set handle [ns_proxy get ExecPool]
        if {[clock clicks -milliseconds] - $start_time > 5} {
            ns_log warning "ExecPool: getting handle took \
                [expr {[clock clicks -milliseconds] - $start_time}]ms (potential configuration issue)"
        }

        ad_try {
            if {[info exists cd]} {
                #
                # We were requested to switch to a different
                # directory. Remember the old directory before
                # switching to the new one.
                #
                set pwd [ns_proxy eval $handle pwd]
                ns_proxy eval $handle [list cd $cd]
            }
            set exec_flags [expr {$ignorestderr_p ? "-ignorestderr --" : ""}]
            set return_string [ns_proxy eval $handle [list ::exec {*}$exec_flags {*}$call]]
        } finally {
            if {[info exists pwd]} {
                #
                # Switch back to the previous directory.
                #
                ns_proxy eval $handle [list cd $pwd]
            }
            ns_proxy release $handle
        }
        return $return_string
    }

    # Now rename exec; protect cases, where file is loaded multiple times
    if {[namespace which ::real_exec] eq ""} {
        rename exec real_exec
    }

    ad_proc exec {-ignorestderr:boolean -- args} {
        This is the wrapped version of exec
    } {
        proxy::exec -ignorestderr=$ignorestderr_p -call $args
    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
