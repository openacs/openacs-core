#
# Register an URN handler for registered URNs
#
# For now, we register the URN handler under /__urn/*, but that should
# be probably made configurable. We just register this handler when
# the command "ns_writer" is available.
#
# Gustaf Neumann, March 2019
#
if {[namespace which ns_writer] ne ""} {
    ns_register_proc GET __urn/* {
        set URN [string range [ns_conn url] 7 end]
        ns_log notice "URN handler checks URN <$URN>"
        set key ::template::head::urn($URN)
        if {[info exists $key]} {
            set URL [set $key]
            ns_log notice "URN handler resolves URN <$URN> -> $URL"
            #
            # We try to use an internal redirect to avoid relying that the
            # requesting client handles redirects correctly.  We do just
            # handle the most common cases. For full rp compatibility, we
            # would require a rp-compatible URL to file mapping.
            # first.
            #
            if {[regexp {^/resources/([^/]+)/(.*)$} $URL . package_key path]
                && [file readable    $::acs::rootdir/packages/$package_key/www/resources/$path]} {
                ns_writer submitfile $::acs::rootdir/packages/$package_key/www/resources/$path
            } else {
                ad_returnredirect -allow_complete_url $URL
            }
        } else {
            ns_log notice "URN handler fails for URN <$URN>"
            ns_return 404 text/plain "can't resolve $URN"
        }
    }
}

ns_ictl trace freeconn ::template::reset_request_vars

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
