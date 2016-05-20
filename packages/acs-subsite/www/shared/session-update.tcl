# acs-subsite/www/shared/session-update.tcl

ad_page_contract {

    @author Don Baccus (dhogaza@pacifier.com)
    @creation-date 2-Feb-2002

    @param session_property The array which describes the new session
           property.  The required elements are package, key, value, and
           referrer.  The referrer element should be set [ad_conn url].
    @param return_url The page to return to

    Update the given session parameter with the given value and
    redirect to the caller.

    Note that a session property should never be used alone to drive
    any action in the system.  Always use permissions or an equivalent
    check!

    In order to reduce the potential for harm that might follow from
    forgetting this principle the session_property array passed to this page
    is signed and verified.
} {
    session_property:array,verify
    return_url:localurl
} -validate {
    referrer_error {
        if { $session_property(referrer) ne [get_referrer] } {
            ad_complain "Expected referrer does not match actual referrer"
        }
    }
}

ad_set_client_property $session_property(package) $session_property(key) $session_property(value)
ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
