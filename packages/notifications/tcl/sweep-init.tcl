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
    ad_schedule_proc -thread t 120 notification::sweep::sweep_notifications -interval_id [lindex $interval 1]
}
