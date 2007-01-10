ad_library {
    Stub procs for developer support procs we call in acs-tcl
    for logging.  We check here if the procs are defined
    before we stub them out.

    This is done since the old ad_call_proc_if_exists
    is somewhat expensive and these are called a lot in 
    every request.

    @author Jeff Davis <davis@xarg.net>
    @creationd-date 2005-03-02
    @cvs-id $Id$
}

if {{} eq [info procs ds_add]} {
    proc ds_add {args} {}
}
if {{} eq [info procs ds_collect_db_call]} {
    proc ds_collect_db_call {args} {}
}
if {{} eq [info procs ds_collect_connection_info]} {
    proc ds_collect_connection_info {} {}
}
