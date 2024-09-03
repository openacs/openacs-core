ad_library {
    ADP to Tcl Compiler, NaviServer variant.
}

if {[ns_info name] ne "NaviServer"} {
    return
}
#
# NaviServer requires for disambiguation of flags and values at the
# end of the argument processing a terminating "--"
#
ad_proc template::adp_parse_string { chunk } {
    Parse string as ADP
} {
    return [ns_adp_parse -string -- $chunk]
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
