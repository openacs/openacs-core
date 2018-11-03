aa_register_case \
    -cats {api smoke} \
    -procs {
        security::get_secure_location
        security::get_insecure_location
        util_current_location
    } \
    get_insecure_location {

        Test if security::get_insecure_location is working as expected.

        @author Gustaf Neumann
} {

    aa_run_with_teardown -rollback -test_code {
        aa_section "security::get_insecure_location"

        set current_location [util_current_location]
        aa_log "current location '$current_location'"

        set cld [ns_parseurl $current_location]
        aa_log "current location parts '$cld'"
        if {[dict exists $cld port] && [dict get $cld port] ne ""} {
            if {[dict get $cld proto] eq "http"} {
                aa_log "run tests with port based on HTTP"
                set insecure [security::get_insecure_location]
                aa_true "insecure location has same proto as current location" {$insecure eq $current_location}

                set secure [security::get_secure_location]
                set sld [ns_parseurl $secure]
                aa_true "secure location starts is HTTPS" {[dict get $sld proto] eq "https"}
            } else {
                aa_log "run tests with port based on HTTPS"
                set secure [security::get_secure_location]
                aa_true "secure location has same proto as current location" {$insecure eq $current_location}

                set insecure [security::get_insecure_location]
                set ild [ns_parseurl $insecure]
                aa_true "insecure location starts is HTTP" {[dict get $ild proto] eq "https"}
            }
        } else {
            aa_log "skip tests with port"
        }

    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
