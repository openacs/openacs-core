ad_library {
    ADP to Tcl Compiler, AOLServer variant
}

if {[ns_info name] eq "NaviServer"} {
    return
}
#
# AOLserver does not support the double dashes "--" to separate non
# positional arguments from positional ones
#
ad_proc template::adp_parse_string { chunk } {
    Parse string as ADP
} {
    return [ns_adp_parse -string $chunk]
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
