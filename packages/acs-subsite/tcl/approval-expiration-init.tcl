ad_library {

    Sweep for expired user approvals.

    @cvs-id $Id$
    @author Lars Pind  (lars@collaboraid.biz)
    @creation-date 2003-05-28

}

set ApprovalExpirationDays [parameter::get -parameter ApprovalExpirationDays -package_id [ad_acs_kernel_id] -default 0]

# Only schedule proc if we've set approvals to expire
if { $ApprovalExpirationDays > 0 } {
    # Schedule proc to run once nightly
    ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 0 0] subsite::sweep_expired_approvals -days $ApprovalExpirationDays
}
