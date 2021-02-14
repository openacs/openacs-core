ad_library {

    Provides the caching implementation of the brute force
    login prevention feature.

    @author Guenter Ernst (guenter.ernst@wu.ac.at)
    @creation-date 28 Feb 2018
    @cvs-id $Id$
}


if {[ns_info name] ne "NaviServer"} {
    return
}

#-------------------------------------------------------------------------
# NaviServer implementation of the brute force login prevention
# feature caching procs.
# -------------------------------------------------------------------------
namespace eval auth::login_attempts {}

#
# Caution: The current implementation is based on the ns:memoize
# cache. In case an application has a huge ns:memoize cache, we should
# use another cache, since the API uses wild card operations on keys
# keys.
#
ad_proc -private ::auth::login_attempts::login_attempt_incr {
    {-key:required}
    {-max_age 21600}
}  {
    Increment the login attempts of a user.
    The max_age is specified in seconds.
} {
    return [ns_cache_incr -expires $max_age -- ns:memoize login-attempt-$key]
}


ad_proc -private ::auth::login_attempts::login_attempt_flush {
    {-key:required}
}  {
    Flush the login attempts of a user.
} {
    ns_cache_flush ns:memoize login-attempt-$key
}

ad_proc -private ::auth::login_attempts::flush_all {}  {
    Flush all login attempt counters.
} {
    ns_cache_flush -glob -- ns:memoize login-attempt-*
}

ad_proc -private ::auth::login_attempts::get {
    {-key:required}
}  {
    Get the current number of login attempts of a user.
} {
    set value 0
    ns_cache_get ns:memoize login-attempt-$key value
    return $value
}

ad_proc -private ::auth::login_attempts::all_entries {}  {
    Get all login attempts

    @return list {key number_of_attempts timeout ... }
} {

    set result [list]
    #
    # The function "ns_cache_stats" is actually not intended for
    # application programs, since - historically speaking - the
    # detailed status change over time. However, we have currently no
    # function to obtain the expire time for a cache entry, so we use
    # it here with caution.
    #
    set contents [ns_cache_stats -contents -- ns:memoize]

    foreach entry $contents {
        lassign $entry key size hits expire
        if {![string match "login-attempt-*" $key]} {
            continue
        }

        #
        # In general we face here a race condition. The entry for the
        # keys might have timed out. So, the cache lookup might
        # fail. So, we provide a "value" with an empty string as
        # default.
        #
        if {![ns_cache_get ns:memoize $key value]} {
            set value ""
        }

        lappend result [string range $key 14 end] [ns_time seconds $expire] $value
    }

    return $result

}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
