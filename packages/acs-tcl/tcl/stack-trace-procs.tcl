# stack-trace-procs.tcl
# (bdolicki 2000) - formerly known as StackTrace.tcl

# Print stack trace after catch
# Taken from http://photo.net/bboard/q-and-a-fetch-msg.tcl?msg_id=000kCh
ad_library {
    @author bdolicki@branimir.com
    @creation-date 2000
    @cvs-id $Id$
}


ad_proc -public ad_print_stack_trace {} {
    Formerly known as PrintStackTrace.  This is useful if you use catch but
    you'd still want to access the full Tcl stack trace e.g. to dump it into
    the log file

    This command truncatates the actual commands to improve readability
    while ad_get_tcl_call_stack dumps the full stack

    @see ad_get_tcl_call_stack
} {
    uplevel {
        if {$::errorInfo ne ""} {
            set callStack [list $::errorInfo "invoked from within"]
        } else {
            set callStack {}
        }
        for {set i [info level]} {$i > 0} {incr i -1} {
            set call [info level $i]
            if {[string length $call] > 160} {
                set call "[string range $call 0 150]..."
            }
            regsub -all {\n} $call {\\n} call
            lappend callStack "   $call"
            if {$i > 1} {
                lappend callStack "invoked from within"
            }
        }
        return [join $callStack "\n"]
    }
}

ad_proc -public ad_log_stack_trace {} {
    A wrapper for ad_print_stack_trace which does the logging for you.
} {
    ns_log Error [ad_print_stack_trace]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
