ad_library {
    Stub procs for developer support procs we call in acs-tcl
    for logging.  We check here if the procs are defined
    before we stub them out.

    This is done since the old ad_call_proc_if_exists
    is somewhat expensive and these are called a lot in 
    every request.

    @author Jeff Davis <davis@xarg.net>
    @creation-date 2005-03-02
    @cvs-id $Id$
}

if {[namespace which ds_add] eq ""} {
    proc ds_add {args} {}
}
if {[namespace which ds_collect_db_call] eq ""} {
    proc ds_collect_db_call {args} {}
}
if {[namespace which ds_collect_connection_info] eq ""} {
    proc ds_collect_connection_info {} {}
}
if {[namespace which ds_init] eq ""} {
    proc ds_init {} {}
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
