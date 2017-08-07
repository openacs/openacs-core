ad_page_contract {

    Kill (restart) the server.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 27:th of March 2003
    @cvs-id $Id$
}

set page_title "Restarting Server"
set context [list $page_title]

#
# When using NaviServer, and when the kernel parameter
# "NsShutdownWithNonZeroExitCode" is set to be true, the "-restart"
# option will be used.
#
if {[ns_info name] eq "NaviServer" &&
    [parameter::get -parameter NsShutdownWithNonZeroExitCode -package_id [ad_acs_kernel_id] -default 0]
} {
    set cmd {ns_shutdown -restart}
} else {
    set cmd ns_shutdown
}

#
# We perform the shutdown as a scheduled proc, so the server will have
# time to serve the page.
#
ad_schedule_proc -thread t -once t 2 {*}$cmd

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
