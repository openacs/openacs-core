ad_library {

    Set up scheduled procs for running nightly batch sync, and for purging old logs.

    @cvs-id $Id$
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-09-09

}

# Schedule old job log purge
ad_schedule_proc \
    -thread t \
    -schedule_proc ns_schedule_daily \
    [list 0 30] \
    auth::sync::purge_jobs

# Schedule batch sync sweeper
ad_schedule_proc \
    -thread t \
    -schedule_proc ns_schedule_daily \
    [list 1 0] \
    auth::sync::sweeper
