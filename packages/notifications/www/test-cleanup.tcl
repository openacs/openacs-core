ad_page_contract {

    Simple script to test the cleanup of notifications that have been sent to
    users.

    To use this for testing remove your local copy of ../tcl/sweep-init.tcl, restart
    your server and use ../www/test to send notifications for a particular interval.
    Afterwards run this script to verify that sent notifications are properly cleaned up.

}

notification::sweep::cleanup_notifications
ns_return 200 text/html "done"

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
