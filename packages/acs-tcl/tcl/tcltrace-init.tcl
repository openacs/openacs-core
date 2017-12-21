#
# Add Tcl traces for asserted Tcl commands.
#
# Add the traces only, when the functions are active (i.e. the
# controlling package parameter has not the default value), because
# adding the traces has performance impact on potentially frequently
# called Tcl commands (such as e.g. ns_log)
#
# Therefore, activating/deactivating requires a server restart.
#
set trace ""
foreach {parameter default cmd} {
    TclTraceLogSeverities ""  {trace add execution ::ns_log     enter {::tcltrace::before-ns_log}}
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
# simple traces
#
set traced_cmds {}
#set traced_cmds {::nsv_get}
#set traced_cmds {::ns_setcookie ::ns_getcookie ::ns_deletecookie}
foreach cmd $traced_cmds {
    append trace "\ntrace add execution $cmd  enter {::tcltrace::before}"
}
set traced_cmds {}

#
# traces with context
#
#set traced_cmds {::ns_return ::ns_returnredirect}

foreach cmd $traced_cmds {
    append trace "\ntrace add execution $cmd  enter {::tcltrace::before -details}"
}
set traced_cmds {}


if {$trace ne ""} {
    ns_ictl trace create $trace
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
