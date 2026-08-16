ad_library {

     Procs intended for use as NaviServer/OpenACS request filters.

     This file contains reusable filters for rejecting unwanted requests
     and protecting the normal connection pool from excessive anonymous
     traffic. The filters can be parameterized when registered for
     particular HTTP methods and URL patterns.
}

namespace eval util {}

ad_proc ::util::reject_request_filter {why what} {

    Reject a request from a NaviServer filter.

    This proc is intended for use with ns_register_filter, in particular
    for early preauth filters that reject unwanted probe, scanner, or
    otherwise unsupported request paths before the OpenACS request
    processor performs canonical-host redirects or page dispatch.

    When used as a preauth filter, the proc performs the minimal ad_conn
    setup needed by the OpenACS request processor cleanup path.

    Example: <pre>
    ns_register_filter -first preauth POST /PSEMHUB/* \
        ::util::reject_request_filter "PeopleSoft probe"</pre>

    @param why  filter stage, e.g. preauth
    @param what short description of the rejected request

    @return filter_return

} {
    ns_log notice \
        "reject blocked request: $what\
         method=[ns_conn method]\
         url=[ns_conn url]\
         peer=[ns_conn peeraddr]"

    if {$why eq "preauth"} {
        #
        # Minimal setup for the OpenACS request processor to avoid errors
        # when the proc is registered as a preauth filter.
        #
        ad_conn -set extra_url /
        ad_conn -set path_info /
    }

    ns_returnnotfound
    return filter_return
}


ad_proc ::util::reject_anonymous_on_high_load_filter {
    why
    args
} {

    Reject an anonymous request when too many requests for the same
    URL are already running or when the server request queue exceeds
    a configured limit.

    The filter is active only in the connection pools specified by
    -pools. The empty pool name denotes the default connection pool.

    Example: <pre>
    ns_register_filter \
        postauth \
        GET /bugtracker/* \
        ::util::reject_anonymous_on_high_load_filter \
        -what "bugtracker request" \
        -pools [list ""] \
        -max_running 3 \
        -max_queued 10 \
        -retry_after 60</pre>

    @param why  filter stage, normally postauth
    @param what short description of the request
    @param pools connection pools in which the filter is active
    @param match optional Tcl match pattern for grouping active URLs;
                 when omitted, only the current URL is counted
    @param max_running maximum number of matching active requests
    @param max_queued maximum number of queued requests
    @param retry_after Retry-After value in seconds

    @return filter_ok or filter_return

} {
    try {
        ns_parseargs {
            {-what ""}
            {-pools ""}
            {-match ""}
            {-max_running 3}
            {-max_queued 10}
            {-retry_after 60}
        } $args
    } on error {errorMsg} {
        ns_log Warning DEBUG failed to parse args <$args>
        return filter_ok
        
    }
    
    #
    # Apply the filter only in the selected connection pools.
    # An empty pool name denotes the default pool.
    #
    set pool [ns_conn pool]
    if {$pool ni $pools} {
        return filter_ok
    }

    #
    # Never throttle authenticated users.
    #
    if {[ad_conn user_id] != 0} {
        return filter_ok
    }

    set method [ns_conn method]
    set url    [ns_conn url]
    set queued [llength [ns_server queued]]
    set running 0

    #
    # With no explicit match pattern, count requests for exactly the
    # current URL. Otherwise, count URLs matching the supplied pattern.
    #
    foreach active_request [ns_server active] {
        lassign $active_request \
            connection_id peer state active_method active_url \
            running_time bytes_sent

        if {$active_method ne $method} {
            continue
        }

        if {$match eq ""} {
            if {$active_url eq $url} {
                incr running
            }
        } else {
            if {[string match $match $active_url]} {
                incr running
            }
        }
    }

    if {$running <= $max_running && $queued <= $max_queued} {
        return filter_ok
    }

    set peer       [ns_conn peeraddr]
    set request    [ns_conn request]
    set user_agent [ns_set iget [ns_conn headers] user-agent]

    ns_log notice \
        "reject anonymous request under high load: $what\
         pool=<$pool>\
         running=$running max_running=$max_running\
         queued=$queued max_queued=$max_queued\
         peer=$peer request=<$request>\
         user-agent=<$user_agent>"

    ns_set update [ns_conn outputheaders] Retry-After $retry_after

    ns_return 503 text/plain \
        "The service is temporarily overloaded. Please try again later.\n"

    return filter_return
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
