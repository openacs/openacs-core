ad_library {

    Compatibility procs in case we're not running a version of AOLServer that supports charsets.

    @author Rob Mayoff [mayoff@arsdigita.com]
    @author Nada Amin [namin@arsdigita.com]
    @creation-date June 28, 2000
    @cvs-id $Id$
}

#
# Define dummy stubs in case the required commands are not available.
#
foreach one_proc {ns_startcontent ns_encodingfortype} {
    if {[namespace which $one_proc] eq ""} {
        proc $one_proc {args} { }
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
