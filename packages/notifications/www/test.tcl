ad_page_contract {

    Simple script to allow one to sweep the notifications queue for a particular
    interval.

    To use this for testing remove your local copy of ../tcl/sweep-init.tcl, restart
    your server and use ../www/test-cleanup.tcl to clean up notifications that have
    been sent. 

}

set intervals [notification::get_all_intervals]

ad_form -name sweep -form {
    {interval_id:integer(select)        {label "Choose interval"}
                                        {options $intervals}}
} -on_submit {
    notification::sweep::sweep_notifications -interval_id $interval_id
    ad_script_abort
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
