ad_library {

    notifications init - sets up scheduled procs

    @cvs-id $Id$
    @author Ben Adida (ben@openforce)
    @date 2002-05-27

}

# Hack for now to test immediate deliveries
# FIXME
ad_schedule_proc -thread t 60 notification::sweep::cleanup_notifications

foreach interval [notification::get_all_intervals] {
    set n_seconds [lindex $interval 2]
    if {$n_seconds > 0} {
        set batched_p 1
    } else {
        set batched_p 0
    } 

    ad_schedule_proc -thread t $n_seconds notification::sweep::sweep_notifications -interval_id [lindex $interval 1] -batched_p $batched_p
}
