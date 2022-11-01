ad_library {

    notifications reply init - sets up scheduled procs

    @cvs-id $Id$
    @author Ben Adida (ben@openforce.net)
    @creation-date 2002-05-27

}

# Roberto Mello (12/2002): Added parameter and check for qmail queue scanning

set scan_replies_p [parameter::get_from_package_key \
                        -package_key notifications \
                        -parameter EmailQmailQueueScanP \
                        -default 0]

if { $scan_replies_p == 1 } {
    ad_schedule_proc -thread t 60 notification::reply::sweep::scan_all_replies
    ad_schedule_proc -thread t 60 notification::reply::sweep::process_all_replies
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
