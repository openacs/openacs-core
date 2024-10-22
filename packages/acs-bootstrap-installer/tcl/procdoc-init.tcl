if {[info commands ::xo::api] ne ""} {
    ns_log notice "updating online documentation using xo::api"
    ::xo::api update_nx_docs
    ns_log notice "updating online documentation using xo::api DONE"
} else {
    ns_log warning "INIT: no xo::api available"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
