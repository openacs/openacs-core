ad_library {

    Notification Intervals

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::interval {

    ad_proc -public schedule_all {} {
        This schedules all the notification procs
    } {
    }

    ad_proc -public sweep_notifications {
        {-interval_id:required}
    } {
        This sweeps for notifications in a particular interval
    } {

    }

}
