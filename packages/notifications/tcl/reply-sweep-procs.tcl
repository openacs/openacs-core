ad_library {

    Notification Reply Sweeps.

    Procs that make sure that replies are being processed.

    @creation-date 2002-06-02
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::reply::sweep {}


ad_proc -public notification::reply::sweep::scan_all_replies {} {
    Go through all the delivery methods and scan replies for that delivery method.
} {
    ns_log Debug "notification::reply::sweep::scan_all_replies starting"

    # Load up the delivery methods
    set delivery_method_ids [db_list select_deliv_methods {}]

    # Loop and scan replies on each one
    foreach delivery_method_id $delivery_method_ids {
        ns_log Debug "scan_all_replies deliv method $delivery_method_id"
        notification::delivery::scan_replies -delivery_method_id $delivery_method_id
    }
}

ad_proc -public notification::reply::sweep::process_all_replies {} {
    Go through the replies in the DB and dispatch correctly to the right processor.
} {
    ns_log Debug "notification::reply::sweep::process_all_replies starting"

    # Load up the replies
    set replies [db_list_of_lists select_replies {}]

    # Loop through and transactionally process each one
    foreach reply $replies {
        set reply_id [lindex $reply 0]
        set type_id [lindex $reply 1]

        ns_log Debug "process_all_replies: one reply $reply_id of type $type_id"

        if { [ catch {
            notification::type::process_reply -type_id $type_id -reply_id $reply_id
	    db_dml deletehold {}
            notification::reply::delete -reply_id $reply_id
        } err ] } {
            ns_log Error "notification::reply::sweep::process_all_replies: bombed on reply_id $reply_id:\n$err"
        }
    }
}
