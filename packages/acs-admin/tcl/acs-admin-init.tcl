ad_library {

    Automated functions for acs-admin

    @author Gustaf Neumann
    @creation-date 2018-08-15
}

#
# Check, if certificates are running out (run this every night at 3am and 3 mins)
#

ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 3 3] ::acs_admin::check_expired_certificates

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
