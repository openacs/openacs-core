ad_library {

    notifications init - sets up scheduled procs

    @cvs-id $Id$
    @author Ben Adida (ben@openforce.net)
    @creation-date 2002-05-27

}

# DRB: The cleanup sweep interval should be made a parameter someday ... 

ad_schedule_proc -thread t 900 notification::sweep::cleanup_notifications

foreach interval [notification::get_all_intervals] {
    set n_seconds [lindex $interval 2]
    if {$n_seconds > 0} {
        set batched_p 1
    } else {
        set batched_p 0
    } 

    # Send weekly and daily notifications at defined times rather than a week after
    # the server was started up, etc etc.   Hourly, instant, and exotic custom
    # intervals will run relative to the server startup time.

    if { $n_seconds == 24 * 60 * 60 } {
        ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 0 0] notification::sweep::sweep_notifications -interval_id [lindex $interval 1] -batched_p $batched_p
    } elseif { $n_seconds == 7 * 24 * 60 * 60 } {
        ad_schedule_proc -thread t -schedule_proc ns_schedule_weekly [list 0 0 0] notification::sweep::sweep_notifications -interval_id [lindex $interval 1] -batched_p $batched_p
    } elseif {$n_seconds > 0} {
        ad_schedule_proc -thread t $n_seconds notification::sweep::sweep_notifications -interval_id [lindex $interval 1] -batched_p $batched_p
    } else {
        ad_schedule_proc -thread t 60 notification::sweep::sweep_notifications -interval_id [lindex $interval 1] -batched_p $batched_p
    }        
}
