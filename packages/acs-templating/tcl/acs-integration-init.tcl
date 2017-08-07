# this initialization must be in a package alphabetically after
# acs-kernel, so the following will overwrite that handler.

# we register SAME handler for adp and Tcl pages

rp_register_extension_handler adp adp_parse_ad_conn_file
rp_register_extension_handler tcl adp_parse_ad_conn_file

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
