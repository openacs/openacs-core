# stack-trace-procs.tcl
# (bdolicki 2000) - formerly known as StackTrace.tcl

# Print stack trace after catch
# Taken from http://photo.net/bboard/q-and-a-fetch-msg.tcl?msg_id=000kCh
ad_library {
  @author bdolicki@branimir.com
  @creation-date 2000
  @cvs-id $Id$
}


ad_proc ad_print_stack_trace {} {
 Formerly known as PrintStackTrace.  This is useful if you use catch but
 you'd still want to access the full Tcl stack trace (e.g. to dump it
into
 the log file)
} {
uplevel {
       global errorInfo
       set callStack [list $errorInfo]
       for {set i [info level]} {$i >= 0} {set i [expr $i - 1]} {
           lappend callStack "invoked from within"
           lappend callStack [info level $i]
       }
       return [join $callStack "\n"] 
}
}

ad_proc ad_log_stack_trace {} {
 A wrapper for ad_print_stack_trace which does the logging for you.
} {
 ns_log Error [ad_print_stack_trace]
}
