#
# Add Tcl traces for asserted tcl commands.
#
# Add the traces only, when the functions are active (i.e. the
# controling package parameter has not the default value), because
# adding the traces has performance impact on potentially frequently
# called tcl commands (such as e.g. ns_log)
#
# Therefore, activating/deactivating requires a server restart.
#
set trace ""
foreach {parameter default cmd} {
    TclTraceLogServerities "" {trace add execution ::ns_log     enter {::tcltrace::before-ns_log}}
    TclTraceSaveNsReturn   0  {trace add execution ::ns_return  enter {::tcltrace::before-ns_return}}
} {
    if {[::parameter::get_from_package_key \
	     -package_key acs-tcl \
	     -parameter $parameter \
	     -default $default] ne $default} {
	append trace \n$cmd 
    }
}

#
# Optionally add more traces here
#
#append trace "\ntrace add execution ::nsv_get    enter {::tcltrace::before}"

if {$trace ne ""} {
    ns_ictl trace create $trace
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
