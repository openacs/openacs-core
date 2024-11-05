if {[info commands ::xo::api] ne ""} {    
    ad_schedule_proc -thread t -once t 1 ::xo::api update_nx_docs
} else {
    ns_log warning "INIT: no xo::api available"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
